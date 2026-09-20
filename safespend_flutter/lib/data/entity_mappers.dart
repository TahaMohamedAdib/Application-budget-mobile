import 'dart:convert';

import '../models/account.dart';
import '../models/category.dart';
import '../models/daret.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';

/// Row-to-model and model-to-row conversion for every synced entity.
///
/// Kept apart from both the models and the repository so that neither has to
/// know about SQL column names: the models stay plain data, and the repository
/// speaks only in models.
///
/// SQLite has no boolean type, so every `bool` crosses this boundary as 0 or 1.
class EntityMappers {
  const EntityMappers._();

  static int _bool(bool value) => value ? 1 : 0;
  static bool _readBool(Object? value) => (value as int? ?? 0) != 0;
  static double _readDouble(Object? value) =>
      (value as num?)?.toDouble() ?? 0.0;

  // Accounts.

  static Map<String, Object?> accountToRow(Account a) => {
        'id': a.id,
        'name': a.name,
        'type': a.type,
        'balance': a.balance,
        'bank_name': a.bankName,
        'color': a.color,
        'include_in_net_worth': _bool(a.includeInNetWorth),
        'image_path': a.imagePath,
        'added_at': a.addedAt,
        'salary_amount': a.salaryAmount,
        'salary_frequency': a.salaryFrequency,
        'salary_day': a.salaryDay,
        'salary_anchor_date': a.salaryAnchorDate,
        'last_salary_date': a.lastSalaryDate,
        'debt_payment_amount': a.debtPaymentAmount,
        'debt_payment_day': a.debtPaymentDay,
        'debt_payment_source_id': a.debtPaymentSourceId,
      };

  static Account accountFromRow(Map<String, Object?> r) => Account(
        id: r['id']! as String,
        name: r['name']! as String,
        type: r['type']! as String,
        balance: _readDouble(r['balance']),
        bankName: r['bank_name'] as String?,
        color: r['color'] as String?,
        includeInNetWorth: _readBool(r['include_in_net_worth']),
        imagePath: r['image_path'] as String?,
        addedAt: r['added_at'] as String?,
        salaryAmount: (r['salary_amount'] as num?)?.toDouble(),
        salaryFrequency: r['salary_frequency'] as String?,
        salaryDay: r['salary_day'] as int?,
        salaryAnchorDate: r['salary_anchor_date'] as String?,
        lastSalaryDate: r['last_salary_date'] as String?,
        debtPaymentAmount: (r['debt_payment_amount'] as num?)?.toDouble(),
        debtPaymentDay: r['debt_payment_day'] as int?,
        debtPaymentSourceId: r['debt_payment_source_id'] as String?,
      );

  // Transactions.

  static Map<String, Object?> transactionToRow(Transaction t) => {
        'id': t.id,
        'type': t.type,
        'amount': t.amount,
        'fees': t.fees,
        'date': t.date,
        'note': t.note,
        'description': t.description,
        'category_id': t.categoryId,
        'account_id': t.accountId,
        'to_account_id': t.toAccountId,
        'is_recurring': _bool(t.isRecurring),
        'image_path': t.imagePath,
        'expense_sub_type': t.expenseSubType,
      };

  static Transaction transactionFromRow(Map<String, Object?> r) => Transaction(
        id: r['id']! as String,
        type: r['type']! as String,
        amount: _readDouble(r['amount']),
        fees: _readDouble(r['fees']),
        date: r['date']! as String,
        note: r['note'] as String?,
        description: r['description'] as String?,
        categoryId: r['category_id'] as String?,
        accountId: r['account_id']! as String,
        toAccountId: r['to_account_id'] as String?,
        isRecurring: _readBool(r['is_recurring']),
        imagePath: r['image_path'] as String?,
        expenseSubType: r['expense_sub_type'] as String?,
      );

  // Goals.

  static Map<String, Object?> goalToRow(Goal g) => {
        'id': g.id,
        'type': g.type,
        'name': g.name,
        'description': g.description,
        'target_amount': g.targetAmount,
        'target_date': g.targetDate,
        'current_amount': g.currentAmount,
        'priority': g.priority,
        'category_id': g.categoryId,
        'icon': g.icon,
        'image_path': g.imagePath,
        'color': g.color,
        'monthly_payment': g.monthlyPayment,
        'payment_day': g.paymentDay,
        'payment_source_account_id': g.paymentSourceAccountId,
      };

