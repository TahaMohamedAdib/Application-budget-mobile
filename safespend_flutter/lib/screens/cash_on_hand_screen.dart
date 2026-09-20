import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';
import '../widgets/feature_help_button.dart';

class CashOnHandScreen extends StatelessWidget {
  const CashOnHandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = S.of(context);
        final cf = MoneyFormat.of(provider.settings);
        final totalCash = provider.totalCash;

        // Get all cash-related transactions sorted by date descending
        final cashTransactions = provider.transactions.where((t) {
          // Withdrawals add to cash
          if (t.type == 'withdrawal') return true;
          // Transactions from cash on hand
          if (t.accountId == AppProvider.cashOnHandId) return true;
          // Transfers TO cash on hand
          if (t.type == 'transfer' && t.toAccountId == AppProvider.cashOnHandId)
            return true;
          return false;
        }).toList()
          ..sort((a, b) =>
              DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: IconButton(
                            icon: const Icon(IOSIcons.arrow_back_rounded,
                                size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(s.tr('cash'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        FeatureHelpButton(
                          title: s.tr('cash'),
                          description: s.tr('cashSources'),
                          icon: IOSIcons.payments_rounded,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 260.ms, curve: Curves.easeOut),
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
                          Wrap(
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(IOSIcons.payments_rounded,
                                  color: AppTheme.cashOnHandIcon, size: 22),
                              const SizedBox(width: 10),
                              Text(s.tr('totalCash'),
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(cf.format(totalCash),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5)),
                          const SizedBox(height: 8),
                          Text(
                            s.tr('cashSources'),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 80.ms, curve: Curves.easeOut),
                ),

                // Transaction History Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Wrap(
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(s.tr('cashTransactions'),
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                            s.tr('totalCount', {
                              'count': cashTransactions.length,
                            }),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 120.ms, curve: Curves.easeOut),
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
                                const Icon(IOSIcons.payments_rounded,
                                    size: 72, color: AppTheme.cashOnHandIcon),
                                const SizedBox(height: 16),
                                Text(s.tr('noCashTransactions'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(s.tr('withdrawToAddCash'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center),
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
                              children:
                                  cashTransactions.asMap().entries.map((entry) {
                                final t = entry.value;
                                final isLast =
                                    entry.key == cashTransactions.length - 1;
                                final date = DateTime.parse(t.date);

                                // Determine if this adds or removes cash
                                bool addsCash = false;
                                String description = S
                                        .forLocale(context
                                            .read<AppProvider>()
                                            .settings
                                            .locale)
                                        .systemNote(t.note) ??
                                    '';
                                if (t.type == 'withdrawal') {
                                  addsCash = true;
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.tr('withdrawalFromBank');
                                } else if (t.type == 'income' &&
                                    t.accountId == AppProvider.cashOnHandId) {
                                  addsCash = true;
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.tr('cashIncome');
                                } else if (t.type == 'transfer' &&
                                    t.toAccountId == AppProvider.cashOnHandId) {
                                  addsCash = true;
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.tr('transferToCash');
                                } else if (t.type == 'expense' &&
                                    t.accountId == AppProvider.cashOnHandId) {
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.tr('cashExpense');
                                } else if (t.type == 'transfer' &&
                                    t.accountId == AppProvider.cashOnHandId) {
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.tr('transferFromCash');
                                } else if (t.type == 'goal_contribution' &&
                                    t.accountId == AppProvider.cashOnHandId) {
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.goalContribution;
                                } else if (t.type == 'debt_payment' &&
                                    t.accountId == AppProvider.cashOnHandId) {
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.debtPayment;
                                } else {
                                  description = S
                                              .forLocale(context
                                                  .read<AppProvider>()
                                                  .settings
                                                  .locale)
                                              .systemNote(t.note)
                                              ?.isNotEmpty ==
                                          true
                                      ? S
                                          .forLocale(context
                                              .read<AppProvider>()
                                              .settings
                                              .locale)
                                          .systemNote(t.note)!
                                      : s.transaction;
                                }

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.adaptiveIconSurface(
                                                      context),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              addsCash
                                                  ? IOSIcons
                                                      .arrow_downward_rounded
                                                  : IOSIcons
                                                      .arrow_upward_rounded,
                                              color: AppTheme.adaptiveIcon(
                                                  context),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(description,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    MaterialLocalizations.of(
                                                            context)
                                                        .formatMediumDate(date),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            cf.signed(t.amount,
                                                positive: addsCash),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              // Cash money is amber in both
                                              // directions.
                                              color: AppTheme.cashOnHandIcon,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                          height: 1,
                                          indent: 76,
                                          color:
                                              Theme.of(context).dividerColor),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }
}
