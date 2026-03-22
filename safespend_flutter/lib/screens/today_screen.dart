import 'dart:io';
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
import 'all_subscriptions_screen.dart';
import '../widgets/add_transaction_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _activeFilter = 'all';

  void resetToAll() {
    setState(() => _activeFilter = 'all');
  }
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder,
                              ),
                              boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _selectedAccountId == null ? Icons.account_balance_wallet_rounded : _getAccountIcon(provider),
                                  size: 16, color: AppTheme.goldPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getSelectedAccountName(provider),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  ),
                                ),
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
                          const SizedBox(width: 10),
                          _buildFilterPill('Accounts', 'accounts'),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                              ),
                              child: Text('Transactions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 450.ms, delay: 80.ms),
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
                    ).animate().fadeIn(duration: 450.ms, delay: 160.ms).slideY(begin: 0.05, end: 0),
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
                            Text('Balance Evolution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            // ── Metric cards ──
                            Row(
                              children: [
                                _metricCard(context, 'Balance actuelle', currencyFormat.format(_getAccountBalance(provider)), const Color(0xFF1D9E75)),
                                const SizedBox(width: 8),
                                _metricCard(context, 'Dépenses / mois', currencyFormat.format(_getMonthlyExpenses(provider)), const Color(0xFFE24B4A)),
                                const SizedBox(width: 8),
                                _metricCard(
                                  context,
                                  'Épargne nette',
                                  (_getMonthlyIncome(provider) - _getMonthlyExpenses(provider) >= 0 ? '+' : '') +
                                      currencyFormat.format(_getMonthlyIncome(provider) - _getMonthlyExpenses(provider)),
                                  const Color(0xFF185FA5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Period pills ──
                            Row(
                              children: ['1d', '1w', '1m', '6m', '1y'].map((tf) {
                                final isActive = _selectedTimeframe == tf;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedTimeframe = tf),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFF185FA5) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isActive ? const Color(0xFF185FA5) : const Color(0xFFCCCCCC),
                                        ),
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
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: _buildBalanceChart(provider, isDark),
                            ),
                            const SizedBox(height: 12),
                            // ── Legend ──
                            Row(
                              children: [
                                _legendDot(const Color(0xFF1D9E75), 'Balance'),
                                const SizedBox(width: 16),
                                _legendDot(const Color(0xFFE24B4A), 'Revenu entrant'),
                                const SizedBox(width: 16),
                                _legendDot(const Color(0xFFBA7517), 'Seuil safe'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 450.ms, delay: 240.ms).slideY(begin: 0.05, end: 0),
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
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAccountRow(
                              context: context,
                              icon: _iconForAccountType(account.type),
                              iconColor: _colorFromHex(account.color),
                              label: account.name,
                              sublabel: account.bankName ?? account.type[0].toUpperCase() + account.type.substring(1),
                              amount: account.balance,
                              cf: currencyFormat,
                              imagePath: account.imagePath,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                            ),
                          )),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAccountRow(
                              context: context,
                              icon: Icons.payments_rounded,
                              iconColor: AppTheme.warning,
                              label: 'Cash',
                              sublabel: 'From withdrawals',
                              amount: totalCash,
                              cf: currencyFormat,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashOnHandScreen())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
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
                            padding: const EdgeInsets.only(bottom: 10),
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
                                    color: AppTheme.goldPrimary.withOpacity(0.3),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
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
                        final _now = DateTime.now();
                        final activeRules = provider.recurringRules
                            .where((r) => r.isActive && DateTime.parse(r.nextDate).isAfter(_now))
                            .toList()
                          ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
                        final upcoming = activeRules.take(3).toList();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Upcoming Subscriptions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllSubscriptionsScreen())),
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
                                                    Builder(builder: (_) {
                                                      final cat = rule.templateTransaction.categoryId != null
                                                          ? provider.categories.where((c) => c.id == rule.templateTransaction.categoryId).firstOrNull
                                                          : null;
                                                      final acct = provider.accounts.where((a) => a.id == rule.templateTransaction.accountId).firstOrNull;
                                                      final imgPath = (cat != null && cat.icon.startsWith('img:')) ? cat.icon.substring(4) : acct?.imagePath;
                                                      return Container(
                                                        width: 44, height: 44,
                                                        decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                                                        child: imgPath != null
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(14),
                                                                child: imgPath.startsWith('http')
                                                                    ? Image.network(imgPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.autorenew_rounded, color: AppTheme.goldPrimary, size: 20))
                                                                    : Image.file(File(imgPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.autorenew_rounded, color: AppTheme.goldPrimary, size: 20)),
                                                              )
                                                            : cat != null
                                                                ? Icon(_subCategoryIcon(cat.icon), color: AppTheme.goldPrimary, size: 20)
                                                                : const Icon(Icons.autorenew_rounded, color: AppTheme.goldPrimary, size: 20),
                                                      );
                                                    }),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(rule.templateTransaction.note ?? 'Subscription', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                          const SizedBox(height: 2),
                                                          Builder(builder: (ctx) {
                                            final nd = DateTime.parse(rule.nextDate);
                                            final today = DateTime.now();
                                            final isToday = nd.year == today.year && nd.month == today.month && nd.day == today.day;
                                            return Text(
                                              isToday ? 'Today · ${DateFormat('h:mm a').format(nd)}' : 'Due ${DateFormat('MMM d').format(nd)}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            );
                                          }),
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
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
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
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(Icons.receipt_long_rounded, size: 32, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                                  ),
                                  const SizedBox(height: 18),
                                  Text('No transactions yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text('Tap + to add your first transaction', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                                ],
                              ),
                            ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                          )
                        : SliverToBoxAdapter(
                            child: _buildGroupedTransactions(
                              provider.transactions.reversed.take(20).toList(),
                              currencyFormat, context, isDark,
                              provider: provider,
                            ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
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

  // ── Balance Chart ──
  Widget _buildBalanceChart(AppProvider provider, bool isDark) {
    const kGreen = Color(0xFF1D9E75);
    const kRed = Color(0xFFE24B4A);
    const kAmber = Color(0xFFBA7517);

    final spots = _computeBalanceSpots(provider);
    if (spots.isEmpty || spots.length < 2) {
      return Center(child: Text('Not enough data', style: Theme.of(context).textTheme.bodySmall));
    }
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 100.0 : range * 0.15;

    // Dynamic safe threshold at the lower 30 % of the balance range
    final safeThreshold = minY + (range == 0 ? 100 : range * 0.30);

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
    final intervalMs = numPoints > 1 ? totalDuration.inMilliseconds / (numPoints - 1) : 1.0;

    // Detect income spike indices: delta > 1.5× average positive delta
    final positiveDeltas = <double>[];
    for (int i = 1; i < spots.length; i++) {
      final d = spots[i].y - spots[i - 1].y;
      if (d > 0) positiveDeltas.add(d);
    }
    final avgDelta = positiveDeltas.isEmpty
        ? double.infinity
        : positiveDeltas.reduce((a, b) => a + b) / positiveDeltas.length;
    final spikeIndices = <int>{};
    for (int i = 1; i < spots.length; i++) {
      if (spots[i].y - spots[i - 1].y >= avgDelta * 1.5) spikeIndices.add(i);
    }

    // Split into green (≥ threshold) and red (< threshold) with bridge points
    final greenSpots = <FlSpot>[];
    final redSpots = <FlSpot>[];
    for (final s in spots) {
      if (s.y >= safeThreshold) {
        greenSpots.add(s);
        if (redSpots.isNotEmpty) redSpots.add(s);
      } else {
        redSpots.add(s);
        if (greenSpots.isNotEmpty) greenSpots.add(s);
      }
    }

    FlDotData dotData() => FlDotData(
      show: true,
      getDotPainter: (spot, _, __, index) {
        final originalIndex = spots.indexWhere((s) => s.x == spot.x && s.y == spot.y);
        if (spikeIndices.contains(originalIndex)) {
          return FlDotCirclePainter(
            radius: 5, color: kRed, strokeWidth: 2, strokeColor: Colors.white,
          );
        }
        return FlDotCirclePainter(radius: 0, color: Colors.transparent);
      },
    );

    LineChartBarData barData(List<FlSpot> s, Color color) => LineChartBarData(
      spots: s,
      isCurved: true,
      curveSmoothness: 0.45,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: dotData(),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
        ),
      ),
    );

    final lineBars = <LineChartBarData>[];
    if (greenSpots.isNotEmpty) lineBars.add(barData(greenSpots, kGreen));
    if (redSpots.isNotEmpty) lineBars.add(barData(redSpots, kRed));

    String formatYLabel(double v) {
      if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (numPoints - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 100 : range / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: safeThreshold,
              color: kAmber,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 4),
                style: const TextStyle(fontSize: 10, color: kAmber, fontWeight: FontWeight.w600),
                labelResolver: (_) => 'Seuil ${cf.format(safeThreshold)}',
              ),
            ),
          ],
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
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E2A38),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem(
              cf.format(s.y),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            )).toList(),
          ),
        ),
        lineBarsData: lineBars,
      ),
    );
  }

  // ── Metric helpers ──

  double _getMonthlyExpenses(AppProvider provider) {
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return provider.transactions.where((t) {
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) return false;
      final d = DateTime.parse(t.date);
      return (t.type == 'expense' || t.type == 'withdrawal') && d.isAfter(startOfMonth);
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getMonthlyIncome(AppProvider provider) {
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return provider.transactions.where((t) {
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) return false;
      final d = DateTime.parse(t.date);
      return t.type == 'income' && d.isAfter(startOfMonth);
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  Widget _metricCard(BuildContext context, String label, String value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF888888)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: valueColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
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

  IconData _subCategoryIcon(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home_rounded;
      case 'flash': return Icons.flash_on_rounded;
      case 'phone': return Icons.phone_android_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      case 'face': return Icons.face_rounded;
      case 'school': return Icons.school_rounded;
      case 'flight': return Icons.flight_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'pets': return Icons.pets_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'local_cafe': return Icons.local_cafe_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'build': return Icons.build_rounded;
      default: return Icons.autorenew_rounded;
    }
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.goldPrimary;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTheme.goldPrimary;
    }
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
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.premiumCard(context),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(icon, color: iconColor, size: 20),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldPrimary : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: isDark && !isActive ? Border.all(color: Colors.white.withOpacity(0.07), width: 1) : null,
          boxShadow: isActive ? AppTheme.goldGlow : (isDark ? [] : AppTheme.cardShadowLight),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }

  String _getDateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return DateFormat('EEEE').format(date).toUpperCase();
    return DateFormat('MMM d').format(date).toUpperCase();
  }

  Widget _buildGroupedTransactions(
    List<dynamic> transactions,
    NumberFormat cf,
    BuildContext context,
    bool isDark, {
    AppProvider? provider,
  }) {
    // Group by date
    final groups = <String, List<dynamic>>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(t.date));
      groups.putIfAbsent(key, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final items = entry.value;
        final date = DateTime.parse(entry.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
              child: Text(
                _getDateGroupLabel(date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: AppTheme.premiumCard(context),
              child: Column(
                children: items.asMap().entries.map((e) {
                  final isLast = e.key == items.length - 1;
                  final t = e.value;
                  final tColor = _getTransactionColor(t.type);

                  // Look up category for icon
                  final cat = (provider != null && t.categoryId != null)
                      ? provider.categories.where((c) => c.id == t.categoryId).firstOrNull
                      : null;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddTransactionModal(initialTransaction: t),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? tColor.withOpacity(0.12) : const Color(0xFFF0F1F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: cat != null
                                    ? _buildCategoryIcon(cat.icon, tColor)
                                    : Icon(_getTransactionIcon(t.type), color: tColor, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.note ?? cat?.name ?? 'Transaction',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('h:mm a').format(DateTime.parse(t.date)),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _balanceVisible
                                    ? '${t.type == 'income' ? '+' : '-'}${cf.format(t.amount)}'
                                    : '••••',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _getTransactionColor(t.type),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) Divider(height: 1, indent: 70, color: Theme.of(context).dividerColor),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryIcon(String iconStr, Color color) {
    if (iconStr.startsWith('img:')) {
      final path = iconStr.substring(4);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          width: 40, height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.category_rounded, color: color, size: 18),
        ),
      );
    }
    return Icon(_categoryIconData(iconStr), color: color, size: 18);
  }

  IconData _categoryIconData(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home_rounded;
      case 'flash': return Icons.flash_on_rounded;
      case 'phone': return Icons.phone_android_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      case 'face': return Icons.face_rounded;
      case 'school': return Icons.school_rounded;
      case 'flight': return Icons.flight_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'pets': return Icons.pets_rounded;
      case 'autorenew': return Icons.autorenew_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'local_cafe': return Icons.local_cafe_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'build': return Icons.build_rounded;
      default: return Icons.category_rounded;
    }
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
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 1.0,
        snap: true,
        snapSizes: const [0.55, 1.0],
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(2)))),
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
              Expanded(
                child: allRules.isEmpty
                    ? Center(
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
                        controller: scrollController,
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
