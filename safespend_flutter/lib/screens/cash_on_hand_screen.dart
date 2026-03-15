import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CashOnHandScreen extends StatelessWidget {
  const CashOnHandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final totalCash = provider.totalCash;

        // Get all cash-related transactions sorted by date descending
        final cashTransactions = provider.transactions.where((t) {
          // Withdrawals add to cash
          if (t.type == 'withdrawal') return true;
          // Transactions from cash on hand
          if (t.accountId == AppProvider.cashOnHandId) return true;
          // Transfers TO cash on hand
          if (t.type == 'transfer' && t.toAccountId == AppProvider.cashOnHandId) return true;
          return false;
        }).toList()
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
                        Text('Cash on Hand', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // Total Cash Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.goldCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text('Total Cash on Hand', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(cf.format(totalCash), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1)),
                          const SizedBox(height: 8),
                          Text(
                            'From withdrawals, income & transactions',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ),

                // Transaction History Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      children: [
                        Text('Cash Transactions', style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        Text('${cashTransactions.length} total', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ),

                // Transaction List
                cashTransactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: AppTheme.premiumCard(context),
                            child: Column(
                              children: [
                                Icon(Icons.payments_rounded, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(height: 16),
                                Text('No cash transactions yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('Make a withdrawal to add cash on hand', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            decoration: AppTheme.premiumCard(context),
                            child: Column(
                              children: cashTransactions.asMap().entries.map((entry) {
                                final t = entry.value;
                                final isLast = entry.key == cashTransactions.length - 1;
                                final date = DateTime.parse(t.date);

                                // Determine if this adds or removes cash
                                bool addsCash = false;
                                String description = t.note ?? '';
                                if (t.type == 'withdrawal') {
                                  addsCash = true;
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Withdrawal from bank';
                                } else if (t.type == 'income' && t.accountId == AppProvider.cashOnHandId) {
                                  addsCash = true;
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Cash income';
                                } else if (t.type == 'transfer' && t.toAccountId == AppProvider.cashOnHandId) {
                                  addsCash = true;
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Transfer to cash';
                                } else if (t.type == 'expense' && t.accountId == AppProvider.cashOnHandId) {
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Cash expense';
                                } else if (t.type == 'transfer' && t.accountId == AppProvider.cashOnHandId) {
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Transfer from cash';
                                } else if (t.type == 'goal_contribution' && t.accountId == AppProvider.cashOnHandId) {
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Goal contribution';
                                } else if (t.type == 'debt_payment' && t.accountId == AppProvider.cashOnHandId) {
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Debt payment';
                                } else {
                                  description = t.note?.isNotEmpty == true ? t.note! : 'Transaction';
                                }

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42, height: 42,
                                            decoration: BoxDecoration(
                                              color: (addsCash ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              addsCash ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                              color: addsCash ? AppTheme.success : AppTheme.error,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(description, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 2),
                                                Text(DateFormat('MMM d, yyyy').format(date), style: Theme.of(context).textTheme.bodySmall),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${addsCash ? '+' : '-'}${cf.format(t.amount)}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: addsCash ? AppTheme.success : AppTheme.error,
                                            ),
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
