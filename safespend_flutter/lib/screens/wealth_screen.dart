import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../l10n/app_localizations.dart';
import '../widgets/account_picker_field.dart';
import 'accounts_screen.dart';
import 'cash_on_hand_screen.dart';
import 'debt_screen.dart';
import 'personal_debts_screen.dart';
import 'portfolio_screen.dart';
import 'goals_screen.dart';
import 'daret_screen.dart';
import 'settings_screen.dart';
import '../utils/money_format.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.goldPrimary;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTheme.goldPrimary;
    }
  }

  String _getSelectedAccountName(AppProvider provider, S s) {
    if (provider.selectedAccountId == null) return s.allAccounts;
    final a =
        provider.accounts.where((a) => a.id == provider.selectedAccountId);
    return a.isNotEmpty ? a.first.name : s.allAccounts;
  }

  Widget _buildHeaderAccountIcon(AppProvider provider) {
    if (provider.selectedAccountId != null) {
      final match =
          provider.accounts.where((a) => a.id == provider.selectedAccountId);
      if (match.isNotEmpty && match.first.imagePath != null) {
        final path = match.first.imagePath!;
        return SizedBox(
          width: 18,
          height: 18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: path.startsWith('http')
                ? Image.network(path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        _getAccountIcon(provider),
                        size: 16,
                        color: AppTheme.adaptiveIcon(context)))
                : Image.file(File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        _getAccountIcon(provider),
                        size: 16,
                        color: AppTheme.adaptiveIcon(context))),
          ),
        );
      }
    }
    return Icon(
      provider.selectedAccountId == null
          ? IOSIcons.account_balance_wallet_rounded
          : _getAccountIcon(provider),
      size: 16,
      color: AppTheme.adaptiveIcon(context),
    );
  }

  IconData _getAccountIcon(AppProvider provider) {
    if (provider.selectedAccountId == null)
      return IOSIcons.account_balance_wallet_rounded;
    final account =
        provider.accounts.where((a) => a.id == provider.selectedAccountId);
    if (account.isEmpty) return IOSIcons.account_balance_wallet_rounded;
    switch (account.first.type) {
      case 'bank':
        return IOSIcons.account_balance_rounded;
      case 'savings':
        return IOSIcons.savings_rounded;
      case 'investment':
        return IOSIcons.investment;
      case 'debt':
        return IOSIcons.credit_card_rounded;
      default:
        return IOSIcons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final netWorth = provider.getNetWorth();
        final rangeData = provider.getBalanceForRange('ALL');
        final income = rangeData['income'] ?? 0.0;
        final expenses = rangeData['expenses'] ?? 0.0;
        final balance = rangeData['total'] ?? 0.0;

        // The Accounts row follows the picker above: one account selected shows
        // that account's balance, "All accounts" shows the combined total.
        final pickedAccounts = provider.selectedAccountId == null
            ? const []
            : provider.accounts
                .where((a) => a.id == provider.selectedAccountId)
                .toList();
        final selectedAccount =
            pickedAccounts.isNotEmpty ? pickedAccounts.first : null;
        final totalBank = selectedAccount != null
            ? selectedAccount.balance
            : provider.getTotalByAccountType('bank');
        final totalCash = provider.totalCash;
        final totalSavings = provider.totalSavingsGoals;
        final totalInvestments = provider.totalInvestmentValue;
        final totalDebt = provider.totalDebtRemaining;
        final totalPersonalDebt = provider.goals
            .where((g) => g.type == 'personal_debt')
            .fold(0.0, (s, g) => s + (g.targetAmount - g.currentAmount));

        final now = DateTime.now();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final totalWeekSpending = provider.transactions
            .where((t) =>
                t.type == 'expense' &&
                (provider.selectedAccountId == null ||
                    t.accountId == provider.selectedAccountId) &&
                DateTime.parse(t.date).isAfter(
                    DateTime(monday.year, monday.month, monday.day)
                        .subtract(const Duration(days: 1))))
            .fold(0.0, (sum, t) => sum + t.amount);

        final cf = MoneyFormat.of(provider.settings);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            // Let content flow under the floating nav pill.
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.wealth,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SettingsScreen())),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: AppIcon(AppIcons.settings,
                                    size: 22,
                                    color: AppTheme.adaptiveIcon(context)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Account picker
                        AccountPickerField(
                          provider: provider,
                          label: s.selectAccount,
                          value: provider.selectedAccountId,
                          includeCashOnHand: false,
                          includeAllAccounts: true,
                          allAccountsLabel: s.allAccounts,
                          onChanged: provider.setSelectedAccount,
                          triggerBuilder: (context, selected, open) =>
                              GestureDetector(
                            onTap: open,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : AppTheme.lightSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : AppTheme.lightBorder,
                                ),
                                boxShadow:
                                    isDark ? [] : AppTheme.cardShadowLight,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeaderAccountIcon(provider),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getSelectedAccountName(provider, s),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AppIcon(AppIcons.caretUpDown,
                                      size: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.05, end: 0, curve: Curves.easeOut),
                ),

                // ── Net Worth Card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.goldCard(isDark: isDark),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.netWorth,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF5F6368),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(cf.format(netWorth),
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5)),
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isDark
                                      ? Colors.white.withOpacity(0.25)
                                      : Colors.black.withOpacity(0.14),
                                  Colors.transparent
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(s.allTime,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : const Color(0xFF74777C),
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w500)), // TODO: localize
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _goldStatCol(s.income, '+${cf.format(income)}',
                                  AppTheme.success, isDark),
                              _goldStatCol(
                                  s.debt,
                                  '-${cf.format(totalDebt)}',
                                  isDark
                                      ? const Color(0xFFFF8A80)
                                      : AppTheme.error,
                                  isDark),
                              _goldStatCol(
                                  s.netWorth,
                                  cf.format(netWorth),
                                  netWorth >= 0
                                      ? AppTheme.success
                                      : (isDark
                                          ? const Color(0xFFFF8A80)
                                          : AppTheme.error),
                                  isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                          duration: 280.ms, delay: 80.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.05, end: 0),
                ),

                // ── Breakdown (clickable items) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text(s.breakdown,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: AppTheme.premiumCard(context),
                      child: Column(
                        children: [
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthAccounts,
                            label: s.accounts,
                            // Name the account so a single balance isn't shown
                            // under a generic "checking / current" caption.
                            sublabel: selectedAccount?.name ?? s.checkingCurrent,
                            amount: totalBank,
                            isFirst: true,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AccountsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthCash,
                            label: s.cashOnHand,
                            sublabel: s.fromWithdrawals,
                            amount: totalCash,
                            amountColor: AppTheme.cashOnHandIcon,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CashOnHandScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthInvestments,
                            label: s.investments,
                            sublabel: s.stocksFundsEtc,
                            amount: totalInvestments,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PortfolioScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthDebt,
                            label: s.debt,
                            sublabel: s.loansAndDebts,
                            amount: -totalDebt,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DebtScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthPersonalDebts,
                            label: s.personalDebts,
                            sublabel: s.moneyPeopleOweMe,
                            amount: totalPersonalDebt,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PersonalDebtsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthSavingsGoals,
                            label: s.savingsGoals,
                            sublabel: s.moneyForGoals,
                            amount: totalSavings,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const GoalsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            icon: IOSIcons.wealthSavingsCircle,
                            label: s.daret,
                            sublabel: s.rotatingSavings,
                            amount: provider.totalDaretNetPosition,
                            isLast: true,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DaretScreen())),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 120.ms, curve: Curves.easeOut),
                ),

                // Clearance for the floating nav pill.
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownItem({
    required BuildContext context,
    required MoneyFormat cf,
    required IconData icon,
    required String label,
    required String sublabel,
    required double amount,
    required VoidCallback onTap,
    /// Colour for the amount only — icons stay neutral across the app.
    /// Null leaves the amount in the default text colour.
    Color? amountColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (!isFirst)
          Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.adaptiveIcon(context, alpha: 0.12),
                    ),
                  ),
                  child: Center(
                    child: Icon(icon,
                        size: 23, color: AppTheme.adaptiveIcon(context)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(sublabel,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  cf.negativeSigned(amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      // Rows without a fixed accent (only Cash on Hand has one)
                      // take their colour from the sign of the balance.
                      color: amountColor ?? AppTheme.balanceColor(amount)),
                ),
                const SizedBox(width: 8),
                AppIcon(AppIcons.caretRight,
                    size: 18, color: AppTheme.adaptiveIcon(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _goldStatCol(
      String label, String value, Color valueColor, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFF74777C),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
