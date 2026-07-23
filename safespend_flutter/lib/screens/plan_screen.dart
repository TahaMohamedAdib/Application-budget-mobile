import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import '../widgets/app_picker_field.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/category.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';

class PlanScreen extends StatefulWidget {
  final int? initialTab; // 0=fixed, 1=variable, 2=sinking
  const PlanScreen({super.key, this.initialTab});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late String _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab == 2
        ? 'sinking'
        : widget.initialTab == 1
            ? 'variable'
            : 'fixed';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final totalPlanned = provider.settings.monthlyIncome;
        final fixedBillsCount = provider.recurringRules.length;
        final fixedBillsTotal = provider.recurringRules
            .fold(0.0, (sum, r) => sum + r.templateTransaction.amount);
        final monthlyContribution = provider.goals.isEmpty
            ? 0.0
            : provider.goals.fold(0.0, (sum, g) => sum + (g.targetAmount / 12));

        final cf = CurrencyHelper.formatter(provider.settings.currency);

        final defaultSinkingFunds = [
          {'name': 'Car/Repairs', 'icon': '🚗'},
          {'name': 'Gifts', 'icon': '🎁'},
          {'name': 'Emergency Fund', 'icon': '🛡️'},
          {'name': 'Vacation', 'icon': '✈️'},
        ];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      if (widget.initialTab != null) ...[
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : AppTheme.lightSurface,
                              shape: BoxShape.circle,
                              boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                            ),
                            child:
                                const Icon(Icons.arrow_back_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.monthlyPlan,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                                '${s.totalPlanned}: ${cf.format(totalPlanned)}/${s.month}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen())),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: const Icon(Icons.settings_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                    .slideY(begin: -0.05, end: 0, curve: Curves.easeOut),

                // Tabs
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTab(s.bills, 'fixed'),
                        _buildTab(s.budgeting, 'variable'),
                        _buildTab(s.sinkingFunds, 'sinking'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                    duration: 260.ms, delay: 80.ms, curve: Curves.easeOut),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Fixed Expenses ──
                        if (_activeTab == 'fixed') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '$fixedBillsCount ${s.bills} · ${cf.format(fixedBillsTotal)}/${s.month}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              GestureDetector(
                                onTap: () =>
                                    _showAddBillModal(context, provider),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: AppTheme.brandPrimary,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_rounded,
                                          size: 16, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(s.add,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (provider.recurringRules.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: AppTheme.premiumCard(context),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                        color: isDark
                                            ? AppTheme.darkSurfaceElevated
                                            : AppTheme.lightBackground,
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Icon(Icons.receipt_long_rounded,
                                        size: 28,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(s.noBills,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(s.addBillsDesc,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ).animate().fadeIn(
                                duration: 300.ms,
                                delay: 120.ms,
                                curve: Curves.easeOut)
                          else
                            ...provider.recurringRules
                                .asMap()
                                .entries
                                .map((entry) {
                              final rule = entry.value;
                              final dueDate = DateTime.parse(rule.nextDate);
                              final day = dueDate.day;
                              final ordinal = day == 1 || day == 21 || day == 31
                                  ? '${day}st'
                                  : day == 2 || day == 22
                                      ? '${day}nd'
                                      : day == 3 || day == 23
                                          ? '${day}rd'
                                          : '${day}th';
                              final freqLabel = rule.frequency == 'monthly'
                                  ? s.monthly
                                  : rule.frequency == 'weekly'
                                      ? s.weekly
                                      : rule.frequency == 'yearly'
                                          ? s.yearly
                                          : rule.frequency;
                              final acct = provider.accounts.where((a) =>
                                  a.id == rule.templateTransaction.accountId);
                              final acctName =
                                  rule.templateTransaction.accountId ==
                                          AppProvider.cashOnHandId
                                      ? s.cashOnHand
                                      : acct.isNotEmpty
                                          ? acct.first.name
                                          : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Dismissible(
                                  key: Key(rule.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                        color: AppTheme.error.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Icon(Icons.delete_rounded,
                                        color: AppTheme.error),
                                  ),
                                  onDismissed: (_) =>
                                      provider.deleteRecurringRule(rule.id),
                                  child: GestureDetector(
                                    onTap: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => AddBillModal(
                                          bill: rule,
                                          onSave: (updated) {
                                            provider
                                                .updateRecurringRule(updated);
                                            Navigator.pop(ctx);
                                          }),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: AppTheme.premiumCard(context),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppTheme
                                                        .darkSurfaceElevated
                                                    : AppTheme.lightBackground,
                                                borderRadius:
                                                    BorderRadius.circular(13)),
                                            child: const Icon(
                                                Icons.receipt_long_rounded,
                                                color: AppTheme.brandPrimary,
                                                size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    rule.templateTransaction
                                                            .note ??
                                                        s.bill,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 12,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        '${s.paymentDay} $ordinal',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                        width: 3,
                                                        height: 3,
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.color,
                                                                shape: BoxShape
                                                                    .circle)),
                                                    const SizedBox(width: 10),
                                                    Text(freqLabel,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall),
                                                    if (acctName
                                                        .isNotEmpty) ...[
                                                      const SizedBox(width: 10),
                                                      Container(
                                                          width: 3,
                                                          height: 3,
                                                          decoration: BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.color,
                                                              shape: BoxShape
                                                                  .circle)),
                                                      const SizedBox(width: 10),
                                                      Flexible(
                                                          child: Text(acctName,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis)),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                              cf.format(rule
                                                  .templateTransaction.amount),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(
                                  duration: 260.ms,
                                  delay: (80 + entry.key * 50).ms,
                                  curve: Curves.easeOut);
                            }),
                        ],

                        // ── Budgeting (Variable Expenses) ──
                        if (_activeTab == 'variable') ...[
                          () {
                            final variableCats = provider.categories
                                .where((c) => c.group == 'variable')
                                .toList();
                            final totalBudget = variableCats.fold(
                                0.0, (sum, c) => sum + c.budgetLimit);
                            final totalSpent = variableCats.fold(
                                0.0,
                                (sum, c) =>
                                    sum + provider.getCategorySpending(c.id));
                            return Text(
                              '${s.totalBudget}: ${cf.format(totalSpent)} / ${cf.format(totalBudget)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }(),
                          const SizedBox(height: 16),
                          ...provider.categories
                              .where((c) => c.group == 'variable')
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final cat = entry.value;
                            final spent = provider.getCategorySpending(cat.id);
                            final budget = cat.budgetLimit;
                            final ratio = budget > 0 ? spent / budget : 0.0;
                            // Green = under budget, Orange = at budget (>=90%), Red = over budget
                            Color statusColor;
                            if (budget <= 0) {
                              statusColor = Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  Colors.grey;
                            } else if (spent > budget) {
                              statusColor = AppTheme.error;
                            } else if (ratio >= 0.9) {
                              statusColor = AppTheme.warning;
                            } else {
                              statusColor = AppTheme.success;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _showSetBudgetModal(
                                    context, provider, cat, cf),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.premiumCard(context),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(_categoryIcon(cat.icon),
                                                color: statusColor, size: 20),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(cat.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  budget > 0
                                                      ? '${cf.format(spent)} of ${cf.format(budget)}'
                                                      : 'No limit set · Tap to set',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: budget > 0
                                                            ? statusColor
                                                            : null,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (budget > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                spent > budget
                                                    ? '+${cf.format(spent - budget)}'
                                                    : cf.format(budget - spent),
                                                style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ] else ...[
                                            const SizedBox(width: 8),
                                            Text(cf.format(spent),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                          ],
                                        ],
                                      ),
                                      if (budget > 0) ...[
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: ratio.clamp(0, 1).toDouble(),
                                            backgroundColor: isDark
                                                ? AppTheme.darkBorder
                                                : const Color(0xFFE2E8F0),
                                            color: statusColor,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(
                                duration: 260.ms,
                                delay: (80 + entry.key * 50).ms,
                                curve: Curves.easeOut);
                          }),
                        ],

                        // ── Sinking Funds ──
                        if (_activeTab == 'sinking') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Monthly contribution: ${cf.format(monthlyContribution)}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              GestureDetector(
                                onTap: () =>
                                    _showAddGoalModal(context, provider, s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: AppTheme.brandPrimary,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded,
                                          size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Add',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (provider.goals.isNotEmpty)
                            ...provider.goals.asMap().entries.map((entry) {
                              final goal = entry.value;
                              final progress = goal.targetAmount > 0
                                  ? (goal.currentAmount /
                                      goal.targetAmount *
                                      100)
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.premiumCard(context),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                                color: AppTheme.brand50,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Center(
                                                child: Text(goal.icon,
                                                    style: const TextStyle(
                                                        fontSize: 20))),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(goal.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                Text(
                                                    '${cf.format(goal.targetAmount / 12)}/mo',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: AppTheme.brandPrimary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Text('${progress.round()}%',
                                                style: const TextStyle(
                                                    color: AppTheme.brandPrimary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: (progress / 100)
                                              .clamp(0, 1)
                                              .toDouble(),
                                          backgroundColor: isDark
                                              ? AppTheme.darkBorder
                                              : const Color(0xFFE2E8F0),
                                          color: AppTheme.brandPrimary,
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              '${cf.format(goal.currentAmount)} saved',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          Text(
                                              '${cf.format(goal.targetAmount)} goal',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showContributeModal(
                                              context, provider, goal),
                                          icon: const Icon(Icons.add_rounded,
                                              size: 18),
                                          label: Text(
                                              goal.type == 'debt'
                                                  ? 'Make Payment'
                                                  : 'Contribute',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme
                                                .brandPrimary
                                                .withOpacity(0.12),
                                            foregroundColor:
                                                AppTheme.brandPrimary,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(
                                  duration: 260.ms,
                                  delay: (80 + entry.key * 50).ms,
                                  curve: Curves.easeOut);
                            })
                          else
                            ...defaultSinkingFunds.asMap().entries.map((entry) {
                              final fund = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.premiumCard(context),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                                color: AppTheme.brand50,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Center(
                                                child: Text(fund['icon']!,
                                                    style: const TextStyle(
                                                        fontSize: 20))),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(fund['name']!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                Text('\$0/mo',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall),
                                              ],
                                            ),
                                          ),
                                          Text('0%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: 0,
                                          backgroundColor: isDark
                                              ? AppTheme.darkBorder
                                              : const Color(0xFFE2E8F0),
                                          color: AppTheme.brandPrimary,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(
                                  duration: 260.ms,
                                  delay: (80 + entry.key * 50).ms,
                                  curve: Curves.easeOut);
                            }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, String value) {
    final isActive = _activeTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive ? AppTheme.brandGlow : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : Theme.of(context).textTheme.bodySmall?.color)),
          ),
        ),
      ),
    );
  }

  void _showAddBillModal(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBillModal(onSave: (bill) {
        provider.addRecurringRule(bill);
        Navigator.pop(context);
      }),
    );
  }

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'flash':
        return Icons.flash_on_rounded;
      case 'phone':
        return Icons.phone_android_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'face':
        return Icons.face_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'more_horiz':
        return Icons.more_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _showSetBudgetModal(BuildContext context, AppProvider provider,
      Category cat, NumberFormat cf) {
    final controller = TextEditingController(
        text: cat.budgetLimit > 0 ? cat.budgetLimit.toStringAsFixed(0) : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spent = provider.getCategorySpending(cat.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Theme.of(ctx).dividerColor,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(_categoryIcon(cat.icon),
                        color: AppTheme.brandPrimary, size: 24),
                    const SizedBox(width: 12),
                    Text('Set Budget for ${cat.name}',
                        style: Theme.of(ctx)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Spent this month: ${cf.format(spent)}',
                    style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Monthly limit',
                    hintText: '0.00',
                    prefixText:
                        '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (cat.budgetLimit > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider
                                .updateCategory(cat.copyWith(budgetLimit: 0));
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: AppTheme.error),
                          ),
                          child: const Text('Remove Limit',
                              style: TextStyle(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    if (cat.budgetLimit > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(controller.text) ?? 0;
                          if (amount > 0) {
                            provider.updateCategory(
                                cat.copyWith(budgetLimit: amount));
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Save',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context, AppProvider provider, S s) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedType = 'savings';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Theme.of(ctx).dividerColor,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text(s.addSinkingFund,
                      style: Theme.of(ctx)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  // Type selector: Savings Goal vs Debt Payoff
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = 'savings'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedType == 'savings'
                                  ? AppTheme.success.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selectedType == 'savings'
                                      ? AppTheme.success
                                      : Theme.of(ctx).dividerColor),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.savings_rounded,
                                    size: 24,
                                    color: selectedType == 'savings'
                                        ? AppTheme.success
                                        : Theme.of(ctx)
                                            .textTheme
                                            .bodySmall
                                            ?.color),
                                const SizedBox(height: 6),
                                Text(s.savingsGoal,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selectedType == 'savings'
                                            ? AppTheme.success
                                            : Theme.of(ctx)
                                                .textTheme
                                                .bodySmall
                                                ?.color)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = 'debt'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedType == 'debt'
                                  ? AppTheme.error.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selectedType == 'debt'
                                      ? AppTheme.error
                                      : Theme.of(ctx).dividerColor),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.credit_card_rounded,
                                    size: 24,
                                    color: selectedType == 'debt'
                                        ? AppTheme.error
                                        : Theme.of(ctx)
                                            .textTheme
                                            .bodySmall
                                            ?.color),
                                const SizedBox(height: 6),
                                Text(s.debtPayoff,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selectedType == 'debt'
                                            ? AppTheme.error
                                            : Theme.of(ctx)
                                                .textTheme
                                                .bodySmall
                                                ?.color)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText: selectedType == 'debt'
                              ? 'Debt Name'
                              : 'Goal Name',
                          hintText: selectedType == 'debt'
                              ? 'e.g., Car Loan, Credit Card'
                              : 'e.g., Vacation, Emergency Fund',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          prefixIcon: Icon(selectedType == 'debt'
                              ? Icons.credit_card_rounded
                              : Icons.flag_rounded))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: selectedType == 'debt'
                              ? 'Total Debt Amount'
                              : 'Target Amount',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.attach_money_rounded))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty) return;
                        provider.addGoal(Goal(
                          id: const Uuid().v4(),
                          type: selectedType,
                          name: nameCtrl.text,
                          targetAmount: double.tryParse(amountCtrl.text) ?? 1,
                          icon: selectedType == 'debt' ? '💳' : '🎯',
                          color: selectedType == 'debt' ? '#EF4444' : '#B8860B',
                        ));
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                      child: Text(
                          selectedType == 'debt' ? s.addDebt : s.addGoal,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContributeModal(
      BuildContext context, AppProvider provider, Goal goal) {
    final amountCtrl = TextEditingController();
    String? selectedSourceId = provider.accounts.isNotEmpty
        ? provider.accounts.first.id
        : AppProvider.cashOnHandId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final isDebt = goal.type == 'debt';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Theme.of(ctx).dividerColor,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppTheme.brand50,
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                            child: Text(goal.icon,
                                style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isDebt ? 'Pay Debt' : 'Contribute to Goal',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text(goal.name,
                                style: Theme.of(ctx).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress info
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isDebt ? 'Remaining' : 'Saved so far',
                            style: Theme.of(ctx).textTheme.bodySmall),
                        Text(
                            '${cf.format(goal.currentAmount)} / ${cf.format(goal.targetAmount)}',
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Source account picker
                  AppPickerField<String>(
                    label: 'Pay From',
                    value: selectedSourceId ?? AppProvider.cashOnHandId,
                    prefixIcon: AppIcons.wallet,
                    items: [
                      AppPickerItem(
                        value: AppProvider.cashOnHandId,
                        label: 'Cash on Hand',
                        subtitle: cf.format(provider.totalCash),
                        leadingIcon: AppIcons.payment,
                        iconColor: AppTheme.warning,
                      ),
                      ...provider.accounts
                          .where((a) => a.type != 'debt')
                          .map((a) => AppPickerItem(
                                value: a.id,
                                label: a.name,
                                subtitle: cf.format(a.balance),
                                leadingIcon: AppIcons.bank,
                                iconColor: AppTheme.brandPrimary,
                                imagePath: a.imagePath,
                              )),
                    ],
                    onChanged: (v) => setModalState(() => selectedSourceId = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Enter a valid amount')));
                          return;
                        }
                        if (isDebt) {
                          provider.payDebt(goal.id, amount,
                              selectedSourceId ?? AppProvider.cashOnHandId);
                        } else {
                          provider.contributeToGoalFromSource(goal.id, amount,
                              selectedSourceId ?? AppProvider.cashOnHandId);
                        }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${cf.format(amount)} ${isDebt ? "paid" : "contributed"} to ${goal.name}'),
                              backgroundColor: AppTheme.brandPrimary),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                      child: Text(isDebt ? 'Make Payment' : 'Contribute',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddBillModal extends StatefulWidget {
  final RecurringRule? bill;
  final Function(RecurringRule) onSave;
  const AddBillModal({super.key, this.bill, required this.onSave});
  @override
  State<AddBillModal> createState() => _AddBillModalState();
}

class _AddBillModalState extends State<AddBillModal> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedFrequency = 'monthly';
  DateTime _nextDate = DateTime.now();
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _nameController.text = widget.bill!.templateTransaction.note ?? '';
      _amountController.text =
          widget.bill!.templateTransaction.amount.toString();
      _selectedFrequency = widget.bill!.frequency;
      _nextDate = DateTime.parse(widget.bill!.nextDate);
      _selectedAccountId = widget.bill!.templateTransaction.accountId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Default to first available account or cash
        if (_selectedAccountId == null) {
          _selectedAccountId = provider.accounts.isNotEmpty
              ? provider.accounts.first.id
              : AppProvider.cashOnHandId;
        }

        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final s = S.of(context);

        return Container(
          decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text(widget.bill == null ? s.addBill : s.editBill,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                          labelText: 'Bill Name',
                          hintText: 'e.g., Rent, Netflix',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.receipt_long_rounded))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.attach_money_rounded))),
                  const SizedBox(height: 16),
                  // Account picker with Cash on Hand
                  AppPickerField<String>(
                    label: 'Pay From',
                    value: _selectedAccountId ?? AppProvider.cashOnHandId,
                    prefixIcon: AppIcons.wallet,
                    items: [
                      AppPickerItem(
                        value: AppProvider.cashOnHandId,
                        label: 'Cash on Hand',
                        subtitle: cf.format(provider.totalCash),
                        leadingIcon: AppIcons.payment,
                        iconColor: AppTheme.warning,
                      ),
                      ...provider.accounts.map((a) => AppPickerItem(
                            value: a.id,
                            label: a.name,
                            subtitle: cf.format(a.balance),
                            leadingIcon: AppIcons.bank,
                            iconColor: AppTheme.brandPrimary,
                            imagePath: a.imagePath,
                          )),
                    ],
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                  const SizedBox(height: 24),
                  Text(s.frequency,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['daily', 'weekly', 'monthly', 'yearly'].map((f) {
                      final isSelected = _selectedFrequency == f;
                      final freqLabel = f == 'daily'
                          ? s.daily
                          : f == 'weekly'
                              ? s.weekly
                              : f == 'monthly'
                                  ? s.monthly
                                  : s.yearly;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFrequency = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.brandPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSelected
                                      ? AppTheme.brandPrimary
                                      : Theme.of(context).dividerColor),
                            ),
                            child: Center(
                                child: Text(
                                    freqLabel[0].toUpperCase() +
                                        freqLabel.substring(1),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                          context: context,
                          initialDate: _nextDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (date != null) setState(() => _nextDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.borderedCard(context),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 18,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.nextDueDate,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text(
                                    DateFormat('MMM d, yyyy').format(_nextDate),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                              ]),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded,
                              size: 20,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveBill,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                      child: Text(
                          widget.bill == null ? s.addBill : s.saveChanges,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'debt':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  void _saveBill() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    final accountId = _selectedAccountId ?? AppProvider.cashOnHandId;
    final transaction = Transaction(
        id: const Uuid().v4(),
        type: 'expense',
        amount: amount,
        date: _nextDate.toIso8601String(),
        note: _nameController.text,
        accountId: accountId);
    final bill = RecurringRule(
        id: widget.bill?.id ?? const Uuid().v4(),
        templateTransaction: transaction,
        frequency: _selectedFrequency,
        nextDate: _nextDate.toIso8601String(),
        isActive: widget.bill?.isActive ?? true);
    widget.onSave(bill);
  }
}
