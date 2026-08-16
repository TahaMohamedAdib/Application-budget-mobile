import 'package:uuid/uuid.dart';

import '../../../models/category.dart';
import '../../../models/goal.dart';
import '../../../models/recurring_rule.dart';
import '../../../models/transaction.dart';
import '../../../providers/app_provider.dart';
import '../ai_error.dart';
import '../ai_tool_call.dart';
import 'ai_tool.dart';
import 'ai_tool_registry.dart';

/// What the app should do with a tool call before anything changes.
enum AIToolDecision {
  /// Ran already; [AIToolExecution.result] holds the data.
  executed,

  /// A mutation the user must approve first.
  needsConfirmation,

  /// Rejected — unknown tool, bad arguments, missing entity.
  rejected,
}

/// Outcome of submitting a tool call to the executor.
class AIToolExecution {
  final AIToolDecision decision;
  final AIToolCall call;
  final AIToolResult? result;

  /// Human-readable description of the pending mutation, e.g.
  /// "Transfer 1,000 MAD — Checking → Savings". Shown on the confirmation card.
  final String? confirmationSummary;

  const AIToolExecution({
    required this.decision,
    required this.call,
    this.result,
    this.confirmationSummary,
  });
}

/// Validates and runs AI tool calls against SafeSpend's own business logic.
///
/// This is the only bridge between the model and user data, and it enforces
/// three rules:
///
///  1. **No direct database access.** Everything goes through [AppProvider],
///     which owns balance maths and Supabase sync.
///  2. **Identity is never taken from the model.** Any `user_id`/`token`
///     argument is discarded; the authenticated session is the sole source.
///  3. **Writes never run implicitly.** [submit] returns
///     [AIToolDecision.needsConfirmation] for mutations; only [confirm]
///     executes them.
class AIToolExecutor {
  final AppProvider provider;
  final Uuid _uuid;

