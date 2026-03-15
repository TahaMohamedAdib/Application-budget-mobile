import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'accounts_screen.dart';
import 'cash_on_hand_screen.dart';
import 'debt_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import 'spending_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeFilter = 'all';
  bool _balanceVisible = true;
  String? _selectedAccountId; // null means "All Accounts"
  String _selectedTimeframe = '1m';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final totalCash = provider.totalCash;
        final currencyFormat = CurrencyHelper.formatter(provider.settings.currency);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAccountPicker(context, provider),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: AppTheme.borderedCard(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedAccountId == null ? Icons.account_balance_wallet_rounded : _getAccountIcon(provider),
                                  size: 16, color: AppTheme.goldPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(_getSelectedAccountName(provider), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Icon(Icons.unfold_more_rounded, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _headerIcon(Icons.settings_rounded, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        }),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                ),

                // Filter pills
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterPill('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterPill('Accounts', 'accounts'),
                          const SizedBox(width: 8),
                          _buildFilterPill('History', 'transactions'),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                ),

                // ── Account Balance Card ──
                if (_activeFilter == 'all' || _activeFilter == 'accounts')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.goldCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Balance', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(
                              _balanceVisible ? currencyFormat.format(_getAccountBalance(provider)) : '••••••',
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAccountId == null ? 'All accounts combined' : _getSelectedAccountName(provider),
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0),
                  ),

                // ── Balance Evolution Graph (All tab only) ──
                if (_activeFilter == 'all')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.premiumCard(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Balance Evolution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                Row(
                                  children: ['1d', '1w', '1m', '6m', '1y'].map((tf) {
                                    final isActive = _selectedTimeframe == tf;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedTimeframe = tf),
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isActive ? AppTheme.goldPrimary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tf.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isActive ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 160,
                              child: _buildBalanceChart(provider, isDark),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05, end: 0),
                  ),

                // ── Accounts Section (Accounts tab only) ──
                if (_activeFilter == 'accounts')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Accounts', style: Theme.of(context).textTheme.titleLarge),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                                child: Text('See all', style: TextStyle(fontSize: 13, color: AppTheme.goldPrimary, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...provider.accounts.map((account) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildAccountRow(
                              context: context,
                              icon: _iconForAccountType(account.type),
                              iconColor: AppTheme.goldPrimary,
                              label: account.name,
                              sublabel: account.bankName ?? account.type[0].toUpperCase() + account.type.substring(1),
                              amount: account.balance,
                              cf: currencyFormat,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                            ),
                          )),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildAccountRow(
                              context: context,
                              icon: Icons.payments_rounded,
                              iconColor: AppTheme.warning,
                              label: 'Cash on Hand',
                              sublabel: 'From withdrawals',
                              amount: totalCash,
                              cf: currencyFormat,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashOnHandScreen())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildAccountRow(
                              context: context,
                              icon: Icons.trending_up_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              label: 'Investments',
                              sublabel: '${provider.holdings.length} holdings',
                              amount: provider.totalInvestmentValue,
                              cf: currencyFormat,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioScreen())),
                            ),
                          ),
                          if (provider.totalDebtRemaining > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildAccountRow(
                                context: context,
                                icon: Icons.credit_card_rounded,
                                iconColor: AppTheme.error,
                                label: 'Debt',
                                sublabel: '${provider.goals.where((g) => g.type == "debt").length} items',
                                amount: -provider.totalDebtRemaining,
                                cf: currencyFormat,
                                isNegative: true,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtScreen())),
                              ),
                            ),
                          // Add Account button
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => AddAccountModal(
                                    onSave: (account) {
                                      provider.addAccount(account);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.goldPrimary.withOpacity(0.4),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.add_rounded, color: AppTheme.goldPrimary, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Text('Add Account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05, end: 0),
                  ),

                // ── Upcoming Subscriptions (All tab) ──
                if (_activeFilter == 'all')
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        final activeRules = provider.recurringRules.where((r) => r.isActive).toList()
                          ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
                        final upcoming = activeRules.take(3).toList();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Upcoming Subscriptions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => _showAllSubscriptions(context, provider),
                                    child: Text('See all', style: TextStyle(fontSize: 13, color: AppTheme.goldPrimary, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: AppTheme.premiumCard(context),
                                child: upcoming.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Center(child: Text('No subscriptions yet', style: Theme.of(context).textTheme.bodySmall)),
                                      )
                                    : Column(
                                        children: upcoming.asMap().entries.map((entry) {
                                          final rule = entry.value;
                                          final isLast = entry.key == upcoming.length - 1;
                                          return Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 42, height: 42,
                                                      decoration: BoxDecoration(
                                                        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Icon(Icons.autorenew_rounded, color: AppTheme.goldPrimary, size: 20),
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(rule.templateTransaction.note ?? 'Subscription', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                          const SizedBox(height: 2),
                                                          Text('Due ${DateFormat('MMM d').format(DateTime.parse(rule.nextDate))}', style: Theme.of(context).textTheme.bodySmall),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(currencyFormat.format(rule.templateTransaction.amount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                                  ],
                                                ),
                                              ),
                                              if (!isLast) Divider(height: 1, indent: 76, color: Theme.of(context).dividerColor),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 350.ms).slideY(begin: 0.05, end: 0);
                      },
                    ),
                  ),

                // ── Recent Transactions ──
                if (_activeFilter == 'all' || _activeFilter == 'transactions')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
                            child: Text('See all', style: TextStyle(fontSize: 13, color: AppTheme.goldPrimary, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  ),

                if (_activeFilter == 'all' || _activeFilter == 'transactions')
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: provider.transactions.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              decoration: AppTheme.premiumCard(context),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.receipt_long_rounded, size: 28, color: Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('No transactions yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text('Tap + to add your first transaction', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                                ],
                              ),
                            ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                          )
                        : SliverToBoxAdapter(
                            child: Container(
                              decoration: AppTheme.premiumCard(context),
                              child: Column(
                                children: provider.transactions.reversed.take(5).toList().asMap().entries.map((entry) {
                                  final transaction = entry.value;
                                  final isLast = entry.key == (provider.transactions.length > 5 ? 4 : provider.transactions.length - 1);
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42, height: 42,
                                              decoration: BoxDecoration(
                                                color: _getTransactionColor(transaction.type).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(_getTransactionIcon(transaction.type), color: _getTransactionColor(transaction.type), size: 20),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(transaction.note ?? 'Transaction', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 2),
                                                  Text(DateFormat('MMM d, yyyy').format(DateTime.parse(transaction.date)), style: Theme.of(context).textTheme.bodySmall),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _balanceVisible
                                                  ? '${transaction.type == 'income' ? '+' : '-'}${currencyFormat.format(transaction.amount)}'
                                                  : '••••••',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _getTransactionColor(transaction.type),
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
                            ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
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

  // ── Balance Chart ──
  Widget _buildBalanceChart(AppProvider provider, bool isDark) {
    final spots = _computeBalanceSpots(provider);
    if (spots.isEmpty || spots.length < 2) {
      return Center(child: Text('Not enough data', style: Theme.of(context).textTheme.bodySmall));
    }
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 100.0 : range * 0.15;

    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final now = DateTime.now();
    late DateTime chartStart;
    switch (_selectedTimeframe) {
      case '1d': chartStart = now.subtract(const Duration(hours: 24)); break;
      case '1w': chartStart = now.subtract(const Duration(days: 7)); break;
      case '1m': chartStart = now.subtract(const Duration(days: 30)); break;
      case '6m': chartStart = now.subtract(const Duration(days: 180)); break;
      case '1y': chartStart = now.subtract(const Duration(days: 365)); break;
      default: chartStart = now.subtract(const Duration(days: 30));
    }
    final numPoints = spots.length;
    final totalDuration = now.difference(chartStart);
    final intervalMs = totalDuration.inMilliseconds / (numPoints - 1);

    String formatYLabel(double v) {
      if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 100 : range / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: range == 0 ? 100 : range / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(formatYLabel(value), style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _selectedTimeframe == '1d' ? 6 : (_selectedTimeframe == '1w' ? 2 : (_selectedTimeframe == '1m' ? 7 : (_selectedTimeframe == '6m' ? 6 : 3))),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= numPoints) return const SizedBox.shrink();
                final pointTime = chartStart.add(Duration(milliseconds: (intervalMs * idx).round()));
                String label;
                if (_selectedTimeframe == '1d') {
                  label = DateFormat('HH:mm').format(pointTime);
                } else if (_selectedTimeframe == '1w' || _selectedTimeframe == '1m') {
                  label = DateFormat('d MMM').format(pointTime);
                } else {
                  label = DateFormat('MMM').format(pointTime);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(cf.format(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12));
            }).toList(),
          ),
        ),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppTheme.goldPrimary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.goldPrimary.withOpacity(0.25), AppTheme.goldPrimary.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _computeBalanceSpots(AppProvider provider) {
    final now = DateTime.now();
    late DateTime start;
    late int numPoints;

    switch (_selectedTimeframe) {
      case '1d':
        start = now.subtract(const Duration(hours: 24));
        numPoints = 24;
        break;
      case '1w':
        start = now.subtract(const Duration(days: 7));
        numPoints = 7;
        break;
      case '1m':
        start = now.subtract(const Duration(days: 30));
        numPoints = 30;
        break;
      case '6m':
        start = now.subtract(const Duration(days: 180));
        numPoints = 26;
        break;
      case '1y':
        start = now.subtract(const Duration(days: 365));
        numPoints = 12;
        break;
      default:
        start = now.subtract(const Duration(days: 30));
        numPoints = 30;
    }

    // Get relevant transactions for selected account
    final txns = provider.transactions.where((t) {
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) return false;
      final d = DateTime.parse(t.date);
      return d.isAfter(start.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Current balance
    double currentBalance = _getAccountBalance(provider);

    // Walk backwards: compute balance at start by reversing all transactions
    double balanceAtStart = currentBalance;
    for (final t in txns.reversed) {
      if (t.type == 'income') {
        balanceAtStart -= t.amount;
      } else if (t.type == 'expense' || t.type == 'withdrawal') {
        balanceAtStart += t.amount;
      } else if (t.type == 'transfer') {
        if (t.accountId == _selectedAccountId) {
          balanceAtStart += t.amount;
        } else if (t.toAccountId == _selectedAccountId) {
          balanceAtStart -= t.amount;
        }
      }
    }

    // Build spots by walking forward
    final totalDuration = now.difference(start);
    final intervalMs = totalDuration.inMilliseconds / (numPoints - 1);
    double runningBalance = balanceAtStart;
    int txnIdx = 0;
    final spots = <FlSpot>[];

    for (int i = 0; i < numPoints; i++) {
      final pointTime = start.add(Duration(milliseconds: (intervalMs * i).round()));
      // Apply all transactions up to this point
      while (txnIdx < txns.length && DateTime.parse(txns[txnIdx].date).isBefore(pointTime.add(const Duration(seconds: 1)))) {
        final t = txns[txnIdx];
        if (t.type == 'income') {
          runningBalance += t.amount;
        } else if (t.type == 'expense' || t.type == 'withdrawal') {
          runningBalance -= t.amount;
        } else if (t.type == 'transfer') {
          if (t.accountId == _selectedAccountId) {
            runningBalance -= t.amount;
          } else if (t.toAccountId == _selectedAccountId) {
            runningBalance += t.amount;
          }
        }
        txnIdx++;
      }
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }

    return spots;
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape: BoxShape.circle,
          boxShadow: isDark ? [] : AppTheme.cardShadowLight,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  double _getAccountBalance(AppProvider provider) {
    if (_selectedAccountId == null) {
      return provider.accounts.fold(0.0, (sum, a) => sum + a.balance);
    }
    final account = provider.accounts.where((a) => a.id == _selectedAccountId);
    return account.isNotEmpty ? account.first.balance : 0.0;
  }

  IconData _iconForAccountType(String type) {
    switch (type) {
      case 'bank': return Icons.account_balance_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'investment': return Icons.trending_up_rounded;
      case 'debt': return Icons.credit_card_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildAccountRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required double amount,
    required NumberFormat cf,
    required VoidCallback onTap,
    bool isNegative = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.premiumCard(context),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _balanceVisible ? cf.format(amount) : '••••••',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isNegative ? AppTheme.error : Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isActive = _activeFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldPrimary : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? AppTheme.goldGlow : (isDark ? [] : AppTheme.cardShadowLight),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'expense': return Icons.arrow_upward_rounded;
      case 'income': return Icons.arrow_downward_rounded;
      case 'transfer': return Icons.swap_horiz_rounded;
      case 'withdrawal': return Icons.account_balance_wallet_rounded;
      case 'goal_contribution': return Icons.savings_rounded;
      case 'debt_payment': return Icons.credit_card_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'expense': return AppTheme.error;
      case 'income': return AppTheme.success;
      case 'transfer': return AppTheme.info;
      case 'withdrawal': return AppTheme.warning;
      case 'goal_contribution': return AppTheme.goldPrimary;
      case 'debt_payment': return const Color(0xFF8B5CF6);
      default: return AppTheme.lightTextTertiary;
    }
  }

  String _getSelectedAccountName(AppProvider provider) {
    if (_selectedAccountId == null) return 'All Accounts';
    final account = provider.accounts.where((a) => a.id == _selectedAccountId);
    return account.isNotEmpty ? account.first.name : 'All Accounts';
  }

  IconData _getAccountIcon(AppProvider provider) {
    if (_selectedAccountId == null) return Icons.account_balance_wallet_rounded;
    final account = provider.accounts.where((a) => a.id == _selectedAccountId);
    if (account.isEmpty) return Icons.account_balance_wallet_rounded;
    switch (account.first.type) {
      case 'bank': return Icons.account_balance_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'investment': return Icons.trending_up_rounded;
      case 'debt': return Icons.credit_card_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Select Account', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              _buildAccountOption(ctx, null, 'All Accounts', Icons.account_balance_wallet_rounded, null, provider),
              if (provider.accounts.isNotEmpty) Divider(height: 1, indent: 72, color: Theme.of(ctx).dividerColor),
              ...provider.accounts.asMap().entries.map((entry) {
                final account = entry.value;
                final isLast = entry.key == provider.accounts.length - 1;
                IconData icon;
                switch (account.type) {
                  case 'bank': icon = Icons.account_balance_rounded; break;
                  case 'savings': icon = Icons.savings_rounded; break;
                  case 'investment': icon = Icons.trending_up_rounded; break;
                  case 'debt': icon = Icons.credit_card_rounded; break;
                  default: icon = Icons.account_balance_wallet_rounded;
                }
                return Column(
                  children: [
                    _buildAccountOption(ctx, account.id, account.name, icon, account.balance, provider),
                    if (!isLast) Divider(height: 1, indent: 72, color: Theme.of(ctx).dividerColor),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllSubscriptions(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final allRules = provider.recurringRules.where((r) => r.isActive).toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Text('All Subscriptions', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${allRules.length} active', style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(ctx).dividerColor),
              Flexible(
                child: allRules.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.autorenew_rounded, size: 48, color: Theme.of(ctx).textTheme.bodySmall?.color),
                            const SizedBox(height: 16),
                            Text('No subscriptions', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: allRules.length,
                        separatorBuilder: (_, __) => Divider(height: 1, indent: 76, color: Theme.of(ctx).dividerColor),
                        itemBuilder: (ctx, index) {
                          final rule = allRules[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.autorenew_rounded, color: AppTheme.goldPrimary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rule.templateTransaction.note ?? 'Subscription', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text('Due ${DateFormat('MMM d').format(DateTime.parse(rule.nextDate))} · ${rule.frequency}', style: Theme.of(ctx).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                Text(cf.format(rule.templateTransaction.amount), style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOption(BuildContext ctx, String? accountId, String name, IconData icon, double? balance, AppProvider provider) {
    final isSelected = _selectedAccountId == accountId;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final currencyFormat = CurrencyHelper.formatter(provider.settings.currency);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _selectedAccountId = accountId);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary.withOpacity(0.12) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: isSelected ? AppTheme.goldPrimary : Theme.of(ctx).textTheme.bodySmall?.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppTheme.goldPrimary : null)),
                  if (balance != null) Text(currencyFormat.format(balance), style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.goldPrimary, size: 22),
          ],
        ),
      ),
    );
  }
}
