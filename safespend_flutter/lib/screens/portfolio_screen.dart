import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/holding.dart';
import '../models/account.dart';
import '../services/stock_price_service.dart';
import '../utils/currency_helper.dart';
import '../widgets/app_form_sheet.dart';
import '../widgets/app_picker_field.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feature_help_button.dart';

enum _PortfolioSortOption {
  totalValueHigh,
  totalValueLow,
  newest,
  oldest,
  name,
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  bool _refreshing = false;
  List<PortfolioPoint> _chartPoints = [];
  Map<String, List<PortfolioPoint>> _holdingHistories = {};
  bool _chartLoading = false;
  String _chartRange = '1mo'; // '5d' | '1mo' | '3mo' | '1y'
  bool _showChartView = true;
  _PortfolioSortOption _assetSort = _PortfolioSortOption.totalValueHigh;
  double _fxRate = 1.0; // USD → user's currency rate

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      _fetchFxRate(provider.settings.currency);
      if (provider.holdings.isNotEmpty) _loadChart(provider.holdings);
    });
  }

  Future<void> _fetchFxRate(String currency) async {
    final rate = await StockPriceService.fetchUsdRate(currency);
    if (mounted) setState(() => _fxRate = rate);
  }

  Future<void> _loadChart(List<Holding> holdings) async {
    if (_chartLoading) return;
    setState(() => _chartLoading = true);
    final result =
        await StockPriceService.fetchPortfolioHistoryAll(holdings, _chartRange);
    if (mounted) {
      setState(() {
        _chartPoints = result.combined;
        _holdingHistories = result.perSymbol;
        _chartLoading = false;
      });
    }
  }

  void _changeRange(String range, List<Holding> holdings) {
    if (_chartRange == range) return;
    setState(() => _chartRange = range);
    _loadChart(holdings);
  }

  Future<void> _refreshAll(AppProvider provider) async {
    if (_refreshing || provider.holdings.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      // Refresh FX rate and prices in parallel
      await Future.wait([
        _fetchFxRate(provider.settings.currency),
        () async {
          final symbols =
              provider.holdings.map((h) => h.symbol).toSet().toList();
          final quotes = await StockPriceService.fetchMultiple(symbols);
          for (final h in provider.holdings) {
            final q = quotes[h.symbol];
            if (q != null && q.price != h.currentPrice) {
              provider.updateHolding(h.copyWith(currentPrice: q.price));
            }
          }
        }(),
      ]);
      await _loadChart(provider.holdings);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _holdingDisplayName(Holding holding) {
    final title = holding.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return holding.symbol.trim();
  }

  int _compareHoldingNames(Holding a, Holding b) {
    final byName = _holdingDisplayName(a)
        .toLowerCase()
        .compareTo(_holdingDisplayName(b).toLowerCase());
    if (byName != 0) return byName;
    return a.symbol.toLowerCase().compareTo(b.symbol.toLowerCase());
  }

  int _comparePurchaseDate(Holding a, Holding b, {required bool newestFirst}) {
    final aDate =
        a.purchaseDate == null ? null : DateTime.tryParse(a.purchaseDate!);
    final bDate =
        b.purchaseDate == null ? null : DateTime.tryParse(b.purchaseDate!);

    if (aDate != null && bDate != null) {
      final byDate =
          newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    } else if (aDate == null && bDate != null) {
      return 1;
    } else if (aDate != null && bDate == null) {
      return -1;
    }

    return _compareHoldingNames(a, b);
  }

  List<Holding> _sortedHoldings(List<Holding> holdings) {
    final sorted = List<Holding>.from(holdings);
    sorted.sort((a, b) {
      switch (_assetSort) {
        case _PortfolioSortOption.totalValueHigh:
          final byValue = b.currentValue.compareTo(a.currentValue);
          return byValue != 0 ? byValue : _compareHoldingNames(a, b);
        case _PortfolioSortOption.totalValueLow:
          final byValue = a.currentValue.compareTo(b.currentValue);
          return byValue != 0 ? byValue : _compareHoldingNames(a, b);
        case _PortfolioSortOption.newest:
          return _comparePurchaseDate(a, b, newestFirst: true);
        case _PortfolioSortOption.oldest:
          return _comparePurchaseDate(a, b, newestFirst: false);
        case _PortfolioSortOption.name:
          return _compareHoldingNames(a, b);
      }
    });
    return sorted;
  }

  String _sortLabel(S s, _PortfolioSortOption option) {
    switch (option) {
      case _PortfolioSortOption.totalValueHigh:
        return '${s.totalValue} · ${s.sortHighest}';
      case _PortfolioSortOption.totalValueLow:
        return '${s.totalValue} · ${s.sortLowest}';
      case _PortfolioSortOption.newest:
        return s.sortNewest;
      case _PortfolioSortOption.oldest:
        return s.sortOldest;
      case _PortfolioSortOption.name:
        return s.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sym = CurrencyHelper.getSymbol(provider.settings.currency);
        final fx = _fxRate; // USD → user currency multiplier
        final totalValue = provider.getTotalPortfolioValue() * fx;
        final totalCost = provider.getTotalPortfolioCost() * fx;
        final gainLoss = provider.getTotalPortfolioGainLoss() * fx;
        final gainLossPercent =
            totalCost > 0 ? (gainLoss / totalCost) * 100 : 0.0;
        final isPositive = gainLoss >= 0;
        final sortedHoldings = _sortedHoldings(provider.holdings);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FB),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ─── HEADER ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AppIcon(AppIcons.back,
                                size: 22,
                                color: AppTheme.adaptiveIcon(context)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.portfolio,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              if (provider.holdings.isNotEmpty)
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(s.livePrices,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (provider.holdings.isNotEmpty)
                          GestureDetector(
                            onTap: () => _refreshAll(provider),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _refreshing
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : AppIcon(AppIcons.refresh,
                                      size: 22,
                                      color: AppTheme.adaptiveIcon(context)),
                            ),
                          ),
                        FeatureHelpButton(
                          title: s.portfolio,
                          description: s.tourWealthBody,
                          icon: IOSIcons.trending_up_rounded,
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showAddHoldingModal(context, provider),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AppIcon(AppIcons.add,
                                size: 24,
                                color: AppTheme.adaptiveIcon(context)),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 240.ms, curve: Curves.easeOut)
                      .slideY(begin: -0.05, end: 0, curve: Curves.easeOut),
                ),

                // ─── STATS CARDS ROW ───
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 148,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      children: [
                        _buildStatCard(
                          context: context,
                          isDark: isDark,
                          title: s.totalValue,
                          value: '$sym${_formatNumber(totalValue)}',
                          change: gainLossPercent,
                          chartData: _generateSparklineData(isPositive),
                          chartColor:
                              isPositive ? AppTheme.success : AppTheme.error,
                          width: 170,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context: context,
                          isDark: isDark,
                          title: s.gainLoss,
                          value:
                              '${isPositive ? '+' : ''}$sym${_formatNumber(gainLoss.abs())}',
                          change: gainLossPercent,
                          chartData: _generateSparklineData(isPositive),
                          chartColor:
                              isPositive ? AppTheme.success : AppTheme.error,
                          width: 160,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context: context,
                          isDark: isDark,
                          title: s.holdings,
                          value: '${provider.holdings.length}',
                          subtitle: s.activePositions,
                          showBarChart: true,
                          barData: provider.holdings
                              .take(6)
                              .map((h) =>
                                  (h.currentValue * fx) /
                                  (totalValue > 0 ? totalValue : 1))
                              .toList(),
                          width: 140,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context: context,
                          isDark: isDark,
                          title: s.totalCost,
                          value: '$sym${_formatNumber(totalCost)}',
                          subtitle: s.investedAmount,
                          chartData: _generateSparklineData(true),
                          chartColor: const Color(0xFF6366F1),
                          width: 160,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                      duration: 260.ms, delay: 80.ms, curve: Curves.easeOut),
                ),

                // ─── MAIN PORTFOLIO CHART ───
                if (provider.holdings.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE8EAED)),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chart header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(s.myPortfolio,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (isPositive
                                                  ? AppTheme.success
                                                  : AppTheme.error)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${isPositive ? '+' : ''}${gainLossPercent.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isPositive
                                                  ? AppTheme.success
                                                  : AppTheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '$sym${_formatNumber(totalValue)}',
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87),
                                      ),
                                      // View toggle
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.06)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Wrap(
                                          runSpacing: 6,
                                          children: [
                                            _buildToggleButton(
                                                s.assets,
                                                !_showChartView,
                                                () => setState(() =>
                                                    _showChartView = false),
                                                isDark),
                                            _buildToggleButton(
                                                s.chart,
                                                _showChartView,
                                                () => setState(() =>
                                                    _showChartView = true),
                                                isDark),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Time range selector
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Wrap(
                                spacing: 0,
                                runSpacing: 8,
                                children:
                                    ['5d', '1mo', '3mo', '1y'].map((range) {
                                  final isSelected = _chartRange == range;
                                  final label = range == '5d'
                                      ? s.oneWeek
                                      : range == '1mo'
                                          ? s.oneMonth
                                          : range == '3mo'
                                              ? s.threeMonths
                                              : s.oneYear;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => _changeRange(
                                          range, provider.holdings),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.success
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.success
                                                  : (isDark
                                                      ? Colors.white24
                                                      : const Color(
                                                          0xFFE5E7EB))),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white70
                                                    : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Chart
                            SizedBox(
                              height: 200,
                              child: _showChartView
                                  ? _buildMainChart(
                                      isDark, isPositive, fx, sym, s)
                                  : _buildTopAssetsView(provider.holdings,
                                      totalValue, isDark, fx, sym),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            duration: 260.ms,
                            delay: 120.ms,
                            curve: Curves.easeOut)
                        .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                  ),

                // ─── ASSETS SECTION HEADER ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          s.assets,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${provider.holdings.length}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                        PopupMenuButton<_PortfolioSortOption>(
                          initialValue: _assetSort,
                          tooltip: s.sortBy,
                          onSelected: (value) =>
                              setState(() => _assetSort = value),
                          itemBuilder: (context) => _PortfolioSortOption.values
                              .map(
                                (option) => PopupMenuItem<_PortfolioSortOption>(
                                  value: option,
                                  child: Text(_sortLabel(s, option)),
                                ),
                              )
                              .toList(),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                s.sortBy,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _sortLabel(s, _assetSort),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                              const SizedBox(width: 4),
                              AppIcon(AppIcons.caretDown,
                                  size: 18,
                                  color: AppTheme.adaptiveIcon(context)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── ASSETS LIST ───
                provider.holdings.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: AppIcon(AppIcons.chartLine,
                                    size: 40,
                                    color: AppTheme.adaptiveIcon(context)),
                              ),
                              const SizedBox(height: 20),
                              Text(s.noHoldings,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(s.addHoldingDesc,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45)),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final holding = sortedHoldings[index];
                              return _buildAssetCard(
                                context: context,
                                holding: holding,
                                totalValue: totalValue,
                                isDark: isDark,
                                fx: fx,
                                sym: sym,
                                onTap: () => _showEditHoldingModal(
                                    context, provider, holding),
                                onSell: () =>
                                    _showSellModal(context, provider, holding),
                                onDelete: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(s.deleteHolding),
                                      content: Text(
                                        s.tr('removeHoldingConfirmation', {
                                          'symbol': holding.symbol,
                                        }),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(s.cancel)),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: Text(s.delete)),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    provider.deleteHolding(holding.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(s.tr('holdingRemoved', {
                                          'symbol': holding.symbol,
                                        })),
                                      ));
                                    }
                                  }
                                },
                              )
                                  .animate()
                                  .fadeIn(
                                      duration: 240.ms,
                                      delay: Duration(milliseconds: 40 * index),
                                      curve: Curves.easeOut)
                                  .slideX(
                                      begin: 0.03,
                                      end: 0,
                                      curve: Curves.easeOut);
                            },
                            childCount: sortedHoldings.length,
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

  // ─── HELPER WIDGETS ───

  String _formatNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toStringAsFixed(2);
  }

  List<double> _generateSparklineData(bool isPositive) {
    final random = math.Random(42);
    final data = <double>[];
    double value = 50;
    for (int i = 0; i < 20; i++) {
      value += (random.nextDouble() - (isPositive ? 0.35 : 0.65)) * 10;
      value = value.clamp(10, 100);
      data.add(value);
    }
    return data;
  }

  Widget _buildStatCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String value,
    double? change,
    String? subtitle,
    List<double>? chartData,
    Color? chartColor,
    bool showBarChart = false,
    List<double>? barData,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54),
                    overflow: TextOverflow.ellipsis),
              ),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (change >= 0 ? AppTheme.success : AppTheme.error)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: change >= 0 ? AppTheme.success : AppTheme.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(subtitle,
                  style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.black38)),
            ),
          const Spacer(),
          if (showBarChart && barData != null)
            SizedBox(
              height: 26,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  barData.length.clamp(0, 6),
                  (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 6 + (barData[i] * 18).clamp(4, 18),
                      decoration: BoxDecoration(
                        color: _getBarColor(i).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (chartData != null)
            SizedBox(
              height: 26,
              child: CustomPaint(
                size: const Size(double.infinity, 26),
                painter: _SparklinePainter(
                    data: chartData,
                    color: chartColor ?? AppTheme.success,
                    isDark: isDark),
              ),
            )
          else
            const SizedBox(height: 26),
        ],
      ),
    );
  }

  Color _getBarColor(int index) {
    const colors = [
      const Color(0xFF0B715F),
      Color(0xFF6366F1),
      Color(0xFFF59E0B),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6)
    ];
    return colors[index % colors.length];
  }

  Widget _buildToggleButton(
      String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 4)
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(
      bool isDark, bool isPositive, double fx, String sym, S s) {
    if (_chartLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_chartPoints.length < 2) {
      return Center(
          child: Text(s.noChartData,
              style:
                  TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
    }

    final lineColor = isPositive ? AppTheme.success : AppTheme.error;
    // Scale chart points by fx so chart shows values in user's currency
    final points =
        _chartPoints.map((p) => PortfolioPoint(p.date, p.value * fx)).toList();
    double minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    double maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15;
    minY = (minY - pad).clamp(0, double.infinity);
    maxY = maxY + pad;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) => Text(
                    '$sym${_formatNumber(value)}',
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    isDark ? const Color(0xFF2D2D2D) : Colors.white,
                tooltipRoundedRadius: 10,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '$sym${s.y.toStringAsFixed(2)}',
                          TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(points.length,
                    (i) => FlSpot(i.toDouble(), points[i].value)),
                isCurved: true,
                curveSmoothness: 0.35,
                color: lineColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withOpacity(0.2),
                      lineColor.withOpacity(0.0)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAssetsView(List<Holding> holdings, double totalValue,
      bool isDark, double fx, String sym) {
    final sorted = List<Holding>.from(holdings)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
    final top = sorted.take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(top.length, (i) {
          final h = top[i];
          final pct =
              totalValue > 0 ? (h.currentValue / totalValue * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                StockLogo(symbol: h.symbol, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.symbol,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87)),
                      Text('${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                ),
                Text('$sym${_formatNumber(h.currentValue * fx)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAssetCard({
    required BuildContext context,
    required Holding holding,
    required double totalValue,
    required bool isDark,
    required double fx,
    required String sym,
    required VoidCallback onTap,
    required VoidCallback onSell,
    required VoidCallback onDelete,
  }) {
    final s = S.of(context);
    final isGain = holding.gainLoss >= 0;
    final gainColor = isGain ? AppTheme.success : AppTheme.error;
    final allocation = totalValue > 0 ? holding.currentValue / totalValue : 0.0;
    final parsedPurchaseDate = holding.purchaseDate == null
        ? null
        : DateTime.tryParse(holding.purchaseDate!);
    final localizedPurchaseDate = parsedPurchaseDate == null
        ? holding.purchaseDate
        : MaterialLocalizations.of(context)
            .formatMediumDate(parsedPurchaseDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Main row ──────────────────────────────────────────────
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  StockLogo(symbol: holding.symbol, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holding.title ?? holding.symbol,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizedPurchaseDate == null
                              ? s.tr('holdingShares', {
                                  'shares': holding.shares.toString(),
                                })
                              : s.tr('holdingSharesPurchasedOn', {
                                  'shares': holding.shares.toString(),
                                  'date': localizedPurchaseDate,
                                }),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: gainColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7)),
                    child: Text(
                      '${isGain ? '+' : ''}${holding.gainLossPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: gainColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sym${_formatNumber(holding.currentValue * fx)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      Text(
                        '@$sym${(holding.currentPrice * fx).toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(children: [
              // Sell
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onSell,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppTheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(AppIcons.sell,
                              color: AppTheme.adaptiveIcon(context), size: 14),
                          const SizedBox(width: 5),
                          Text(s.sell,
                              style: TextStyle(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Edit
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.goldPrimary.withOpacity(0.3)),
                    ),
                    child: Wrap(
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          AppIcon(AppIcons.edit,
                              color: AppTheme.adaptiveIcon(context), size: 14),
                          const SizedBox(width: 5),
                          Text(s.edit,
                              style: TextStyle(
                                  color: AppTheme.goldPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: AppIcon(AppIcons.delete,
                      color: AppTheme.adaptiveIcon(context), size: 16),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showAddHoldingModal(BuildContext context, AppProvider provider) {
    final s = S.of(context);
    showAppFormSheet(
      context: context,
      builder: (_) => AddHoldingModal(
        fxRate: _fxRate,
        onSave: (h) {
          provider.addHolding(h);
          Navigator.pop(context);
          final sourceMatches = h.sourceAccountId == null
              ? const <Account>[]
              : provider.accounts
                  .where((a) => a.id == h.sourceAccountId)
                  .toList();
          final sourceName =
              sourceMatches.isEmpty ? null : sourceMatches.first.name;
          final message = h.affectsSourceBalance && sourceName != null
              ? s.tr('holdingAddedAndFunded', {
                  'symbol': h.symbol,
                  'account': sourceName,
                })
              : s.tr('existingHoldingAdded', {'symbol': h.symbol});
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      ),
    );
  }

  void _showSellModal(
      BuildContext context, AppProvider provider, Holding holding) {
    final s = S.of(context);
    final sym = CurrencyHelper.getSymbol(provider.settings.currency);
    showAppFormSheet(
      context: context,
      builder: (_) => SellHoldingModal(
        holding: holding,
        accounts: provider.accounts,
        cashBalance: provider.totalCash,
        currencySymbol: sym,
        fxRate: _fxRate,
        onSell: ({
          required double sharesToSell,
          required double sellPrice,
          required String accountId,
          required String transactionId,
        }) {
          provider.sellHolding(
            holding: holding,
            sharesToSell: sharesToSell,
            sellPrice: sellPrice,
            accountId: accountId,
            transactionId: transactionId,
          );
          Navigator.pop(context);
          final proceeds = sharesToSell *
              sellPrice *
              _fxRate; // convert USD proceeds to local currency for display
          final dest = accountId == AppProvider.cashOnHandId
              ? s.cashOnHand
              : provider.accounts
                  .firstWhere((a) => a.id == accountId,
                      orElse: () => provider.accounts.first)
                  .name;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.tr('holdingSaleCompleted', {
              'shares': sharesToSell.toString(),
              'symbol': holding.symbol,
              'amount': '$sym${proceeds.toStringAsFixed(2)}',
              'destination': dest,
            })),
            backgroundColor: AppTheme.success,
          ));
        },
      ),
    );
  }

  void _showEditHoldingModal(
      BuildContext context, AppProvider provider, Holding holding) {
    final s = S.of(context);
    showAppFormSheet(
      context: context,
      builder: (_) => AddHoldingModal(
        holding: holding,
        fxRate: _fxRate,
        onSave: (h) {
          provider.updateHolding(h);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.tr('holdingUpdated', {'symbol': h.symbol}))));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio Chart  (Total | per-symbol | Compare all)
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioChart extends StatefulWidget {
  final List<PortfolioPoint> points; // combined total
  final Map<String, List<PortfolioPoint>> holdingHistories; // per symbol
  final List<Holding> holdings;
  final bool loading;
  final String range;
  final ValueChanged<String> onRangeChanged;

  const _PortfolioChart({
    required this.points,
    required this.holdingHistories,
    required this.holdings,
    required this.loading,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  State<_PortfolioChart> createState() => _PortfolioChartState();
}

class _PortfolioChartState extends State<_PortfolioChart> {
  int? _touchedIndex;
  PortfolioPoint? _hoveredPoint;

  /// null = 'Total', '__compare__' = all colored, or a symbol string
  String? _filter;

  static const _ranges = ['5d', '1mo', '3mo', '1y'];
  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFF0B715F),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
    Color(0xFFF97316),
  ];

  bool get _isCompare => _filter == '__compare__';

  List<PortfolioPoint> get _activePoints {
    if (_filter == null || _isCompare) return widget.points;
    return widget.holdingHistories[_filter] ?? [];
  }

  Color _colorForSymbol(String sym) {
    final syms = widget.holdingHistories.keys.toList();
    final idx = syms.indexOf(sym);
    return _palette[(idx < 0 ? 0 : idx) % _palette.length];
  }

  Color get _singleLineColor {
    final pts = _activePoints;
    final isUp = pts.length >= 2 ? pts.last.value >= pts.first.value : true;
    if (_filter != null && !_isCompare) return _colorForSymbol(_filter!);
    return isUp ? AppTheme.success : AppTheme.error;
  }

  // Build spots for compare mode — align all series to a shared date index
  List<LineChartBarData> _buildCompareLines() {
    final allDates = <DateTime>{};
    for (final pts in widget.holdingHistories.values) {
      allDates.addAll(pts.map((p) => p.date));
    }
    final sortedDates = allDates.toList()..sort((a, b) => a.compareTo(b));
    final dateIdx = <DateTime, int>{
      for (int i = 0; i < sortedDates.length; i++) sortedDates[i]: i,
    };

    return widget.holdingHistories.entries.map((entry) {
      final color = _colorForSymbol(entry.key);
      return LineChartBarData(
        spots: entry.value
            .map((p) => FlSpot((dateIdx[p.date] ?? 0).toDouble(), p.value))
            .toList(),
        isCurved: true,
        curveSmoothness: 0.25,
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }

  ({double minY, double maxY, double maxX}) _compareBounds() {
    double minV = double.infinity, maxV = 0, maxX = 0;
    for (final pts in widget.holdingHistories.values) {
      if (pts.length > maxX) maxX = pts.length.toDouble();
      for (final p in pts) {
        if (p.value < minV) minV = p.value;
        if (p.value > maxV) maxV = p.value;
      }
    }
    if (minV == double.infinity) minV = 0;
    final pad = (maxV - minV) * 0.15;
    return (
      minY: (minV - pad).clamp(0, double.infinity),
      maxY: maxV + pad,
      maxX: (maxX - 1).clamp(0, double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final points = _activePoints;
    final lineColor = _singleLineColor;
    final symbols = widget.holdingHistories.keys.toList();

    // Y bounds for single-line mode
    double minY = 0, maxY = 0;
    if (!_isCompare && points.isNotEmpty) {
      minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
      maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
      final pad = (maxY - minY) * 0.15;
      minY = (minY - pad).clamp(0, double.infinity);
      maxY = maxY + pad;
      if (minY == maxY) {
        minY = minY * 0.95;
        maxY = maxY * 1.05;
      }
    }

    final compareBounds = _isCompare ? _compareBounds() : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + range buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  if (!_isCompare) ...[
                    Text(
                      _hoveredPoint != null
                          ? '\$${_hoveredPoint!.value.toStringAsFixed(2)}'
                          : (_filter == null
                              ? s.tr('totalPortfolio')
                              : _filter!),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_hoveredPoint != null) ...[
                      const SizedBox(width: 8),
                      Text(
                          materialLocalizations
                              .formatCompactDate(_hoveredPoint!.date),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ] else
                    Text(
                      s.compareHoldings,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  const Spacer(),
                  ...List.generate(_ranges.length, (i) {
                    final r = _ranges[i];
                    final selected = widget.range == r;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => widget.onRangeChanged(r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF185FA5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF185FA5)
                                  : const Color(0xFFCCCCCC),
                            ),
                          ),
                          child: Text(
                            [
                              s.oneWeek,
                              s.oneMonth,
                              s.threeMonths,
                              s.oneYear
                            ][i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Filter chips: Total | AAPL | BTC-USD | … | Compare
            if (symbols.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ChartFilterChip(
                        label: s.tr('totalLabel'),
                        selected: _filter == null,
                        color: AppTheme.success,
                        onTap: () => setState(() {
                          _filter = null;
                          _touchedIndex = null;
                          _hoveredPoint = null;
                        }),
                      ),
                      ...symbols.map((sym) => _ChartFilterChip(
                            label: sym,
                            selected: _filter == sym,
                            color: _colorForSymbol(sym),
                            onTap: () => setState(() {
                              _filter = sym;
                              _touchedIndex = null;
                              _hoveredPoint = null;
                            }),
                          )),
                      _ChartFilterChip(
                        label: s.tr('compare'),
                        selected: _isCompare,
                        color: const Color(0xFF7C3AED),
                        onTap: () => setState(() {
                          _filter = '__compare__';
                          _touchedIndex = null;
                          _hoveredPoint = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Chart area
            SizedBox(
              height: 220,
              child: widget.loading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: lineColor),
                      ),
                    )
                  : _isCompare
                      ? _buildCompareChart(compareBounds!, isDark)
                      : _buildSingleChart(
                          points, minY, maxY, lineColor, isDark),
            ),

            // ── Bottom row: legend (compare) or date+% (single)
            if (!widget.loading) ...[
              if (_isCompare)
                _buildLegend(symbols)
              else if (points.length >= 2)
                _buildDateRow(points, lineColor)
              else
                const SizedBox(height: 12),
            ] else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChart(List<PortfolioPoint> points, double minY,
      double maxY, Color lineColor, bool isDark) {
    if (points.length < 2) {
      return Center(
        child: Text(S.of(context).tr('noDataAvailable'),
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    final range = maxY - minY;
    final allSpots = List.generate(
        points.length, (i) => FlSpot(i.toDouble(), points[i].value));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY - (range == 0 ? 10 : range * 0.10),
        maxY: maxY + (range == 0 ? 10 : range * 0.10),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 100 : range / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.07),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2D2D2D),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((s) => LineTooltipItem(
                      '\$${s.y.toStringAsFixed(2)}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ))
                .toList(),
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              final idx = response.lineBarSpots!.first.x.round();
              if (idx >= 0 && idx < points.length) {
                setState(() {
                  _touchedIndex = idx;
                  _hoveredPoint = points[idx];
                });
              }
            } else if (event is FlTapUpEvent ||
                event is FlLongPressEnd ||
                event is FlPanEndEvent) {
              setState(() {
                _touchedIndex = null;
                _hoveredPoint = null;
              });
            }
          },
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: allSpots,
            isCurved: true,
            curveSmoothness: 0.40,
            color: lineColor,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _touchedIndex != null,
              getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                radius: index == _touchedIndex ? 5 : 0,
                color: lineColor,
                strokeWidth: 2,
                strokeColor: Colors.black,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.12),
                  lineColor.withOpacity(0.0)
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildCompareChart(
      ({double minY, double maxY, double maxX}) bounds, bool isDark) {
    final lines = _buildCompareLines();
    if (lines.isEmpty) {
      return Center(
        child: Text(S.of(context).tr('noDataAvailable'),
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: bounds.maxX,
        minY: bounds.minY,
        maxY: bounds.maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: lines,
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildDateRow(List<PortfolioPoint> points, Color lineColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              MaterialLocalizations.of(context)
                  .formatCompactDate(points.first.date),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10)),
          if (points.first.value > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                () {
                  final change = ((points.last.value - points.first.value) /
                          points.first.value) *
                      100;
                  return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
                }(),
                style: TextStyle(
                    color: lineColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          Text(
              MaterialLocalizations.of(context)
                  .formatCompactDate(points.last.date),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLegend(List<String> symbols) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: symbols.map((sym) {
            final color = _colorForSymbol(sym);
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(sym,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Small filter chip for chart modes
class _ChartFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChartFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color:
                selected ? color : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Market country model + data
// ─────────────────────────────────────────────────────────────────────────────

class _MarketCountry {
  final String l10nKey;
  final String name;
  final String flag;
  final String suffix; // Yahoo Finance exchange suffix, '' = US/global

  const _MarketCountry(this.l10nKey, this.name, this.flag, this.suffix);
}

const _kAllCountries = [
  // ── Global / US (no suffix) ──────────────────────────────────────────
  _MarketCountry('marketCountryGlobalUs', 'Global / US', '🌍', ''),
  // ── Africa ──────────────────────────────────────────────────────────
  _MarketCountry('marketCountryMorocco', 'Morocco', '🇲🇦', '.CS'),
  _MarketCountry('marketCountryEgypt', 'Egypt', '🇪🇬', '.CA'),
  _MarketCountry('marketCountrySouthAfrica', 'South Africa', '🇿🇦', '.JO'),
  _MarketCountry('marketCountryNigeria', 'Nigeria', '🇳🇬', '.LA'),
  _MarketCountry('marketCountryKenya', 'Kenya', '🇰🇪', '.NR'),
  // ── Middle East ─────────────────────────────────────────────────────
  _MarketCountry('marketCountrySaudiArabia', 'Saudi Arabia', '🇸🇦', '.SR'),
  _MarketCountry('marketCountryUae', 'UAE', '🇦🇪', '.AE'),
  _MarketCountry('marketCountryQatar', 'Qatar', '🇶🇦', '.QA'),
  _MarketCountry('marketCountryKuwait', 'Kuwait', '🇰🇼', '.KW'),
  _MarketCountry('marketCountryBahrain', 'Bahrain', '🇧🇭', '.BH'),
  _MarketCountry('marketCountryIsrael', 'Israel', '🇮🇱', '.TA'),
  _MarketCountry('marketCountryTurkey', 'Turkey', '🇹🇷', '.IS'),
  // ── Europe ──────────────────────────────────────────────────────────
  _MarketCountry('marketCountryFrance', 'France', '🇫🇷', '.PA'),
  _MarketCountry('marketCountryGermany', 'Germany', '🇩🇪', '.DE'),
  _MarketCountry('marketCountryUnitedKingdom', 'United Kingdom', '🇬🇧', '.L'),
  _MarketCountry('marketCountrySpain', 'Spain', '🇪🇸', '.MC'),
  _MarketCountry('marketCountryItaly', 'Italy', '🇮🇹', '.MI'),
  _MarketCountry('marketCountryNetherlands', 'Netherlands', '🇳🇱', '.AS'),
  _MarketCountry('marketCountryBelgium', 'Belgium', '🇧🇪', '.BR'),
  _MarketCountry('marketCountryPortugal', 'Portugal', '🇵🇹', '.LS'),
  _MarketCountry('marketCountrySwitzerland', 'Switzerland', '🇨🇭', '.SW'),
  _MarketCountry('marketCountrySweden', 'Sweden', '🇸🇪', '.ST'),
  _MarketCountry('marketCountryNorway', 'Norway', '🇳🇴', '.OL'),
  _MarketCountry('marketCountryDenmark', 'Denmark', '🇩🇰', '.CO'),
  _MarketCountry('marketCountryFinland', 'Finland', '🇫🇮', '.HE'),
  _MarketCountry('marketCountryAustria', 'Austria', '🇦🇹', '.VI'),
  _MarketCountry('marketCountryPoland', 'Poland', '🇵🇱', '.WA'),
  _MarketCountry('marketCountryCzechRepublic', 'Czech Republic', '🇨🇿', '.PR'),
  _MarketCountry('marketCountryHungary', 'Hungary', '🇭🇺', '.BD'),
  _MarketCountry('marketCountryRussia', 'Russia', '🇷🇺', '.ME'),
  _MarketCountry('marketCountryGreece', 'Greece', '🇬🇷', '.AT'),
  // ── Americas ────────────────────────────────────────────────────────
  _MarketCountry('marketCountryCanada', 'Canada', '🇨🇦', '.TO'),
  _MarketCountry('marketCountryBrazil', 'Brazil', '🇧🇷', '.SA'),
  _MarketCountry('marketCountryMexico', 'Mexico', '🇲🇽', '.MX'),
  _MarketCountry('marketCountryArgentina', 'Argentina', '🇦🇷', '.BA'),
  _MarketCountry('marketCountryChile', 'Chile', '🇨🇱', '.SN'),
  _MarketCountry('marketCountryColombia', 'Colombia', '🇨🇴', '.BC'),
  _MarketCountry('marketCountryPeru', 'Peru', '🇵🇪', '.LM'),
  // ── Asia Pacific ────────────────────────────────────────────────────
  _MarketCountry('marketCountryJapan', 'Japan', '🇯🇵', '.T'),
  _MarketCountry(
      'marketCountryChinaShanghai', 'China (Shanghai)', '🇨🇳', '.SS'),
  _MarketCountry(
      'marketCountryChinaShenzhen', 'China (Shenzhen)', '🇨🇳', '.SZ'),
  _MarketCountry('marketCountryHongKong', 'Hong Kong', '🇭🇰', '.HK'),
  _MarketCountry('marketCountrySouthKorea', 'South Korea', '🇰🇷', '.KS'),
  _MarketCountry('marketCountryIndiaNse', 'India (NSE)', '🇮🇳', '.NS'),
  _MarketCountry('marketCountryIndiaBse', 'India (BSE)', '🇮🇳', '.BO'),
  _MarketCountry('marketCountryAustralia', 'Australia', '🇦🇺', '.AX'),
  _MarketCountry('marketCountryNewZealand', 'New Zealand', '🇳🇿', '.NZ'),
  _MarketCountry('marketCountrySingapore', 'Singapore', '🇸🇬', '.SI'),
  _MarketCountry('marketCountryMalaysia', 'Malaysia', '🇲🇾', '.KL'),
  _MarketCountry('marketCountryThailand', 'Thailand', '🇹🇭', '.BK'),
  _MarketCountry('marketCountryIndonesia', 'Indonesia', '🇮🇩', '.JK'),
  _MarketCountry('marketCountryPhilippines', 'Philippines', '🇵🇭', '.PS'),
  _MarketCountry('marketCountryVietnam', 'Vietnam', '🇻🇳', '.VN'),
  _MarketCountry('marketCountryTaiwan', 'Taiwan', '🇹🇼', '.TW'),
  _MarketCountry('marketCountryPakistan', 'Pakistan', '🇵🇰', '.KA'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Country picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final _MarketCountry? selected;
  const _CountryPickerSheet({this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _ctrl = TextEditingController();
  List<_MarketCountry> _filtered = _kAllCountries;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      final s = S.of(context);
      setState(() {
        _filtered = q.isEmpty
            ? _kAllCountries
            : _kAllCountries
                .where((c) =>
                    c.name.toLowerCase().contains(q) ||
                    s.tr(c.l10nKey).toLowerCase().contains(q) ||
                    c.suffix.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    return AppFormSheet(
        header: Text(s.tr('selectMarket'),
            style: Theme.of(context).textTheme.titleLarge),
        body: Column(children: [
          TextField(
            controller: _ctrl,
            autofocus: false,
            decoration: InputDecoration(
              hintText: s.tr('searchCountry'),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: AppIcon(AppIcons.search,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 38, minHeight: 38),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final c = _filtered[i];
              final isSelected = widget.selected?.suffix == c.suffix;
              return InkWell(
                onTap: () => Navigator.pop(context, c),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.4))
                        : null,
                  ),
                  child: Row(children: [
                    Text(c.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(s.tr(c.l10nKey),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected ? const Color(0xFF7C3AED) : null,
                            ))),
                    if (c.suffix.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(c.suffix,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color)),
                      ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      AppIcon(AppIcons.checkCircle,
                          color: AppTheme.adaptiveIcon(context), size: 18),
                    ],
                  ]),
                ),
              );
            },
          )
        ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exchange filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _ExchangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ExchangeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C3AED);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent : accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? accent : accent.withOpacity(0.25)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : accent,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Logo Widget
// ─────────────────────────────────────────────────────────────────────────────

class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const StockLogo({super.key, required this.symbol, this.size = 44});

  /// Strip exchange suffixes: BTC-USD → BTC, AIR.PA → AIR
  String get _clean => symbol.toUpperCase().split('-').first.split('.').first;

  String get _logoUrl =>
      'https://assets.parqet.com/logos/symbol/$_clean?format=jpg';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.network(
        _logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final label = _clean.length > 4 ? _clean.substring(0, 4) : _clean;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF7C3AED),
            fontSize: size * 0.24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Holding Card
// ─────────────────────────────────────────────────────────────────────────────

class _HoldingCard extends StatelessWidget {
  final Holding holding;
  final bool isGain;
  final VoidCallback onTap;
  final VoidCallback onSell;

  const _HoldingCard({
    required this.holding,
    required this.isGain,
    required this.onTap,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StockLogo(symbol: holding.symbol, size: 44),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (holding.title != null &&
                            holding.title!.isNotEmpty) ...[
                          Text(
                            holding.title!,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            holding.symbol.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                          ),
                        ] else ...[
                          Text(holding.symbol.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          s.tr('holdingQuantity', {
                            'quantity': holding.shares.toString(),
                            'unit': holding.symbol.contains('-')
                                ? s.tr('units')
                                : s.shares,
                          }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${holding.currentValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGain
                              ? AppTheme.success.withOpacity(0.15)
                              : AppTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${isGain ? '+' : ''}${holding.gainLossPercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isGain ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCol(
                      label: s.tr('averageCost'),
                      value: '\$${holding.costBasis.toStringAsFixed(2)}'),
                  _StatCol(
                      label: s.currentPrice,
                      value: '\$${holding.currentPrice.toStringAsFixed(2)}'),
                  _StatCol(
                    label: s.gainLoss,
                    value:
                        '${isGain ? '+' : ''}\$${holding.gainLoss.toStringAsFixed(2)}',
                    valueColor: isGain ? AppTheme.success : AppTheme.error,
                    alignEnd: true,
                  ),
                ],
              ),
              if (holding.notes != null && holding.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  holding.notes!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 12),
              // Sell button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: onSell,
                  icon: const AppIcon(AppIcons.sell, size: 16),
                  label: Text(s.sell),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  const _StatCol({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Holding Modal  — with live price fetch
// ─────────────────────────────────────────────────────────────────────────────

class AddHoldingModal extends StatefulWidget {
  final Holding? holding;
  final Function(Holding) onSave;
  final double fxRate;

  const AddHoldingModal({
    super.key,
    this.holding,
    required this.onSave,
    this.fxRate = 1.0,
  });

  @override
  State<AddHoldingModal> createState() => _AddHoldingModalState();
}

class _AddHoldingModalState extends State<AddHoldingModal> {
  final _symbolCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _sharesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  String? _sourceAccountId;

  double? _livePrice;
  String? _companyName;
  bool _fetching = false;
  String? _fetchError;
  Timer? _debounce;

  List<StockSearchResult> _searchResults = [];
  bool _searching = false;
  Timer? _searchDebounce;
  String? _exchangeFilter; // null = all
  _MarketCountry _selectedCountry = _kAllCountries.first; // Global/US default

  @override
  void initState() {
    super.initState();
    if (widget.holding != null) {
      final h = widget.holding!;
      _symbolCtrl.text = h.symbol;
      _titleCtrl.text = h.title ?? '';
      _sharesCtrl.text = h.shares.toString();
      _costCtrl.text = h.costBasis.toString();
      _notesCtrl.text = h.notes ?? '';
      _livePrice = h.currentPrice > 0 ? h.currentPrice : null;
      if (h.purchaseDate != null) {
        _purchaseDate = DateTime.tryParse(h.purchaseDate!) ?? DateTime.now();
      }
      _sourceAccountId = h.sourceAccountId;
    }
    _symbolCtrl.addListener(_onSymbolChanged);
  }

  void _onSymbolChanged() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    final sym = _symbolCtrl.text.trim();
    if (sym.isEmpty) {
      setState(() {
        _livePrice = null;
        _companyName = null;
        _fetchError = null;
        _searchResults = [];
      });
      return;
    }
    _searchDebounce =
        Timer(const Duration(milliseconds: 400), _searchCompanies);
    _debounce = Timer(const Duration(milliseconds: 900), _fetchPrice);
  }

  Future<void> _searchCompanies() async {
    final query = _symbolCtrl.text.trim();
    if (query.length < 2) return;
    setState(() => _searching = true);
    final suffix =
        _selectedCountry.suffix.isEmpty ? null : _selectedCountry.suffix;
    final results =
        await StockPriceService.searchSymbols(query, preferredSuffix: suffix);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
      _exchangeFilter = null;
    });
  }

  void _selectResult(StockSearchResult r) {
    _symbolCtrl.text = r.symbol;
    if (_titleCtrl.text.trim().isEmpty) _titleCtrl.text = r.name;
    setState(() => _searchResults = []);
    _debounce?.cancel();
    _fetchPrice();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _symbolCtrl.removeListener(_onSymbolChanged);
    _symbolCtrl.dispose();
    _titleCtrl.dispose();
    _sharesCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<Account> _fundingAccounts(AppProvider provider) => provider.accounts
      .where((a) => a.type == 'bank' || a.type == 'savings')
      .toList();

  Account? _selectedFundingAccount(AppProvider provider) {
    if (_sourceAccountId == null) return null;
    final matches = _fundingAccounts(provider)
        .where((a) => a.id == _sourceAccountId)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  DateTime _accountTrackingStart(Account account) {
    final parsed = DateTime.tryParse(account.addedAt ?? '');
    return _dateOnly(parsed ?? DateTime.now());
  }

  bool _shouldDeductFromSource(AppProvider provider) {
    final account = _selectedFundingAccount(provider);
    if (account == null) return false;
    return !_dateOnly(_purchaseDate).isBefore(_accountTrackingStart(account));
  }

  Future<void> _fetchPrice() async {
    final sym = _symbolCtrl.text.trim().toUpperCase();
    if (sym.isEmpty) return;
    setState(() {
      _fetching = true;
      _fetchError = null;
    });
    final quote = await StockPriceService.fetchQuote(sym);
    if (!mounted) return;
    if (quote != null) {
      setState(() {
        _livePrice = quote.price;
        _companyName = quote.companyName;
        _fetching = false;
      });
      // Auto-fill title with company name if the user hasn't typed one yet
      if (_titleCtrl.text.trim().isEmpty && quote.companyName != null) {
        _titleCtrl.text = quote.companyName!;
      }
    } else {
      final s = S.of(context);
      setState(() {
        _fetchError = s.tr('portfolioSymbolNotFound', {'symbol': sym});
        _fetching = false;
      });
    }
  }

  void _save() {
    final s = S.of(context);
    final sym = _symbolCtrl.text.trim().toUpperCase();
    if (sym.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.tr('pleaseEnterSymbol'))));
      return;
    }
    final shares = double.tryParse(_sharesCtrl.text) ?? 0;
    if (shares <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.tr('enterValidShares'))));
      return;
    }
    final costBasis = double.tryParse(_costCtrl.text) ?? 0;
    final currentPrice = _livePrice ?? 0;
    final provider = context.read<AppProvider>();
    final selectedFundingAccount =
        widget.holding == null ? _selectedFundingAccount(provider) : null;
    final affectsSourceBalance = widget.holding?.affectsSourceBalance ??
        (selectedFundingAccount != null && _shouldDeductFromSource(provider));
    final sourceAmount = widget.holding?.sourceAmount ??
        (selectedFundingAccount == null
            ? null
            : shares * costBasis * widget.fxRate);

    final pdStr =
        '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}';
    widget.onSave(Holding(
      id: widget.holding?.id ?? const Uuid().v4(),
      symbol: sym,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      shares: shares,
      costBasis: costBasis,
      currentPrice: currentPrice,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      purchaseDate: pdStr,
      sourceAccountId:
          widget.holding?.sourceAccountId ?? selectedFundingAccount?.id,
      affectsSourceBalance: affectsSourceBalance,
      sourceAmount: sourceAmount,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<AppProvider>();
    final currencySymbol = CurrencyHelper.getSymbol(provider.settings.currency);
    final isEditing = widget.holding != null;
    final selectedFundingAccount = _selectedFundingAccount(provider);
    final trackedPurchase = !isEditing && _shouldDeductFromSource(provider);
    final materialLocalizations = MaterialLocalizations.of(context);
    final formattedTrackingStart = selectedFundingAccount == null
        ? null
        : materialLocalizations
            .formatMediumDate(_accountTrackingStart(selectedFundingAccount));
    final estimatedSourceAmount = (() {
      final shares = double.tryParse(_sharesCtrl.text) ?? 0;
      final costBasis = double.tryParse(_costCtrl.text) ?? 0;
      return shares > 0 && costBasis > 0
          ? shares * costBasis * widget.fxRate
          : null;
    })();
    return AppFormSheet(
        header: AppFormSheetHeader(
          title: widget.holding == null ? s.addHolding : s.editHolding,
          icon: IOSIcons.wealthInvestments,
          accent: AppTheme.adaptiveIcon(context),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () async {
              final picked = await showAppFormSheet<_MarketCountry>(
                context: context,
                builder: (_) => _CountryPickerSheet(selected: _selectedCountry),
              );
              if (picked != null) {
                setState(() {
                  _selectedCountry = picked;
                  _searchResults = [];
                  _exchangeFilter = null;
                });
                // Re-trigger search with new country
                if (_symbolCtrl.text.trim().length >= 2) _searchCompanies();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
              ),
              child: Row(children: [
                Text(_selectedCountry.flag,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(s.market,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7C3AED))),
                      Text(s.tr(_selectedCountry.l10nKey),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                if (_selectedCountry.suffix.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_selectedCountry.suffix,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED))),
                  ),
                AppIcon(AppIcons.caretDown,
                    color: AppTheme.adaptiveIcon(context), size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _symbolCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: s.searchByTickerOrName,
              hintText: s.tr('portfolioSearchHint'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              prefixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: AppIcon(AppIcons.search,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 38, minHeight: 38),
              suffixIcon: _symbolCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const AppIcon(AppIcons.close, size: 18),
                      onPressed: () {
                        _symbolCtrl.clear();
                        setState(() {
                          _searchResults = [];
                          _livePrice = null;
                          _companyName = null;
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _fetchPrice(),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Exchange filter chips
            Builder(builder: (ctx) {
              final exchanges = _searchResults
                  .map((r) => r.exchange)
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
              if (exchanges.length <= 1) return const SizedBox.shrink();
              return SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ExchangeChip(
                      label: s.all,
                      selected: _exchangeFilter == null,
                      onTap: () => setState(() => _exchangeFilter = null),
                    ),
                    ...exchanges.map((e) => _ExchangeChip(
                          label: e,
                          selected: _exchangeFilter == e,
                          onTap: () => setState(() => _exchangeFilter =
                              _exchangeFilter == e ? null : e),
                        )),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Builder(builder: (ctx) {
              final filtered = _exchangeFilter == null
                  ? _searchResults
                  : _searchResults
                      .where((r) => r.exchange == _exchangeFilter)
                      .toList();
              return Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, color: Theme.of(context).dividerColor),
                    itemBuilder: (ctx, i) {
                      final r = filtered[i];
                      final (typeLabel, typeColor) = switch (r.type) {
                        'CRYPTOCURRENCY' => (
                            s.tr('assetTypeCrypto'),
                            const Color(0xFFF59E0B)
                          ),
                        'ETF' => (
                            s.tr('assetTypeEtf'),
                            const Color(0xFF8B5CF6)
                          ),
                        'CURRENCY' => (
                            s.tr('assetTypeForex'),
                            const Color(0xFF06B6D4)
                          ),
                        'MUTUALFUND' => (
                            s.tr('assetTypeFund'),
                            const Color(0xFF0B715F)
                          ),
                        _ => (s.tr('assetTypeStock'), const Color(0xFF3B82F6)),
                      };
                      return InkWell(
                        onTap: () => _selectResult(r),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          child: Row(children: [
                            // Logo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: StockLogo(symbol: r.symbol, size: 40),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name + symbol + exchange
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      Text(r.symbol,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: typeColor)),
                                      if (r.exchange.isNotEmpty) ...[
                                        Text('  ·  ',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color)),
                                        Flexible(
                                            child: Text(r.exchange,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                      ],
                                    ]),
                                  ]),
                            ),
                            const SizedBox(width: 8),
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(typeLabel,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: typeColor)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ] else if (!_searching &&
              _symbolCtrl.text.trim().length >= 2 &&
              _livePrice == null) ...[
            const SizedBox(height: 8),
            // Fetch price button (shown when user has typed a ticker and no results)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _fetching ? null : _fetchPrice,
                icon: _fetching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const AppIcon(AppIcons.refresh, size: 18),
                label: Text(_fetching
                    ? s.tr('fetching')
                    : s.tr('fetchLivePriceFor', {
                        'symbol': _symbolCtrl.text.trim().toUpperCase(),
                      })),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                ),
              ),
            ),
          ],
          if (_livePrice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.checkCircle,
                      color: AppTheme.adaptiveIcon(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_companyName != null)
                          Text(_companyName!,
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        Text(
                          s.tr('livePriceAmount', {
                            'amount': '\$${_livePrice!.toStringAsFixed(2)}',
                          }),
                          style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_fetchError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(IOSIcons.error_outline,
                      color: AppTheme.adaptiveIcon(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_fetchError!,
                        style: TextStyle(color: AppTheme.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.tr('titleOptional'),
              hintText: s.tr('holdingTitleHint'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon:
                  Icon(IOSIcons.title, color: AppTheme.adaptiveIcon(context)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sharesCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.tr('holdingQuantityLabel'),
              hintText: '0',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon:
                  Icon(IOSIcons.numbers, color: AppTheme.adaptiveIcon(context)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.tr('averageBuyPricePerUnit'),
              hintText: '0.00',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(IOSIcons.attach_money,
                  color: AppTheme.adaptiveIcon(context)),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _purchaseDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _purchaseDate = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: s.tr('purchaseDate'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(IOSIcons.calendar_today_rounded,
                    color: AppTheme.adaptiveIcon(context)),
              ),
              child: Text(
                materialLocalizations.formatMediumDate(_purchaseDate),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isEditing) ...[
            AppPickerField<String>(
              label: s.sourceAccount,
              value: _sourceAccountId,
              prefixIcon: AppIcons.bank,
              helperText: s.tr('sourceAccountHelper'),
              items: _fundingAccounts(provider)
                  .map(
                    (account) => AppPickerItem(
                      value: account.id,
                      label: account.name,
                      subtitle: s.tr('availableTrackedFrom', {
                        'amount':
                            '$currencySymbol${account.balance.toStringAsFixed(2)}',
                        'date': materialLocalizations
                            .formatMediumDate(_accountTrackingStart(account)),
                      }),
                      leadingIcon: AppIcons.bank,
                      iconColor: AppTheme.adaptiveIcon(context),
                      imagePath: account.imagePath,
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _sourceAccountId = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selectedFundingAccount == null
                    ? Theme.of(context).cardColor
                    : (trackedPurchase ? AppTheme.success : AppTheme.warning)
                        .withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedFundingAccount == null
                      ? Theme.of(context).dividerColor.withOpacity(0.4)
                      : (trackedPurchase ? AppTheme.success : AppTheme.warning)
                          .withOpacity(0.28),
                ),
              ),
              child: Text(
                selectedFundingAccount == null
                    ? s.tr('noSourceAccountHoldingInfo')
                    : trackedPurchase
                        ? s.tr('purchaseDeductionInfo', {
                            'amount': estimatedSourceAmount == null
                                ? s.tr('enteredBuyAmount')
                                : '$currencySymbol${estimatedSourceAmount.toStringAsFixed(2)}',
                            'account': selectedFundingAccount.name,
                            'date': formattedTrackingStart!,
                          })
                        : s.tr('historicalPurchaseImportInfo', {
                            'account': selectedFundingAccount.name,
                            'date': formattedTrackingStart!,
                          }),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: selectedFundingAccount == null
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : (trackedPurchase
                              ? AppTheme.success
                              : AppTheme.warning),
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.4),
                ),
              ),
              child: Text(
                widget.holding?.affectsSourceBalance == true
                    ? s.tr('holdingSourceAlreadyAdjusted')
                    : s.tr('holdingImportedWithoutBalanceChange'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.tr('notesOptional'),
              hintText: s.tr('holdingNotesHint'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon:
                  Icon(IOSIcons.note, color: AppTheme.adaptiveIcon(context)),
            ),
          )
        ]),
        actions: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              widget.holding == null ? s.addHolding : s.saveChanges,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sell Holding Modal
// ─────────────────────────────────────────────────────────────────────────────

class SellHoldingModal extends StatefulWidget {
  final Holding holding;
  final List<Account> accounts;
  final double cashBalance;
  final String currencySymbol;
  final double fxRate; // USD → user currency multiplier
  final void Function({
    required double sharesToSell,
    required double sellPrice,
    required String accountId,
    required String transactionId,
  }) onSell;

  const SellHoldingModal({
    super.key,
    required this.holding,
    required this.accounts,
    required this.cashBalance,
    required this.currencySymbol,
    this.fxRate = 1.0,
    required this.onSell,
  });

  @override
  State<SellHoldingModal> createState() => _SellHoldingModalState();
}

class _SellHoldingModalState extends State<SellHoldingModal> {
  final _sharesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _selectedAccountId = AppProvider.cashOnHandId; // default: cash

  @override
  void initState() {
    super.initState();
    if (widget.holding.currentPrice > 0) {
      _priceCtrl.text =
          (widget.holding.currentPrice * widget.fxRate).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _sharesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _sharesToSell => double.tryParse(_sharesCtrl.text) ?? 0;
  double get _sellPrice =>
      double.tryParse(_priceCtrl.text) ?? 0; // in user's currency
  double get _sellPriceUsd => widget.fxRate > 0
      ? _sellPrice / widget.fxRate
      : _sellPrice; // back to USD for storage
  double get _proceeds => _sharesToSell * _sellPrice;
  double get _profitLoss =>
      _sharesToSell * (_sellPrice - widget.holding.costBasis * widget.fxRate);
  String get _sym => widget.currencySymbol;

  String _destLabel() {
    final s = S.of(context);
    if (_selectedAccountId == AppProvider.cashOnHandId) {
      return '${s.cashOnHand} · ${_sym}${widget.cashBalance.toStringAsFixed(0)}';
    }
    final a = widget.accounts.firstWhere((a) => a.id == _selectedAccountId,
        orElse: () => widget.accounts.first);
    return '${a.name} · ${_sym}${a.balance.toStringAsFixed(0)}';
  }

  void _confirm() {
    final s = S.of(context);
    if (_sharesToSell <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.enterSharesToSell)));
      return;
    }
    if (_sharesToSell > widget.holding.shares) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.tr(
              'youOnlyHold', {'shares': widget.holding.shares.toString()}))));
      return;
    }
    if (_sellPrice <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.enterSellPrice)));
      return;
    }
    widget.onSell(
      sharesToSell: _sharesToSell,
      sellPrice: _sellPriceUsd, // store in USD internally
      accountId: _selectedAccountId,
      transactionId: const Uuid().v4(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final isProfit = _profitLoss >= 0;
    final profitColor = isProfit ? AppTheme.success : AppTheme.error;

    // Build dropdown items: Cash first, then non-investment accounts
    final destItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: AppProvider.cashOnHandId,
        child: Row(children: [
          const Icon(IOSIcons.payments_rounded,
              size: 18, color: AppTheme.cashOnHandIcon),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
            '${s.cashOnHand}  ·  ${_sym}${widget.cashBalance.toStringAsFixed(0)}',
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
      ...widget.accounts.where((a) => a.type != 'investment').map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Row(children: [
                Icon(IOSIcons.account_balance_rounded,
                    size: 18, color: AppTheme.adaptiveIcon(context)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                  '${a.name}  ·  ${_sym}${a.balance.toStringAsFixed(0)}',
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          ),
    ];

    return AppFormSheet(
        header: AppFormSheetHeader(
          title: s.tr('sellSymbol', {'symbol': widget.holding.symbol}),
          icon: IOSIcons.wealthInvestments,
          accent: AppTheme.adaptiveIcon(context),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Text(
              s.tr('sharesAvailableLivePrice', {
                'shares': widget.holding.shares.toString(),
                'amount':
                    '$_sym${(widget.holding.currentPrice * widget.fxRate).toStringAsFixed(2)}',
              }),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(s.howManyShares,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextField(
                controller: _sharesCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: '/ ${widget.holding.shares}',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: Icon(IOSIcons.candlestick_chart_rounded,
                      color: AppTheme.adaptiveIcon(context)),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Quick-fill buttons
            Column(children: [
              _QuickFillButton(
                  label: '½',
                  onTap: () {
                    _sharesCtrl.text = (widget.holding.shares / 2)
                        .toStringAsFixed(widget.holding.shares ==
                                widget.holding.shares.roundToDouble()
                            ? 0
                            : 2);
                    setState(() {});
                  }),
              const SizedBox(height: 6),
              _QuickFillButton(
                  label: s.all,
                  onTap: () {
                    _sharesCtrl.text = widget.holding.shares.toString();
                    setState(() {});
                  },
                  color: AppTheme.error),
            ]),
          ]),
          const SizedBox(height: 16),
          Text(s.sellPricePerShare,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '$_sym ',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              prefixIcon: Icon(IOSIcons.sell_rounded,
                  color: AppTheme.adaptiveIcon(context)),
              filled: true,
              helperText: widget.holding.currentPrice > 0
                  ? s.tr('livePriceTapToUse', {
                      'amount':
                          '$_sym${(widget.holding.currentPrice * widget.fxRate).toStringAsFixed(2)}',
                    })
                  : null,
              helperStyle:
                  const TextStyle(color: AppTheme.goldPrimary, fontSize: 11),
              suffixIcon: widget.holding.currentPrice > 0
                  ? IconButton(
                      icon: Icon(IOSIcons.flash_on_rounded,
                          size: 18, color: AppTheme.adaptiveIcon(context)),
                      tooltip: s.tr('useLivePrice'),
                      onPressed: () {
                        _priceCtrl.text =
                            (widget.holding.currentPrice * widget.fxRate)
                                .toStringAsFixed(2);
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          AppPickerField<String>(
            label: s.tr('proceedsGoTo'),
            value: _selectedAccountId,
            prefixIcon: AppIcons.wallet,
            items: [
              AppPickerItem(
                value: AppProvider.cashOnHandId,
                label: s.cashOnHand,
                subtitle: s.tr('amountAvailable', {
                  'amount': '$_sym${widget.cashBalance.toStringAsFixed(2)}',
                }),
                leadingIcon: AppIcons.money,
                iconColor: AppTheme.cashOnHandIcon,
              ),
              ...widget.accounts.where((a) => a.type != 'investment').map(
                    (a) => AppPickerItem(
                      value: a.id,
                      label: a.name,
                      subtitle: s.tr('amountAvailable', {
                        'amount': '$_sym${a.balance.toStringAsFixed(2)}',
                      }),
                      leadingIcon: AppIcons.bank,
                      iconColor: AppTheme.adaptiveIcon(context),
                      imagePath: a.imagePath,
                    ),
                  ),
            ],
            onChanged: (v) => setState(
                () => _selectedAccountId = v ?? AppProvider.cashOnHandId),
          ),
          const SizedBox(height: 20),
          if (_sharesToSell > 0 && _sellPrice > 0) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceElevated
                    : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
              child: Column(children: [
                _SummaryRow(
                  label: s.tr('sharesTimesPrice'),
                  value:
                      '${_sharesToSell} × ${_sym}${_sellPrice.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: s.tr('totalProceeds'),
                  value: '${_sym}${_proceeds.toStringAsFixed(2)}',
                  valueStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: s.tr('costBasis'),
                  value:
                      '${_sym}${(_sharesToSell * widget.holding.costBasis * widget.fxRate).toStringAsFixed(2)}',
                  valueStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                Divider(
                    height: 20,
                    color: Theme.of(context).dividerColor.withOpacity(0.4)),
                _SummaryRow(
                  label: isProfit ? '📈 ${s.profit}' : '📉 ${s.loss}',
                  value:
                      '${isProfit ? '+' : ''}${_sym}${_profitLoss.toStringAsFixed(2)}',
                  valueStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: profitColor,
                      fontSize: 15),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: s.destinationAccount,
                  value: _destLabel(),
                  valueStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ]
        ]),
        actions: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              _sharesToSell > 0 && _sellPrice > 0
                  ? s.tr('sellForAmount', {
                      'amount': '$_sym${_proceeds.toStringAsFixed(2)}',
                    })
                  : s.confirmSell,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ));
  }
}

class _QuickFillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _QuickFillButton(
      {required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.goldPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 25,
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c))),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryRow(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value,
            style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparkline Painter for mini charts in stat cards
// ─────────────────────────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDark;

  _SparklinePainter(
      {required this.data, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