  AIToolExecutor(this.provider, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Arguments that would let the model act as another user. Stripped before
  /// validation so they cannot reach business logic even by accident.
  static const _identityArgs = {
    'user_id',
    'userId',
    'token',
    'access_token',
    'auth',
    'jwt',
  };

  /// Entry point for a model-issued tool call.
  AIToolExecution submit(AIToolCall call) {
    final tool = AIToolRegistry.byName(call.name);
    if (tool == null) {
      return AIToolExecution(
        decision: AIToolDecision.rejected,
        call: call,
        result: AIToolResult.failure(
          call,
          code: AIErrorKind.invalidToolRequest.name,
          message: 'Unknown tool "${call.name}".',
        ),
      );
    }

    final sanitized = AIToolCall(
      id: call.id,
      name: call.name,
      arguments: Map<String, dynamic>.from(call.arguments)
        ..removeWhere((k, _) => _identityArgs.contains(k)),
    );

    final missing = tool.params
        .where((p) => p.required && sanitized.arguments[p.name] == null)
        .map((p) => p.name)
        .toList();
    if (missing.isNotEmpty) {
      return AIToolExecution(
        decision: AIToolDecision.rejected,
        call: sanitized,
        result: AIToolResult.failure(
          sanitized,
          code: AIErrorKind.invalidToolRequest.name,
          message: 'Missing required argument(s): ${missing.join(', ')}.',
        ),
      );
    }

    if (tool.requiresConfirmation) {
      final summary = describe(sanitized);
      if (summary == null) {
        return AIToolExecution(
          decision: AIToolDecision.rejected,
          call: sanitized,
          result: AIToolResult.failure(
            sanitized,
            code: AIErrorKind.invalidToolRequest.name,
            message: "That request didn't match anything in your data.",
          ),
        );
      }
      return AIToolExecution(
        decision: AIToolDecision.needsConfirmation,
        call: sanitized,
        confirmationSummary: summary,
      );
    }

    return AIToolExecution(
      decision: AIToolDecision.executed,
      call: sanitized,
      result: _run(tool, sanitized),
    );
  }

  /// Runs a mutation the user approved. Call only with a [AIToolCall] that
  /// [submit] returned as [AIToolDecision.needsConfirmation].
  AIToolResult confirm(AIToolCall call) {
    final tool = AIToolRegistry.byName(call.name);
    if (tool == null) {
      return AIToolResult.failure(
        call,
        code: AIErrorKind.invalidToolRequest.name,
        message: 'Unknown tool "${call.name}".',
      );
    }
    return _run(tool, call);
  }

  // ── Execution ─────────────────────────────────────────────────────────────

  AIToolResult _run(AITool tool, AIToolCall call) {
    try {
      final data = switch (tool.name) {
        'get_financial_summary' => _financialSummary(),
        'get_safe_to_spend' => _safeToSpend(call),
        'get_accounts' => _accounts(),
        'get_account_balance' => _accountBalance(call),
        'get_recent_transactions' => _recentTransactions(call),
        'search_transactions' => _searchTransactions(call),
        'get_spending_by_category' => _spendingByCategory(call),
        'get_budget_status' => _budgetStatus(),
        'get_upcoming_bills' => _upcomingBills(call),
        'get_subscriptions' => _subscriptions(),
        'get_savings_goals' => _savingsGoals(),
        'get_debts' => _debts(),
        'get_net_worth' => _netWorth(),
        'get_investment_summary' => _investmentSummary(),
        'create_transaction' => _createTransaction(call),
        'update_transaction' => _updateTransaction(call),
        'delete_transaction' => _deleteTransaction(call),
        'create_transfer' => _createTransfer(call),
        'create_budget' || 'update_budget' => _setBudget(call),
        'create_goal' => _createGoal(call),
        'update_goal' => _updateGoal(call),
        'contribute_to_goal' => _contributeToGoal(call),
        'create_subscription' => _createSubscription(call),
        'update_subscription' => _updateSubscription(call),
        'cancel_subscription' => _cancelSubscription(call),
        'record_debt_payment' => _recordDebtPayment(call),
        _ => null,
      };
      if (data == null) {
        return AIToolResult.failure(
          call,
          code: AIErrorKind.invalidToolRequest.name,
          message: 'Tool "${tool.name}" is declared but not implemented.',
        );
      }
      return AIToolResult.success(call, data);
    } on _ToolArgumentError catch (e) {
      return AIToolResult.failure(
        call,
        code: AIErrorKind.invalidToolRequest.name,
        message: e.message,
      );
    } catch (e) {
      return AIToolResult.failure(
        call,
        code: AIErrorKind.toolExecutionFailed.name,
        message: 'That action could not be completed. Nothing was changed.',
      );
    }
  }

  // ── Confirmation copy ─────────────────────────────────────────────────────

  /// One-line description of a pending mutation, or null when the call refers
  /// to something that doesn't exist.
  String? describe(AIToolCall call) {
    final a = call.arguments;
    final cur = provider.settings.currency;
    String money(num v) => '${_fmt(v.toDouble())} $cur';

    switch (call.name) {
      case 'create_transaction':
        final amount = _num(a, 'amount', required: true);
        final acc = _accountName(_str(a, 'account_id', required: true)!);
        if (acc == null) return null;
        final type = _str(a, 'type', required: true)!;
        final label = _str(a, 'note') ?? type;
        return '${_titleCase(type)} ${money(amount!)} — $label ($acc)';
      case 'update_transaction':
        final t = _findTransaction(_str(a, 'transaction_id', required: true)!);
        if (t == null) return null;
        return 'Update "${t.note ?? t.type}" (${money(t.amount)})';
      case 'delete_transaction':
        final t = _findTransaction(_str(a, 'transaction_id', required: true)!);
        if (t == null) return null;
        return 'Delete "${t.note ?? t.type}" — ${money(t.amount)}';
      case 'create_transfer':
        final from = _accountName(_str(a, 'from_account_id', required: true)!);
        final to = _accountName(_str(a, 'to_account_id', required: true)!);
        if (from == null || to == null) return null;
        return 'Transfer ${money(_num(a, 'amount', required: true)!)}\n$from → $to';
      case 'create_budget':
      case 'update_budget':
        final c = _findCategory(_str(a, 'category_id', required: true)!);
        if (c == null) return null;
        return 'Set ${c.name} budget to ${money(_num(a, 'limit', required: true)!)}';
      case 'create_goal':
        return 'Create goal "${_str(a, 'name', required: true)}" — target ${money(_num(a, 'target_amount', required: true)!)}';
      case 'update_goal':
        final g = _findGoal(_str(a, 'goal_id', required: true)!);
        if (g == null) return null;
        return 'Update goal "${g.name}"';
      case 'contribute_to_goal':
        final g = _findGoal(_str(a, 'goal_id', required: true)!);
        final acc = _accountName(_str(a, 'account_id', required: true)!);
        if (g == null || acc == null) return null;
        return 'Add ${money(_num(a, 'amount', required: true)!)} to "${g.name}"\nfrom $acc';
      case 'create_subscription':
        return 'New subscription "${_str(a, 'name', required: true)}" — ${money(_num(a, 'amount', required: true)!)} ${_str(a, 'frequency', required: true)}';
      case 'update_subscription':
        final r = _findRule(_str(a, 'subscription_id', required: true)!);
        if (r == null) return null;
        return 'Update subscription "${r.templateTransaction.note ?? 'Subscription'}"';
      case 'cancel_subscription':
        final r = _findRule(_str(a, 'subscription_id', required: true)!);
        if (r == null) return null;
        return 'Cancel "${r.templateTransaction.note ?? 'Subscription'}"';
      case 'record_debt_payment':
        final g = _findGoal(_str(a, 'debt_id', required: true)!);
        final acc = _accountName(_str(a, 'account_id', required: true)!);
        if (g == null || acc == null) return null;
        return 'Pay ${money(_num(a, 'amount', required: true)!)} toward "${g.name}"\nfrom $acc';
      default:
        return null;
    }
  }

  // ── Read implementations ──────────────────────────────────────────────────

  Map<String, dynamic> _financialSummary() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final month = provider.transactions.where((t) {
      final d = DateTime.tryParse(t.date);
      return d != null && !d.isBefore(monthStart);
    });
    return {
      'currency': provider.settings.currency,
      'net_worth': _r(provider.getNetWorth()),
      'cash_on_hand': _r(provider.totalCash),
      'total_debt': _r(provider.totalDebtRemaining),
      'investments': _r(provider.totalInvestmentValue),
      'monthly_income': _r(month
          .where((t) => t.type == 'income')
          .fold<double>(0, (s, t) => s + t.amount)),
      'monthly_expenses': _r(month
          .where((t) => t.type == 'expense')
          .fold<double>(0, (s, t) => s + t.amount)),
    };
  }

