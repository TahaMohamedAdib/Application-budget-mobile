import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../l10n/app_localizations.dart';
import 'accounts_screen.dart';
import 'cash_on_hand_screen.dart';
import 'debt_screen.dart';
import 'personal_debts_screen.dart';
import 'portfolio_screen.dart';
import 'goals_screen.dart';
import 'daret_screen.dart';
import 'settings_screen.dart';

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

  String _iconForType(String type) {
    switch (type) {
      case 'bank':
        return AppIcons.bank;
      case 'savings':
        return AppIcons.savings;
      case 'investment':
        return AppIcons.trendUp;
      case 'debt':
        return AppIcons.creditCard;
      default:
        return AppIcons.wallet;
    }
  }

  void _showAccountPicker(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final s = S.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 16),
                Text(s.selectAccount,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                // All Accounts row
                _buildPickerAccountRow(
                  ctx: ctx,
                  isDark: isDark,
                  cf: cf,
                  icon: AppIcons.wallet,
                  iconColor: AppTheme.goldPrimary,
                  name: s.allAccounts,
                  sublabel: s.accountsCombined,
                  balance: provider.accounts.fold(0.0, (s, a) => s + a.balance),
                  isSelected: provider.selectedAccountId == null,
                  onTap: () {
                    provider.setSelectedAccount(null);
                    Navigator.pop(ctx);
                  },
                ),
                if (provider.accounts.isNotEmpty)
                  Divider(
                      height: 1, indent: 72, color: Theme.of(ctx).dividerColor),
                ...provider.accounts.asMap().entries.map((e) {
                  final a = e.value;
                  final isLast = e.key == provider.accounts.length - 1;
                  return Column(
                    children: [
                      _buildPickerAccountRow(
                        ctx: ctx,
                        isDark: isDark,
                        cf: cf,
                        icon: _iconForType(a.type),
                        iconColor: _colorFromHex(a.color),
                        name: a.name,
                        sublabel: a.bankName ??
                            (a.type[0].toUpperCase() + a.type.substring(1)),
                        balance: a.balance,
                        isSelected: provider.selectedAccountId == a.id,
                        imagePath: a.imagePath,
                        onTap: () {
                          provider.setSelectedAccount(a.id);
                          Navigator.pop(ctx);
                        },
                      ),
                      if (!isLast)
                        Divider(
                            height: 1,
                            indent: 72,
                            color: Theme.of(ctx).dividerColor),
                    ],
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerAccountRow({
    required BuildContext ctx,
    required bool isDark,
    required NumberFormat cf,
    required String icon,
    required Color iconColor,
    required String name,
    required String sublabel,
    required double balance,
    required bool isSelected,
    required VoidCallback onTap,
    String? imagePath,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: (imagePath.startsWith('http')
                          ? Image.network(imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Iconify(icon, color: iconColor, size: 20))
                          : Image.file(File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Iconify(icon, color: iconColor, size: 20))),
                    )
                  : Iconify(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(cf.format(balance),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Iconify(
              isSelected ? AppIcons.checkCircle : AppIcons.circleEmpty,
              color: isSelected
                  ? AppTheme.goldPrimary
                  : Theme.of(ctx).dividerColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
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
                        color: AppTheme.goldPrimary))
                : Image.file(File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        _getAccountIcon(provider),
                        size: 16,
                        color: AppTheme.goldPrimary)),
          ),
        );
      }
    }
    return Icon(
      provider.selectedAccountId == null
          ? Icons.account_balance_wallet_rounded
          : _getAccountIcon(provider),
      size: 16,
      color: AppTheme.goldPrimary,
    );
  }

  IconData _getAccountIcon(AppProvider provider) {
    if (provider.selectedAccountId == null)
      return Icons.account_balance_wallet_rounded;
    final account =
        provider.accounts.where((a) => a.id == provider.selectedAccountId);
    if (account.isEmpty) return Icons.account_balance_wallet_rounded;
    switch (account.first.type) {
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

        final totalBank = provider.getTotalByAccountType('bank');
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

        final cf = CurrencyHelper.formatter(provider.settings.currency);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
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
                                child: Iconify(AppIcons.settings,
                                    size: 22,
                                    color:
                                        isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Account picker
                        GestureDetector(
                          onTap: () => _showAccountPicker(context, provider),
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
                              boxShadow: isDark ? [] : AppTheme.cardShadowLight,
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
                                Iconify(AppIcons.caretUpDown,
                                    size: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                              ],
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
                      decoration: AppTheme.goldCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.netWorth,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(cf.format(netWorth),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5)),
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.transparent
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(s.allTime,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w500)), // TODO: localize
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _goldStatCol(s.income, '+${cf.format(income)}',
                                  AppTheme.success),
                              _goldStatCol(s.debt, '-${cf.format(totalDebt)}',
                                  const Color(0xFFFF8A80)),
                              _goldStatCol(
                                  s.netWorth,
                                  cf.format(netWorth),
                                  netWorth >= 0
                                      ? AppTheme.success
                                      : const Color(0xFFFF8A80)),
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
                            iconPath: 'assets/icons/bank_account.svg',
                            label: s.accounts,
                            sublabel: s.checkingCurrent,
                            amount: totalBank,
                            color: const Color(0xFF3B82F6),
                            isFirst: true,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AccountsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            iconPath: 'assets/icons/cash.svg',
                            label: s.cashOnHand,
                            sublabel: s.fromWithdrawals,
                            amount: totalCash,
                            color: AppTheme.goldPrimary,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CashOnHandScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            iconPath: 'assets/icons/investments.svg',
                            label: s.investments,
                            sublabel: s.stocksFundsEtc,
                            amount: totalInvestments,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PortfolioScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            iconPath: 'assets/icons/debt.svg',
                            label: s.debt,
                            sublabel: s.loansAndDebts,
                            amount: -totalDebt,
                            color: const Color(0xFFEF4444),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DebtScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            iconPath: 'assets/icons/personal_debt.svg',
                            label: s.personalDebts,
                            sublabel: s.moneyPeopleOweMe,
                            amount: totalPersonalDebt,
                            color: const Color(0xFFF97316),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PersonalDebtsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            iconPath: 'assets/icons/goals.svg',
                            label: s.savingsGoals,
                            sublabel: s.moneyForGoals,
                            amount: totalSavings,
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const GoalsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context,
                            cf: cf,
                            iconPath: 'assets/icons/daret.svg',
                            label: s.daret,
                            sublabel: s.rotatingSavings,
                            amount: provider.totalDaretNetPosition,
                            color: const Color(0xFF6366F1),
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

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownItem({
    required BuildContext context,
    required NumberFormat cf,
    required String iconPath,
    required String label,
    required String sublabel,
    required double amount,
    required Color color,
    required VoidCallback onTap,
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
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
                  '${amount < 0 ? '-' : ''}${cf.format(amount.abs())}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: amount < 0 ? AppTheme.error : null),
                ),
                const SizedBox(width: 8),
                Iconify(AppIcons.caretRight,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _goldStatCol(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
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
