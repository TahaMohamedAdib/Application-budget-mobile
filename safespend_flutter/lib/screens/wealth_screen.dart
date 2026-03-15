import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'accounts_screen.dart';
import 'cash_on_hand_screen.dart';
import 'debt_screen.dart';
import 'budgets_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import 'spending_screen.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  String? _selectedAccountId; // null = all accounts


  void _showAccountPicker(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Select Account', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.goldPrimary),
                title: const Text('All Accounts'),
                trailing: _selectedAccountId == null ? const Icon(Icons.check_rounded, color: AppTheme.goldPrimary) : null,
                onTap: () { setState(() => _selectedAccountId = null); Navigator.pop(ctx); },
              ),
              ...provider.accounts.map((a) => ListTile(
                leading: const Icon(Icons.account_balance_rounded),
                title: Text(a.name),
                subtitle: a.bankName != null ? Text(a.bankName!) : null,
                trailing: _selectedAccountId == a.id ? const Icon(Icons.check_rounded, color: AppTheme.goldPrimary) : null,
                onTap: () { setState(() => _selectedAccountId = a.id); Navigator.pop(ctx); },
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getSelectedAccountName(AppProvider provider) {
    if (_selectedAccountId == null) return 'All Accounts';
    final a = provider.accounts.where((a) => a.id == _selectedAccountId);
    return a.isNotEmpty ? a.first.name : 'All Accounts';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

        final now = DateTime.now();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final totalWeekSpending = provider.transactions
            .where((t) => t.type == 'expense' && (_selectedAccountId == null || t.accountId == _selectedAccountId) && DateTime.parse(t.date).isAfter(DateTime(monday.year, monday.month, monday.day).subtract(const Duration(days: 1))))
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
                            Text('Wealth', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                  shape: BoxShape.circle,
                                  boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                                ),
                                child: const Icon(Icons.settings_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Account picker
                        GestureDetector(
                          onTap: () => _showAccountPicker(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, size: 15, color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(width: 8),
                                Text(_getSelectedAccountName(provider), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Icon(Icons.unfold_more_rounded, size: 15, color: Theme.of(context).textTheme.bodySmall?.color),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
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
                          Text('Net Worth', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(cf.format(netWorth), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1)),
                          const SizedBox(height: 20),
                          Container(height: 1, color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 16),
                          Text('All Time', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _goldStatCol('Income', '+${cf.format(income)}', AppTheme.success),
                              _goldStatCol('Expenses', '-${cf.format(expenses)}', const Color(0xFFFF8A80)),
                              _goldStatCol('Balance', '${balance >= 0 ? '+' : ''}${cf.format(balance)}', balance >= 0 ? AppTheme.success : const Color(0xFFFF8A80)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
                ),

                // ── Breakdown (clickable items) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text('Breakdown', style: Theme.of(context).textTheme.titleLarge),
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
                            context: context, cf: cf, icon: '🏦', label: 'Bank Accounts', sublabel: 'Checking & current',
                            amount: totalBank, color: const Color(0xFF3B82F6), isFirst: true,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context, cf: cf, icon: '💵', label: 'Cash on Hand', sublabel: 'From withdrawals',
                            amount: totalCash, color: AppTheme.goldPrimary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashOnHandScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context, cf: cf, icon: '��', label: 'Savings', sublabel: 'Goals & sinking funds',
                            amount: totalSavings, color: const Color(0xFFF59E0B),
                            onTap: () {
                              // Navigate to Budgets screen
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                            },
                          ),
                          _buildBreakdownItem(
                            context: context, cf: cf, icon: '📈', label: 'Investments', sublabel: 'Stocks, funds, etc.',
                            amount: totalInvestments, color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioScreen())),
                          ),
                          _buildBreakdownItem(
                            context: context, cf: cf, icon: '💳', label: 'Debt', sublabel: 'Loans & debts',
                            amount: -totalDebt, color: const Color(0xFFEF4444), isLast: true,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtScreen())),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    required String icon,
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
        if (!isFirst) Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
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
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(sublabel, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  '${amount < 0 ? '-' : ''}${cf.format(amount.abs())}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: amount < 0 ? AppTheme.error : null),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
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
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