  Map<String, dynamic> _safeToSpend(AIToolCall call) {
    final period = _str(call.arguments, 'period') ?? 'month';
    final value = period == 'today'
        ? provider.getSafeToSpendToday()
        : provider.getSafeToSpendMonth();
    return {
      'period': period,
      'amount': _r(value),
      'currency': provider.settings.currency,
    };
  }

  Map<String, dynamic> _accounts() => {
        'accounts': [
          {
            'id': AppProvider.cashOnHandId,
            'name': 'Cash on Hand',
            'type': 'cash',
            'balance': _r(provider.totalCash),
          },
          ...provider.accounts.map((a) => {
                'id': a.id,
                'name': a.name,
                'type': a.type,
                'balance': _r(a.balance),
                if (a.bankName != null) 'bank_name': a.bankName,
              }),
        ],
        'currency': provider.settings.currency,
      };

  Map<String, dynamic> _accountBalance(AIToolCall call) {
    final id = _str(call.arguments, 'account_id', required: true)!;
    if (id == AppProvider.cashOnHandId) {
      return {
        'id': id,
        'name': 'Cash on Hand',
        'balance': _r(provider.totalCash),
        'currency': provider.settings.currency,
      };
    }
    final acc = provider.accounts.where((a) => a.id == id).firstOrNull;
    if (acc == null) throw _ToolArgumentError('No account with id "$id".');
    return {
      'id': acc.id,
      'name': acc.name,
      'type': acc.type,
      'balance': _r(acc.balance),
      'currency': provider.settings.currency,
    };
  }

