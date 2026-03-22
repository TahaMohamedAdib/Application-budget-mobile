import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/holding.dart';
import '../models/account.dart';
import '../services/stock_price_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _refreshing = false;
  List<PortfolioPoint> _chartPoints = [];
  Map<String, List<PortfolioPoint>> _holdingHistories = {};
  bool _chartLoading = false;
  String _chartRange = '1mo'; // '5d' | '1mo' | '3mo' | '1y'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.holdings.isNotEmpty) _loadChart(provider.holdings);
    });
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
      final symbols = provider.holdings.map((h) => h.symbol).toSet().toList();
      final quotes = await StockPriceService.fetchMultiple(symbols);
      for (final h in provider.holdings) {
        final q = quotes[h.symbol];
        if (q != null && q.price != h.currentPrice) {
          provider.updateHolding(h.copyWith(currentPrice: q.price));
        }
      }
      // Also reload chart with fresh data
      await _loadChart(provider.holdings);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final totalValue = provider.getTotalPortfolioValue();
        final totalCost = provider.getTotalPortfolioCost();
        final gainLoss = provider.getTotalPortfolioGainLoss();
        final gainLossPercent = totalCost > 0 ? (gainLoss / totalCost) * 100 : 0.0;

        // Card color: green when up, red when down, neutral purple when empty
        final cardColor = provider.holdings.isEmpty
            ? const Color(0xFF7C3AED)
            : gainLoss >= 0
                ? const Color(0xFF16A34A) // deep green
                : const Color(0xFFDC2626); // deep red

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Portfolio', style: Theme.of(context).textTheme.headlineSmall),
                        const Spacer(),
                        // Refresh prices button
                        if (provider.holdings.isNotEmpty)
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: _refreshing
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.refresh, size: 20),
                                    tooltip: 'Refresh live prices',
                                    onPressed: () => _refreshAll(provider),
                                    padding: EdgeInsets.zero,
                                  ),
                          ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 20, color: Colors.white),
                            onPressed: () => _showAddHoldingModal(context, provider),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Portfolio Summary Card
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.accentCard(cardColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pie_chart, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Total Value',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                              ),
                              const Spacer(),
                              if (provider.holdings.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _refreshAll(provider),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.bolt, color: Colors.white.withOpacity(0.9), size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Live',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\$${totalValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Cost',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Gain/Loss',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${gainLoss >= 0 ? '+' : ''}\$${gainLoss.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${gainLossPercent >= 0 ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Chart
                  if (provider.holdings.isNotEmpty)
                    _PortfolioChart(
                      points: _chartPoints,
                      holdingHistories: _holdingHistories,
                      holdings: provider.holdings,
                      loading: _chartLoading,
                      range: _chartRange,
                      onRangeChanged: (r) =>
                          _changeRange(r, provider.holdings),
                    ),

                  // Holdings List
                  Expanded(
                    child: provider.holdings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.show_chart, size: 64,
                                    color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(height: 16),
                                Text('No holdings yet',
                                    style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text('Tap + to add a stock, ETF or crypto',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.holdings.length,
                            itemBuilder: (context, index) {
                              final holding = provider.holdings[index];
                              final isGain = holding.gainLoss >= 0;

                              return Dismissible(
                                key: Key(holding.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Holding?'),
                                      content: Text('Remove ${holding.symbol} from your portfolio?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) {
                                  provider.deleteHolding(holding.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${holding.symbol} removed')),
                                  );
                                },
                                child: _HoldingCard(
                                  holding: holding,
                                  isGain: isGain,
                                  onTap: () => _showEditHoldingModal(context, provider, holding),
                                  onSell: () => _showSellModal(context, provider, holding),
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
      },
    );
  }

  void _showAddHoldingModal(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHoldingModal(
        onSave: (h) {
          provider.addHolding(h);
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${h.symbol} added')));
        },
      ),
    );
  }

  void _showSellModal(BuildContext context, AppProvider provider, Holding holding) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellHoldingModal(
        holding: holding,
        accounts: provider.accounts,
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
          final proceeds = sharesToSell * sellPrice;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Sold $sharesToSell × ${holding.symbol} for \$${proceeds.toStringAsFixed(2)}'),
          ));
        },
      ),
    );
  }

  void _showEditHoldingModal(BuildContext context, AppProvider provider, Holding holding) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHoldingModal(
        holding: holding,
        onSave: (h) {
          provider.updateHolding(h);
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${h.symbol} updated')));
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
  static const _rangeLabels = ['5D', '1M', '3M', '1Y'];

  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
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
                          : (_filter == null ? 'Total Portfolio' : _filter!),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_hoveredPoint != null) ...[
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM d').format(_hoveredPoint!.date),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ] else
                    Text(
                      'Compare Holdings',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  const Spacer(),
                  ...List.generate(_ranges.length, (i) {
                    final r = _ranges[i];
                    final selected = widget.range == r;
                    return GestureDetector(
                      onTap: () => widget.onRangeChanged(r),
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? lineColor.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _rangeLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? lineColor
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
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
                        label: 'Total',
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
                        label: 'Compare',
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
              height: 150,
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
                      : _buildSingleChart(points, minY, maxY, lineColor, isDark),
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
        child: Text('No data available',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            getTooltipItems: (_) => [],
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
            spots: List.generate(
                points.length, (i) => FlSpot(i.toDouble(), points[i].value)),
            isCurved: true,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: _touchedIndex != null,
              getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                radius: index == _touchedIndex ? 5 : 0,
                color: lineColor,
                strokeWidth: 2,
                strokeColor: isDark ? Colors.black : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.25),
                  lineColor.withValues(alpha: 0.0),
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
        child: Text('No data available',
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
          Text(DateFormat('MMM d').format(points.first.date),
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
          if (points.first.value > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                () {
                  final change =
                      ((points.last.value - points.first.value) /
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
          Text(DateFormat('MMM d').format(points.last.date),
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
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
// Stock Logo Widget
// ─────────────────────────────────────────────────────────────────────────────

class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const StockLogo({super.key, required this.symbol, this.size = 44});

  /// Strip exchange suffixes: BTC-USD → BTC, AIR.PA → AIR
  String get _clean =>
      symbol.toUpperCase().split('-').first.split('.').first;

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
                        if (holding.title != null && holding.title!.isNotEmpty) ...[
                          Text(
                            holding.title!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            holding.symbol.toUpperCase(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ] else ...[
                          Text(holding.symbol.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${holding.shares} ${holding.symbol.contains('-') ? 'units' : 'shares'}',
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  _StatCol(label: 'Avg Cost', value: '\$${holding.costBasis.toStringAsFixed(2)}'),
                  _StatCol(label: 'Live Price', value: '\$${holding.currentPrice.toStringAsFixed(2)}'),
                  _StatCol(
                    label: 'Gain/Loss',
                    value: '${isGain ? '+' : ''}\$${holding.gainLoss.toStringAsFixed(2)}',
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
                  icon: const Icon(Icons.sell_outlined, size: 16),
                  label: const Text('Sell'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
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
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

  const AddHoldingModal({super.key, this.holding, required this.onSave});

  @override
  State<AddHoldingModal> createState() => _AddHoldingModalState();
}

class _AddHoldingModalState extends State<AddHoldingModal> {
  final _symbolCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _sharesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double? _livePrice;
  String? _companyName;
  bool _fetching = false;
  String? _fetchError;
  Timer? _debounce;

  List<StockSearchResult> _searchResults = [];
  bool _searching = false;
  Timer? _searchDebounce;

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
    _searchDebounce = Timer(const Duration(milliseconds: 400), _searchCompanies);
    _debounce = Timer(const Duration(milliseconds: 900), _fetchPrice);
  }

  Future<void> _searchCompanies() async {
    final query = _symbolCtrl.text.trim();
    if (query.length < 2) return;
    setState(() => _searching = true);
    final results = await StockPriceService.searchSymbols(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
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
      setState(() {
        _fetchError =
            'Could not find "$sym". Try searching by name above, or use formats: AAPL, ATW.CS, AIR.PA, BTC-USD, EURUSD=X';
        _fetching = false;
      });
    }
  }

  void _save() {
    final sym = _symbolCtrl.text.trim().toUpperCase();
    if (sym.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a symbol')));
      return;
    }
    final shares = double.tryParse(_sharesCtrl.text) ?? 0;
    if (shares <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid number of shares')));
      return;
    }
    final costBasis = double.tryParse(_costCtrl.text) ?? 0;
    final currentPrice = _livePrice ?? 0;

    widget.onSave(Holding(
      id: widget.holding?.id ?? const Uuid().v4(),
      symbol: sym,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      shares: shares,
      costBasis: costBasis,
      currentPrice: currentPrice,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.holding == null ? 'Add Holding' : 'Edit Holding',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),

              // Symbol + Fetch button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _symbolCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Ticker Symbol',
                        hintText: 'AAPL · ATW.CS · AIR.PA · BTC-USD · IAM.CS',
                        helperText: 'Type ticker or company name — any exchange worldwide',
                        helperMaxLines: 1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.show_chart),
                        suffixIcon: _fetching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _fetchPrice(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: Tooltip(
                      message: 'Refresh price',
                      child: ElevatedButton(
                        onPressed: _fetching ? null : _fetchPrice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(52, 56),
                        ),
                        child: const Icon(Icons.refresh, size: 22),
                      ),
                    ),
                  ),
                ],
              ),

              // Company search results
              if (_searching) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ] else if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: _searchResults.map((r) {
                      final typeIcon = r.type == 'CRYPTOCURRENCY'
                          ? Icons.currency_bitcoin
                          : r.type == 'ETF'
                              ? Icons.pie_chart_outline
                              : r.type == 'CURRENCY'
                                  ? Icons.currency_exchange
                                  : Icons.show_chart;
                      return InkWell(
                        onTap: () => _selectResult(r),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(typeIcon, size: 18, color: AppTheme.goldPrimary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${r.symbol}  ·  ${r.exchange}', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Live price result
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
                      Icon(Icons.check_circle_outline,
                          color: AppTheme.success, size: 18),
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
                              'Live price: \$${_livePrice!.toStringAsFixed(2)}',
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
                      Icon(Icons.error_outline, color: AppTheme.error, size: 18),
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

              // Title (optional custom name)
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'e.g., Apple Stock, Bitcoin Investment',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // Shares
              TextField(
                controller: _sharesCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity (shares / units)',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),

              // Avg cost
              TextField(
                controller: _costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Avg Buy Price per Unit',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., Long-term hold, Roth IRA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.holding == null ? 'Add Holding' : 'Save Changes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sell Holding Modal
// ─────────────────────────────────────────────────────────────────────────────

class SellHoldingModal extends StatefulWidget {
  final Holding holding;
  final List<Account> accounts;
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
    required this.onSell,
  });

  @override
  State<SellHoldingModal> createState() => _SellHoldingModalState();
}

class _SellHoldingModalState extends State<SellHoldingModal> {
  final _sharesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current live price
    if (widget.holding.currentPrice > 0) {
      _priceCtrl.text = widget.holding.currentPrice.toStringAsFixed(2);
    }
    // Default to first bank/savings account
    final bankAccounts = widget.accounts
        .where((a) => a.type == 'bank' || a.type == 'savings')
        .toList();
    if (bankAccounts.isNotEmpty) _selectedAccountId = bankAccounts.first.id;
  }

  @override
  void dispose() {
    _sharesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _sharesToSell => double.tryParse(_sharesCtrl.text) ?? 0;
  double get _sellPrice => double.tryParse(_priceCtrl.text) ?? 0;
  double get _proceeds => _sharesToSell * _sellPrice;
  double get _profitLoss =>
      _sharesToSell * (_sellPrice - widget.holding.costBasis);

  void _confirm() {
    if (_sharesToSell <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the number of shares to sell')));
      return;
    }
    if (_sharesToSell > widget.holding.shares) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'You only hold ${widget.holding.shares} shares')));
      return;
    }
    if (_sellPrice <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a sell price')));
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a destination account')));
      return;
    }
    widget.onSell(
      sharesToSell: _sharesToSell,
      sellPrice: _sellPrice,
      accountId: _selectedAccountId!,
      transactionId: const Uuid().v4(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = _profitLoss >= 0;
    final profitColor = isProfit ? AppTheme.success : AppTheme.error;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  StockLogo(symbol: widget.holding.symbol, size: 44),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sell ${widget.holding.symbol}',
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        '${widget.holding.shares} shares available',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Shares to sell
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sharesCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Shares to sell',
                        hintText: 'Max ${widget.holding.shares}',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.numbers),
                        suffixText: '/ ${widget.holding.shares}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _sharesCtrl.text =
                            widget.holding.shares.toString();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.error.withValues(alpha: 0.12),
                        foregroundColor: AppTheme.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('All',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sell price
              TextField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Sell price per share',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                  helperText: widget.holding.currentPrice > 0
                      ? 'Live: \$${widget.holding.currentPrice.toStringAsFixed(2)}'
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Destination account
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: 'Proceeds go to',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance),
                ),
                items: widget.accounts
                    .where((a) => a.type != 'investment')
                    .map((a) => DropdownMenuItem<String>(
                          value: a.id,
                          child: Text('${a.name} · \$${a.balance.toStringAsFixed(0)}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: 20),

              // Summary box
              if (_sharesToSell > 0 && _sellPrice > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Total proceeds',
                        value: '\$${_proceeds.toStringAsFixed(2)}',
                        valueStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Cost basis (${_sharesToSell} shares)',
                        value:
                            '\$${(_sharesToSell * widget.holding.costBasis).toStringAsFixed(2)}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: isProfit ? 'Profit' : 'Loss',
                        value:
                            '${isProfit ? '+' : ''}\$${_profitLoss.toStringAsFixed(2)}',
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: profitColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _sharesToSell > 0 && _sellPrice > 0
                        ? 'Sell for \$${_proceeds.toStringAsFixed(2)}'
                        : 'Confirm Sale',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value,
            style: valueStyle ??
                const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

