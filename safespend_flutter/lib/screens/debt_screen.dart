import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);

        final debtGoals = provider.goals.where((g) => g.type == 'debt').toList();
        final totalDebt = debtGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
        final totalPaid = debtGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
        final totalRemaining = totalDebt - totalPaid;

        // Get debt payment transactions
        final debtTransactions = provider.transactions
            .where((t) => t.type == 'debt_payment')
            .toList()
          ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Debt Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text('Total Remaining Debt', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(cf.format(totalRemaining), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1)),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Debt', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(cf.format(totalDebt), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Paid Off', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(cf.format(totalPaid), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ),

                // Debts List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text('Your Debts', style: Theme.of(context).textTheme.titleLarge),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ),

                // Debts
                debtGoals.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: AppTheme.premiumCard(context),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 48, color: AppTheme.success),
                                const SizedBox(height: 16),
                                Text('No debts!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('You have no active debts. Great job!', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final goal = debtGoals[index];
                              final remaining = goal.targetAmount - goal.currentAmount;
                              final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount * 100) : 0.0;
                              final hasDeadline = goal.targetDate != null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.premiumCard(context),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(child: Text(goal.icon, style: const TextStyle(fontSize: 20))),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(goal.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                if (hasDeadline)
                                                  Text('Due: ${DateFormat('MMM d, yyyy').format(DateTime.parse(goal.targetDate!))}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(cf.format(remaining), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.error)),
                                              Text('remaining', style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: (progress / 100).clamp(0, 1).toDouble(),
                                          backgroundColor: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                                          color: AppTheme.success,
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${cf.format(goal.currentAmount)} paid', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.success)),
                                          Text('${progress.round()}% complete', style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms, delay: (250 + index * 80).ms);
                            },
                            childCount: debtGoals.length,
                          ),
                        ),
                      ),

                // Payment History Header
                if (debtTransactions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text('Payment History', style: Theme.of(context).textTheme.titleLarge),
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  ),

                // Payment History
                if (debtTransactions.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: AppTheme.premiumCard(context),
                        child: Column(
                          children: debtTransactions.take(20).toList().asMap().entries.map((entry) {
                            final t = entry.value;
                            final isLast = entry.key == (debtTransactions.length > 20 ? 19 : debtTransactions.length - 1);
                            final date = DateTime.parse(t.date);

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42, height: 42,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.credit_card_rounded, color: Color(0xFF8B5CF6), size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.note ?? 'Debt payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(DateFormat('MMM d, yyyy').format(date), style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '-${cf.format(t.amount)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast) Divider(height: 1, indent: 76, color: Theme.of(context).dividerColor),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }
}