  Map<String, dynamic> _recentTransactions(AIToolCall call) {
    final limit = _int(call.arguments, 'limit')?.clamp(1, 100) ?? 20;
    final accountId = _str(call.arguments, 'account_id');
    final list = provider.transactions
        .where((t) => accountId == null || t.accountId == accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return {
      'transactions': list.take(limit).map(_txnJson).toList(),
      'currency': provider.settings.currency,
    };
  }

  Map<String, dynamic> _searchTransactions(AIToolCall call) {
    final a = call.arguments;
    final query = _str(a, 'query')?.toLowerCase();
    final categoryId = _str(a, 'category_id');
    final type = _str(a, 'type');
    final minAmount = _num(a, 'min_amount');
    final maxAmount = _num(a, 'max_amount');
    final start = _date(a, 'start_date');
    final end = _date(a, 'end_date');
    final limit = _int(a, 'limit')?.clamp(1, 200) ?? 50;

    final results = provider.transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (minAmount != null && t.amount < minAmount) return false;
      if (maxAmount != null && t.amount > maxAmount) return false;
      final d = DateTime.tryParse(t.date);
      if (start != null && (d == null || d.isBefore(start))) return false;
      if (end != null && (d == null || d.isAfter(end))) return false;
      if (query != null && query.isNotEmpty) {
        final hay =
            '${t.note ?? ''} ${t.description ?? ''}'.toLowerCase();
        if (!hay.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((x, y) => y.date.compareTo(x.date));

    return {
      'count': results.length,
      'transactions': results.take(limit).map(_txnJson).toList(),
      'currency': provider.settings.currency,
    };
  }

  Map<String, dynamic> _spendingByCategory(AIToolCall call) {
    final now = DateTime.now();
    final start =
        _date(call.arguments, 'start_date') ?? DateTime(now.year, now.month, 1);
    final end = _date(call.arguments, 'end_date') ?? now;

    final totals = <String, double>{};
    for (final t in provider.transactions.where((t) => t.type == 'expense')) {
      final d = DateTime.tryParse(t.date);
      if (d == null || d.isBefore(start) || d.isAfter(end)) continue;
      final name = t.categoryId == null
          ? 'Uncategorised'
          : provider.categories
                  .where((c) => c.id == t.categoryId)
                  .firstOrNull
                  ?.name ??
              'Uncategorised';
      totals[name] = (totals[name] ?? 0) + t.amount;
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'total': _r(rows.fold<double>(0, (s, e) => s + e.value)),
      'categories':
          rows.map((e) => {'name': e.key, 'amount': _r(e.value)}).toList(),
      'currency': provider.settings.currency,
    };
  }

  Map<String, dynamic> _budgetStatus() => {
        'budgets': provider.categories
            .where((c) => c.budgetLimit > 0)
            .map((c) {
              final spent = provider.getCategorySpending(c.id);
              return {
                'category_id': c.id,
                'name': c.name,
                'limit': _r(c.budgetLimit),
                'spent': _r(spent),
                'remaining': _r(c.budgetLimit - spent),
                'over_budget': spent > c.budgetLimit,
              };
            })
            .toList(),
        'currency': provider.settings.currency,
      };

  Map<String, dynamic> _upcomingBills(AIToolCall call) {
    final days = _int(call.arguments, 'days_ahead')?.clamp(1, 365) ?? 30;
    final horizon = DateTime.now().add(Duration(days: days));
    final bills = provider.recurringRules.where((r) {
      if (!r.isActive) return false;
      final d = DateTime.tryParse(r.nextDate);
      return d != null && !d.isAfter(horizon);
    }).map((r) => {
              'id': r.id,
              'name': r.templateTransaction.note ?? 'Bill',
              'amount': _r(r.templateTransaction.amount),
              'due_date': r.nextDate,
              'frequency': r.frequency,
            }).toList()
      ..sort((a, b) =>
          (a['due_date'] as String).compareTo(b['due_date'] as String));
    return {
      'days_ahead': days,
      'bills': bills,
      'currency': provider.settings.currency,
    };
  }

  Map<String, dynamic> _subscriptions() => {
        'subscriptions': provider.recurringRules
            .where((r) => r.isActive)
            .map((r) => {
                  'id': r.id,
                  'name': r.templateTransaction.note ?? 'Subscription',
                  'amount': _r(r.templateTransaction.amount),
                  'frequency': r.frequency,
                  'next_date': r.nextDate,
                })
            .toList(),
        'currency': provider.settings.currency,
      };

  Map<String, dynamic> _savingsGoals() => {
        'goals': provider.goals
            .where((g) => g.type != 'debt')
            .map((g) => {
                  'id': g.id,
                  'name': g.name,
                  'type': g.type,
                  'target': _r(g.targetAmount),
                  'saved': _r(g.currentAmount),
                  'remaining': _r(g.targetAmount - g.currentAmount),
                  'progress_pct': g.targetAmount > 0
                      ? ((g.currentAmount / g.targetAmount) * 100).round()
                      : 0,
                  if (g.targetDate != null) 'target_date': g.targetDate,
                })
            .toList(),
        'currency': provider.settings.currency,
      };

  Map<String, dynamic> _debts() => {
        'debts': provider.goals
            .where((g) => g.type == 'debt')
            .map((g) => {
                  'id': g.id,
                  'name': g.name,
                  'total': _r(g.targetAmount),
                  'paid': _r(g.currentAmount),
                  'remaining': _r(g.targetAmount - g.currentAmount),
                  if (g.monthlyPayment != null)
                    'monthly_payment': _r(g.monthlyPayment!),
                })
            .toList(),
        'total_remaining': _r(provider.totalDebtRemaining),
        'currency': provider.settings.currency,
      };

  Map<String, dynamic> _netWorth() => {
        'net_worth': _r(provider.getNetWorth()),
        'cash_on_hand': _r(provider.totalCash),
        'bank_total': _r(provider.getTotalByAccountType('bank')),
        'savings_total': _r(provider.totalSavingsGoals),
        'investments': _r(provider.totalInvestmentValue),
        'total_debt': _r(provider.totalDebtRemaining),
        'currency': provider.settings.currency,
      };

  Map<String, dynamic> _investmentSummary() => {
        'value': _r(provider.getTotalPortfolioValue()),
        'cost_basis': _r(provider.getTotalPortfolioCost()),
        'gain_loss': _r(provider.getTotalPortfolioGainLoss()),
        'currency': provider.settings.currency,
      };

  // ── Write implementations ─────────────────────────────────────────────────

  Map<String, dynamic> _createTransaction(AIToolCall call) {
    final a = call.arguments;
    final type = _str(a, 'type', required: true)!;
    if (!const {'expense', 'income', 'withdrawal'}.contains(type)) {
      throw _ToolArgumentError('Unsupported transaction type "$type".');
    }
    final amount = _positive(_num(a, 'amount', required: true)!, 'amount');
    final accountId = _requireAccount(_str(a, 'account_id', required: true)!);
    final categoryId = _str(a, 'category_id');
    if (categoryId != null && _findCategory(categoryId) == null) {
      throw _ToolArgumentError('No category with id "$categoryId".');
    }

    final txn = Transaction(
      id: _uuid.v4(),
      type: type,
      amount: amount,
      fees: _num(a, 'fees')?.toDouble() ?? 0,
      date: (_date(a, 'date') ?? DateTime.now()).toIso8601String(),
      note: _str(a, 'note'),
      description: _str(a, 'description'),
      categoryId: categoryId,
      accountId: accountId,
    );
    provider.addTransaction(txn);
    return {'transaction_id': txn.id, 'created': true};
  }

  Map<String, dynamic> _updateTransaction(AIToolCall call) {
    final a = call.arguments;
    final existing =
        _findTransaction(_str(a, 'transaction_id', required: true)!);
    if (existing == null) {
      throw _ToolArgumentError('No transaction with that id.');
    }
    final amount = _num(a, 'amount');
    final updated = existing.copyWith(
      amount: amount == null ? null : _positive(amount, 'amount'),
      categoryId: _str(a, 'category_id'),
      note: _str(a, 'note'),
      date: _date(a, 'date')?.toIso8601String(),
    );
    provider.updateTransaction(updated);
    return {'transaction_id': updated.id, 'updated': true};
  }

  Map<String, dynamic> _deleteTransaction(AIToolCall call) {
    final id = _str(call.arguments, 'transaction_id', required: true)!;
    if (_findTransaction(id) == null) {
      throw _ToolArgumentError('No transaction with that id.');
    }
    provider.deleteTransaction(id);
    return {'transaction_id': id, 'deleted': true};
  }

  Map<String, dynamic> _createTransfer(AIToolCall call) {
    final a = call.arguments;
    final from = _requireAccount(_str(a, 'from_account_id', required: true)!);
    final to = _requireAccount(_str(a, 'to_account_id', required: true)!);
    if (from == to) {
      throw _ToolArgumentError('Source and destination must differ.');
    }
    final amount = _positive(_num(a, 'amount', required: true)!, 'amount');
    final txn = Transaction(
      id: _uuid.v4(),
      type: 'transfer',
      amount: amount,
      fees: _num(a, 'fees')?.toDouble() ?? 0,
      date: DateTime.now().toIso8601String(),
      note: _str(a, 'note') ?? 'Transfer',
      accountId: from,
      toAccountId: to,
    );
    provider.addTransaction(txn);
    return {'transaction_id': txn.id, 'created': true};
  }

  Map<String, dynamic> _setBudget(AIToolCall call) {
    final a = call.arguments;
    final category = _findCategory(_str(a, 'category_id', required: true)!);
    if (category == null) throw _ToolArgumentError('No category with that id.');
    final limit = _num(a, 'limit', required: true)!.toDouble();
    if (limit < 0) throw _ToolArgumentError('Budget limit cannot be negative.');
    provider.updateCategory(category.copyWith(budgetLimit: limit));
    return {'category_id': category.id, 'limit': _r(limit)};
  }

  Map<String, dynamic> _createGoal(AIToolCall call) {
    final a = call.arguments;
    final goal = Goal(
      id: _uuid.v4(),
      type: 'savings',
      name: _str(a, 'name', required: true)!,
      targetAmount:
          _positive(_num(a, 'target_amount', required: true)!, 'target_amount'),
      targetDate: _date(a, 'target_date')?.toIso8601String(),
    );
    provider.addGoal(goal);
    return {'goal_id': goal.id, 'created': true};
  }

  Map<String, dynamic> _updateGoal(AIToolCall call) {
    final a = call.arguments;
    final goal = _findGoal(_str(a, 'goal_id', required: true)!);
    if (goal == null) throw _ToolArgumentError('No goal with that id.');
    final target = _num(a, 'target_amount');
    provider.updateGoal(goal.copyWith(
      name: _str(a, 'name'),
      targetAmount:
          target == null ? null : _positive(target, 'target_amount'),
      targetDate: _date(a, 'target_date')?.toIso8601String(),
    ));
    return {'goal_id': goal.id, 'updated': true};
  }

  Map<String, dynamic> _contributeToGoal(AIToolCall call) {
    final a = call.arguments;
    final goal = _findGoal(_str(a, 'goal_id', required: true)!);
    if (goal == null) throw _ToolArgumentError('No goal with that id.');
    final accountId = _requireAccount(_str(a, 'account_id', required: true)!);
    final amount = _positive(_num(a, 'amount', required: true)!, 'amount');
    provider.contributeToGoalFromSource(goal.id, amount, accountId);
    return {'goal_id': goal.id, 'amount': _r(amount)};
  }

  Map<String, dynamic> _createSubscription(AIToolCall call) {
    final a = call.arguments;
    final accountId = _requireAccount(_str(a, 'account_id', required: true)!);
    final frequency = _str(a, 'frequency', required: true)!;
    if (!const {'daily', 'weekly', 'monthly', 'yearly'}.contains(frequency)) {
      throw _ToolArgumentError('Unsupported frequency "$frequency".');
    }
    final rule = RecurringRule(
      id: _uuid.v4(),
      frequency: frequency,
      nextDate: (_date(a, 'next_date') ?? DateTime.now()).toIso8601String(),
      templateTransaction: Transaction(
        id: _uuid.v4(),
        type: 'expense',
        amount: _positive(_num(a, 'amount', required: true)!, 'amount'),
        date: DateTime.now().toIso8601String(),
        note: _str(a, 'name', required: true),
        categoryId: _str(a, 'category_id'),
        accountId: accountId,
        isRecurring: true,
        expenseSubType: 'subscription',
      ),
    );
    provider.addRecurringRule(rule);
    return {'subscription_id': rule.id, 'created': true};
  }

  Map<String, dynamic> _updateSubscription(AIToolCall call) {
    final a = call.arguments;
    final rule = _findRule(_str(a, 'subscription_id', required: true)!);
    if (rule == null) throw _ToolArgumentError('No subscription with that id.');
    final amount = _num(a, 'amount');
    provider.updateRecurringRule(RecurringRule(
      id: rule.id,
      frequency: _str(a, 'frequency') ?? rule.frequency,
      nextDate: _date(a, 'next_date')?.toIso8601String() ?? rule.nextDate,
      isActive: rule.isActive,
      templateTransaction: amount == null
          ? rule.templateTransaction
          : rule.templateTransaction
              .copyWith(amount: _positive(amount, 'amount')),
    ));
    return {'subscription_id': rule.id, 'updated': true};
  }

  Map<String, dynamic> _cancelSubscription(AIToolCall call) {
    final rule = _findRule(_str(call.arguments, 'subscription_id',
        required: true)!);
    if (rule == null) throw _ToolArgumentError('No subscription with that id.');
    provider.deleteRecurringRule(rule.id);
    return {'subscription_id': rule.id, 'cancelled': true};
  }

  Map<String, dynamic> _recordDebtPayment(AIToolCall call) {
    final a = call.arguments;
    final debt = _findGoal(_str(a, 'debt_id', required: true)!);
    if (debt == null) throw _ToolArgumentError('No debt with that id.');
    final accountId = _requireAccount(_str(a, 'account_id', required: true)!);
    final amount = _positive(_num(a, 'amount', required: true)!, 'amount');
    provider.payDebt(debt.id, amount, accountId);
    return {'debt_id': debt.id, 'amount': _r(amount)};
  }

  // ── Lookups & coercion ────────────────────────────────────────────────────

  Transaction? _findTransaction(String id) =>
      provider.transactions.where((t) => t.id == id).firstOrNull;

  Category? _findCategory(String id) =>
      provider.categories.where((c) => c.id == id).firstOrNull;

  Goal? _findGoal(String id) =>
      provider.goals.where((g) => g.id == id).firstOrNull;

  RecurringRule? _findRule(String id) =>
      provider.recurringRules.where((r) => r.id == id).firstOrNull;

  String? _accountName(String id) {
    if (id == AppProvider.cashOnHandId) return 'Cash on Hand';
    return provider.accounts.where((a) => a.id == id).firstOrNull?.name;
  }

  /// Resolves an account id, rejecting anything that isn't real.
  String _requireAccount(String id) {
    if (id == AppProvider.cashOnHandId) return id;
    final exists = provider.accounts.any((a) => a.id == id);
    if (!exists) throw _ToolArgumentError('No account with id "$id".');
    return id;
  }

  double _positive(num value, String field) {
    final v = value.toDouble();
    if (v <= 0) throw _ToolArgumentError('"$field" must be greater than zero.');
    return v;
  }

  static String? _str(Map<String, dynamic> a, String key,
      {bool required = false}) {
    final v = a[key];
    if (v == null || (v is String && v.trim().isEmpty)) {
      if (required) throw _ToolArgumentError('Missing "$key".');
      return null;
    }
    return v.toString();
  }

  static num? _num(Map<String, dynamic> a, String key,
      {bool required = false}) {
    final v = a[key];
    if (v == null) {
      if (required) throw _ToolArgumentError('Missing "$key".');
      return null;
    }
    if (v is num) return v;
    final parsed = num.tryParse(v.toString());
    if (parsed == null) {
      throw _ToolArgumentError('"$key" must be a number.');
    }
    return parsed;
  }

  static int? _int(Map<String, dynamic> a, String key) =>
      _num(a, key)?.toInt();

  static DateTime? _date(Map<String, dynamic> a, String key) {
    final raw = _str(a, key);
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw _ToolArgumentError('"$key" must be an ISO-8601 date.');
    }
    return parsed;
  }

  Map<String, dynamic> _txnJson(Transaction t) => {
        'id': t.id,
        'type': t.type,
        'amount': _r(t.amount),
        if (t.fees != 0) 'fees': _r(t.fees),
        'date': t.date,
        if (t.note != null) 'note': t.note,
        if (t.categoryId != null) 'category_id': t.categoryId,
        'account_id': t.accountId,
        if (t.toAccountId != null) 'to_account_id': t.toAccountId,
      };

  static double _r(double v) => double.parse(v.toStringAsFixed(2));

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ToolArgumentError implements Exception {
  final String message;
  const _ToolArgumentError(this.message);
}