  static Goal goalFromRow(Map<String, Object?> r) => Goal(
        id: r['id']! as String,
        type: r['type'] as String? ?? 'savings',
        name: r['name']! as String,
        description: r['description'] as String?,
        targetAmount: _readDouble(r['target_amount']),
        targetDate: r['target_date'] as String?,
        currentAmount: _readDouble(r['current_amount']),
        priority: r['priority'] as int? ?? 0,
        categoryId: r['category_id'] as String?,
        icon: r['icon'] as String? ?? '🎯',
        imagePath: r['image_path'] as String?,
        color: r['color'] as String? ?? '#B8860B',
        monthlyPayment: (r['monthly_payment'] as num?)?.toDouble(),
        paymentDay: r['payment_day'] as int?,
        paymentSourceAccountId: r['payment_source_account_id'] as String?,
      );

  // Holdings.

  static Map<String, Object?> holdingToRow(Holding h) => {
        'id': h.id,
        'symbol': h.symbol,
        'title': h.title,
        'shares': h.shares,
        'cost_basis': h.costBasis,
        'current_price': h.currentPrice,
        'notes': h.notes,
        'purchase_date': h.purchaseDate,
        'source_account_id': h.sourceAccountId,
        'affects_source_balance': _bool(h.affectsSourceBalance),
        'source_amount': h.sourceAmount,
      };

  static Holding holdingFromRow(Map<String, Object?> r) => Holding(
        id: r['id']! as String,
        symbol: r['symbol']! as String,
        title: r['title'] as String?,
        shares: _readDouble(r['shares']),
        costBasis: _readDouble(r['cost_basis']),
        currentPrice: _readDouble(r['current_price']),
        notes: r['notes'] as String?,
        purchaseDate: r['purchase_date'] as String?,
        sourceAccountId: r['source_account_id'] as String?,
        affectsSourceBalance: _readBool(r['affects_source_balance']),
        sourceAmount: (r['source_amount'] as num?)?.toDouble(),
      );

  // Categories. "group" is a reserved SQL word, hence the quoting at the
  // query sites; the map key itself is plain.

  static Map<String, Object?> categoryToRow(Category c) => {
        'id': c.id,
        'name': c.name,
        'group': c.group,
        'icon': c.icon,
        'color': c.color,
        'budget_limit': c.budgetLimit,
      };

  static Category categoryFromRow(Map<String, Object?> r) => Category(
        id: r['id']! as String,
        name: r['name']! as String,
        group: r['group']! as String,
        icon: r['icon'] as String? ?? '',
        color: r['color'] as String? ?? '',
        budgetLimit: _readDouble(r['budget_limit']),
      );

  // Recurring rules. The template transaction is stored whole as JSON: it is
  // never queried by field, only rehydrated.

  static Map<String, Object?> recurringRuleToRow(RecurringRule rule) => {
        'id': rule.id,
        'template': jsonEncode(rule.templateTransaction.toJson()),
        'frequency': rule.frequency,
        'next_date': rule.nextDate,
        'is_active': _bool(rule.isActive),
      };

  static RecurringRule recurringRuleFromRow(Map<String, Object?> r) =>
      RecurringRule(
        id: r['id']! as String,
        templateTransaction: Transaction.fromJson(
          jsonDecode(r['template']! as String) as Map<String, dynamic>,
        ),
        frequency: r['frequency']! as String,
        nextDate: r['next_date']! as String,
        isActive: _readBool(r['is_active']),
      );

  // Darets. `payoutMonths` is a JSON int array, for the same reason.

  static Map<String, Object?> daretToRow(Daret d) => {
        'id': d.id,
        'name': d.name,
        'contribution_per_share': d.contributionPerShare,
        'total_shares': d.totalShares,
        'user_shares': d.userShares,
        'payout_months': jsonEncode(d.payoutMonths),
        'start_date': d.startDate,
        'payment_source_id': d.paymentSourceId,
        'destination_account_id': d.destinationAccountId,
        'payment_day': d.paymentDay,
        'is_active': _bool(d.isActive),
      };

  static Daret daretFromRow(Map<String, Object?> r) => Daret(
        id: r['id']! as String,
        name: r['name']! as String,
        contributionPerShare: _readDouble(r['contribution_per_share']),
        totalShares: r['total_shares'] as int? ?? 0,
        userShares: r['user_shares'] as int? ?? 1,
        payoutMonths: (jsonDecode(r['payout_months'] as String? ?? '[]')
                as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(),
        startDate: r['start_date']! as String,
        paymentSourceId: r['payment_source_id']! as String,
        destinationAccountId: r['destination_account_id']! as String,
        paymentDay: r['payment_day'] as int? ?? 1,
        isActive: _readBool(r['is_active']),
      );
}
