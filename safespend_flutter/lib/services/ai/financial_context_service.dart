import '../../providers/app_provider.dart';

/// A compact snapshot of the user's finances, sent with every AI request.
///
/// Deliberately a *summary*: the full transaction history is never uploaded.
/// Detail is fetched on demand through the read tools, which keeps requests
/// small and limits how much data leaves the device per turn.
///
/// Every number here is computed by SafeSpend. The model's job is to explain
/// these figures, never to derive them.
class FinancialContext {
  final String currency;
  final double cashOnHand;
  final double totalAssets;
  final double totalDebt;
  final double netWorth;
  final double safeToSpend;
  final double monthlyIncome;
  final double monthlyExpenses;
  final List<Map<String, dynamic>> upcomingBills;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> subscriptions;
  final List<Map<String, dynamic>> accountsSummary;
  final List<Map<String, dynamic>> topCategories;

  /// Free-form extras (e.g. project context in the Coach).
  final Map<String, dynamic> extras;

  const FinancialContext({
    required this.currency,
    required this.cashOnHand,
    required this.totalAssets,
    required this.totalDebt,
    required this.netWorth,
    required this.safeToSpend,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    this.upcomingBills = const [],
    this.budgets = const [],
    this.goals = const [],
    this.subscriptions = const [],
    this.accountsSummary = const [],
    this.topCategories = const [],
    this.extras = const {},
  });

  FinancialContext withExtras(Map<String, dynamic> more) => FinancialContext(
        currency: currency,
        cashOnHand: cashOnHand,
        totalAssets: totalAssets,
        totalDebt: totalDebt,
        netWorth: netWorth,
        safeToSpend: safeToSpend,
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        upcomingBills: upcomingBills,
        budgets: budgets,
        goals: goals,
        subscriptions: subscriptions,
        accountsSummary: accountsSummary,
        topCategories: topCategories,
        extras: {...extras, ...more},
      );

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'cash_on_hand': _r(cashOnHand),
        'total_assets': _r(totalAssets),
        'total_debt': _r(totalDebt),
        'net_worth': _r(netWorth),
        'safe_to_spend': _r(safeToSpend),
        'monthly_income': _r(monthlyIncome),
        'monthly_expenses': _r(monthlyExpenses),
        'upcoming_bills': upcomingBills,
        'budgets': budgets,
        'goals': goals,
        'subscriptions': subscriptions,
        'accounts_summary': accountsSummary,
        'top_categories': topCategories,
        ...extras,
      };

  static double _r(double v) => double.parse(v.toStringAsFixed(2));
}

class FinancialContextService {
  const FinancialContextService._();

  /// Builds the snapshot from live provider state.
  static FinancialContext build(AppProvider p) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final monthTxns = p.transactions.where((t) {
      final d = DateTime.tryParse(t.date);
      return d != null && !d.isBefore(monthStart);
    }).toList();

    final monthlyExpenses = monthTxns
        .where((t) => t.type == 'expense')
        .fold<double>(0, (s, t) => s + t.amount);
    final monthlyIncome = monthTxns
        .where((t) => t.type == 'income')
        .fold<double>(0, (s, t) => s + t.amount);

    final bankTotal = p.accounts
        .where((a) => a.type != 'debt')
        .fold<double>(0, (s, a) => s + a.balance);

    // Spending per category this month, ranked — enough for "why am I
    // overspending" without shipping every transaction.
    final spendByCategory = <String, double>{};
    for (final t in monthTxns.where((t) => t.type == 'expense')) {
      final name = t.categoryId == null
          ? 'Uncategorised'
          : p.categories
                  .where((c) => c.id == t.categoryId)
                  .firstOrNull
                  ?.name ??
              'Uncategorised';
      spendByCategory[name] = (spendByCategory[name] ?? 0) + t.amount;
    }
    final topCategories = (spendByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(6)
        .map((e) => {'name': e.key, 'amount': FinancialContext._r(e.value)})
        .toList();

    final budgets = p.categories
        .where((c) => c.budgetLimit > 0)
        .map((c) {
          final spent = p.getCategorySpending(c.id);
          return {
            'category_id': c.id,
            'name': c.name,
            'limit': FinancialContext._r(c.budgetLimit),
            'spent': FinancialContext._r(spent),
            'remaining': FinancialContext._r(c.budgetLimit - spent),
          };
        })
        .toList();

    final goals = p.goals.where((g) => g.type != 'debt').map((g) {
      return {
        'id': g.id,
        'name': g.name,
        'type': g.type,
        'target': FinancialContext._r(g.targetAmount),
        'saved': FinancialContext._r(g.currentAmount),
        'progress_pct': g.targetAmount > 0
            ? ((g.currentAmount / g.targetAmount) * 100).round()
            : 0,
        if (g.targetDate != null) 'target_date': g.targetDate,
      };
    }).toList();

    final subscriptions = p.recurringRules
        .where((r) => r.isActive)
        .map((r) => {
              'id': r.id,
              'name': r.templateTransaction.note ?? 'Subscription',
              'amount': FinancialContext._r(r.templateTransaction.amount),
              'frequency': r.frequency,
              'next_date': r.nextDate,
            })
        .toList();

    // Bills due in the next 30 days, soonest first.
    final horizon = now.add(const Duration(days: 30));
    final upcomingBills = p.recurringRules
        .where((r) {
          if (!r.isActive) return false;
          final d = DateTime.tryParse(r.nextDate);
          return d != null && !d.isAfter(horizon);
        })
        .map((r) => {
              'name': r.templateTransaction.note ?? 'Bill',
              'amount': FinancialContext._r(r.templateTransaction.amount),
              'due_date': r.nextDate,
            })
        .toList()
      ..sort((a, b) =>
          (a['due_date'] as String).compareTo(b['due_date'] as String));

    final accountsSummary = p.accounts
        .map((a) => {
              'id': a.id,
              'name': a.name,
              'type': a.type,
              'balance': FinancialContext._r(a.balance),
            })
        .toList();

    return FinancialContext(
      currency: p.settings.currency,
      cashOnHand: p.totalCash,
      totalAssets: bankTotal + p.totalCash + p.totalInvestmentValue,
      totalDebt: p.totalDebtRemaining,
      netWorth: p.getNetWorth(),
      safeToSpend: p.getSafeToSpendMonth(),
      monthlyIncome:
          monthlyIncome > 0 ? monthlyIncome : p.settings.monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      upcomingBills: upcomingBills,
      budgets: budgets,
      goals: goals,
      subscriptions: subscriptions,
      accountsSummary: accountsSummary,
      topCategories: topCategories,
    );
  }
}
