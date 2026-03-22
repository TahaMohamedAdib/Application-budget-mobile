import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/currency_helper.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/add_transaction_modal.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'all';
  String _sortBy = 'newest';
  bool _showFilters = false;
  String _chartTimeframe = '1w';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Filter and sort transactions
        var filteredTransactions = provider.transactions.where((t) {
          // Filter by type
          if (_filterType != 'all' && t.type != _filterType) return false;
          
          // Filter by search query
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            final note = (t.note ?? '').toLowerCase();
            final amount = t.amount.toString();
            if (!note.contains(query) && !amount.contains(query)) return false;
          }
          
          return true;
        }).toList();

        // Sort transactions
        filteredTransactions.sort((a, b) {
          switch (_sortBy) {
            case 'newest':
              return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
            case 'oldest':
              return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
            case 'highest':
              return b.amount.compareTo(a.amount);
            case 'lowest':
              return a.amount.compareTo(b.amount);
            default:
              return 0;
          }
        });

        // Calculate totals
        final totalExpenses = filteredTransactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalIncome = filteredTransactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);

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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                shape: BoxShape.circle,
                                boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : AppTheme.cardShadowLight,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Transactions',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Search transactions...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _showFilters
                                    ? AppTheme.goldPrimary.withOpacity(0.2)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _showFilters
                                      ? AppTheme.goldPrimary
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.filter_list,
                                  color: _showFilters
                                      ? AppTheme.goldPrimary
                                      : Theme.of(context).iconTheme.color,
                                ),
                                onPressed: () => setState(() => _showFilters = !_showFilters),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        
                        // Filters
                        if (_showFilters) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Type',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _filterType,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'all', child: Text('All')),
                                        DropdownMenuItem(value: 'expense', child: Text('Expenses')),
                                        DropdownMenuItem(value: 'income', child: Text('Income')),
                                        DropdownMenuItem(value: 'transfer', child: Text('Transfers')),
                                        DropdownMenuItem(value: 'withdrawal', child: Text('Withdrawals')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _filterType = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sort By',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _sortBy,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                                        DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                                        DropdownMenuItem(value: 'highest', child: Text('Highest')),
                                        DropdownMenuItem(value: 'lowest', child: Text('Lowest')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _sortBy = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Spending Chart
                  _buildSpendingChart(context, provider),


                  // Transactions List
                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty || _filterType != 'all'
                                      ? 'No transactions found'
                                      : 'No transactions yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty || _filterType != 'all'
                                      ? 'Try adjusting your filters'
                                      : 'Tap the + button to add your first transaction',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            children: _buildTransactionGroups(filteredTransactions, provider, context),
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

  Widget _buildSpendingChart(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final now = DateTime.now();

    // Determine chart color and label based on filter
    Color lineColor;
    String chartLabel;
    switch (_filterType) {
      case 'expense': lineColor = AppTheme.error; chartLabel = 'Expenses'; break;
      case 'income': lineColor = AppTheme.success; chartLabel = 'Income'; break;
      case 'transfer': lineColor = AppTheme.info; chartLabel = 'Transfers'; break;
      case 'withdrawal': lineColor = AppTheme.warning; chartLabel = 'Withdrawals'; break;
      default: lineColor = AppTheme.goldPrimary; chartLabel = 'Spending'; break;
    }

    // Timeframe config
    late DateTime chartStart;
    late int numPoints;
    switch (_chartTimeframe) {
      case '1d': chartStart = now.subtract(const Duration(hours: 24)); numPoints = 24; break;
      case '1w': chartStart = now.subtract(const Duration(days: 7)); numPoints = 7; break;
      case '1m': chartStart = now.subtract(const Duration(days: 30)); numPoints = 30; break;
      case '6m': chartStart = now.subtract(const Duration(days: 180)); numPoints = 26; break;
      case '1y': chartStart = now.subtract(const Duration(days: 365)); numPoints = 12; break;
      default: chartStart = now.subtract(const Duration(days: 7)); numPoints = 7;
    }

    final totalDuration = now.difference(chartStart);
    final intervalMs = totalDuration.inMilliseconds / (numPoints - 1);

    // Filter matching transactions
    bool matchesFilter(Transaction t) {
      if (_filterType == 'all') return t.type == 'expense' || t.type == 'income';
      return t.type == _filterType;
    }

    // Build cumulative spending per point
    final relevantTxns = provider.transactions.where((t) {
      if (!matchesFilter(t)) return false;
      final d = DateTime.parse(t.date);
      return d.isAfter(chartStart.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    double cumulative = 0;
    int txnIdx = 0;
    for (int i = 0; i < numPoints; i++) {
      final pointTime = chartStart.add(Duration(milliseconds: (intervalMs * i).round()));
      while (txnIdx < relevantTxns.length && DateTime.parse(relevantTxns[txnIdx].date).isBefore(pointTime.add(const Duration(seconds: 1)))) {
        cumulative += relevantTxns[txnIdx].amount;
        txnIdx++;
      }
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    final totalAmount = cumulative;

    if (spots.length < 2) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.premiumCard(context),
          child: Column(
            children: [
              _buildChartHeader(context, chartLabel, cf, totalAmount, isDark),
              const SizedBox(height: 20),
              SizedBox(height: 180, child: Center(child: Text('Not enough data', style: Theme.of(context).textTheme.bodySmall))),
            ],
          ),
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final yPadding = range == 0 ? 100.0 : range * 0.15;

    String formatYLabel(double v) {
      if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCard(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(context, chartLabel, cf, totalAmount, isDark),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range == 0 ? 100 : range / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: minY + (range == 0 ? 100 : range * 0.30),
                        color: const Color(0xFFBA7517),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 6, bottom: 4),
                          style: const TextStyle(fontSize: 10, color: Color(0xFFBA7517), fontWeight: FontWeight.w600),
                          labelResolver: (_) => 'Seuil ${cf.format(minY + (range == 0 ? 100 : range * 0.30))}',
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
                        interval: _chartTimeframe == '1d' ? 6 : (_chartTimeframe == '1w' ? 2 : (_chartTimeframe == '1m' ? 7 : (_chartTimeframe == '6m' ? 6 : 3))),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= numPoints) return const SizedBox.shrink();
                          final pointTime = chartStart.add(Duration(milliseconds: (intervalMs * idx).round()));
                          String label;
                          if (_chartTimeframe == '1d') {
                            label = DateFormat('HH:mm').format(pointTime);
                          } else if (_chartTimeframe == '1w' || _chartTimeframe == '1m') {
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
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E2A38),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) =>
                        LineTooltipItem(cf.format(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ).toList(),
                    ),
                  ),
                  minY: (minY - yPadding).clamp(0.0, double.infinity),
                  maxY: maxY + yPadding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.45,
                      color: lineColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chartLegendDot(lineColor, chartLabel),
                const SizedBox(width: 16),
                _chartLegendDot(const Color(0xFFBA7517), 'Seuil'),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildChartHeader(BuildContext context, String label, NumberFormat cf, double total, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(cf.format(total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        Row(
          children: ['1d', '1w', '1m', '6m', '1y'].map((tf) {
            final isActive = _chartTimeframe == tf;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _chartTimeframe = tf),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      ],
    );
  }

  Widget _chartLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
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

  List<Widget> _buildTransactionGroups(List transactions, AppProvider provider, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = CurrencyHelper.formatter(provider.settings.currency);

    final groups = <String, List>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(t.date));
      groups.putIfAbsent(key, () => []).add(t);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      final items = entry.value;
      final date = DateTime.parse(entry.key);
      widgets.add(
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
      );
      widgets.add(
        Container(
          decoration: AppTheme.premiumCard(context),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final t = e.value;
              final tColor = _getTransactionColor(t.type);
              final date = DateTime.parse(t.date);

              // Look up category
              final cat = t.categoryId != null
                  ? provider.categories.where((c) => c.id == t.categoryId).firstOrNull
                  : null;

              return Column(
                children: [
                  Slidable(
                    key: Key(t.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.22,
                      children: [
                        CustomSlidableAction(
                          onPressed: (_) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Delete Transaction?'),
                                content: Text('Delete "${t.note ?? _getTransactionTypeLabel(t.type)}"? This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                            if (confirmed) provider.deleteTransaction(t.id);
                          },
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => _showTransactionDetail(context, t, provider, cf, isDark),
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
                                  : Icon(_getTransactionDisplayIcon(t.type, t.note), color: tColor, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          t.note ?? cat?.name ?? _getTransactionTypeLabel(t.type),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (t.expenseSubType != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (t.expenseSubType == 'subscription' ? AppTheme.info : AppTheme.warning).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            t.expenseSubType == 'subscription' ? 'Sub' : 'Bill',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: t.expenseSubType == 'subscription' ? AppTheme.info : AppTheme.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('h:mm a').format(date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              cf.format(t.amount),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, indent: 70, color: Theme.of(context).dividerColor),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
    return widgets;
  }

  void _showTransactionDetail(BuildContext context, Transaction t, AppProvider provider, NumberFormat cf, bool isDark) {
    final cat = t.categoryId != null
        ? provider.categories.where((c) => c.id == t.categoryId).firstOrNull
        : null;
    final account = provider.accounts.where((a) => a.id == t.accountId).firstOrNull;
    final tColor = _getTransactionColor(t.type);
    final date = DateTime.parse(t.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon + title + amount
                Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: tColor.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                      child: cat != null
                          ? _buildCategoryIcon(cat.icon, tColor)
                          : Icon(_getTransactionDisplayIcon(t.type, t.note), color: tColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.note ?? cat?.name ?? t.type,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, yyyy · h:mm a').format(date),
                            style: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${t.type == 'income' ? '+' : '-'}${cf.format(t.amount)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Info rows
                if (account != null) _detailInfoRow(ctx, Icons.account_balance_rounded, 'Account', account.name),
                if (cat != null) _detailInfoRow(ctx, Icons.category_rounded, 'Category', cat.name),
                if (t.expenseSubType != null) _detailInfoRow(ctx, Icons.label_rounded, 'Type', t.expenseSubType![0].toUpperCase() + t.expenseSubType!.substring(1)),
                if (t.isRecurring) _detailInfoRow(ctx, Icons.repeat_rounded, 'Recurring', 'Yes'),
                const SizedBox(height: 8),
                // Receipt image
                if (t.imagePath != null) ...[
                  Text('Receipt', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: ctx,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: t.imagePath!.startsWith('http')
                              ? Image.network(t.imagePath!, fit: BoxFit.contain)
                              : Image.file(File(t.imagePath!), fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: t.imagePath!.startsWith('http')
                          ? Image.network(t.imagePath!, width: double.infinity, height: 180, fit: BoxFit.cover)
                          : Image.file(File(t.imagePath!), width: double.infinity, height: 180, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 180, color: Colors.grey.withOpacity(0.1),
                                child: const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
                              )),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Edit button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddTransactionModal(initialTransaction: t),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Transaction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8860B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
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

  Widget _detailInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text('$label  ', style: Theme.of(context).textTheme.bodySmall),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
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
    return Icon(_categoryIcon(iconStr), color: color, size: 18);
  }

  IconData _categoryIcon(String iconName) {
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

  IconData _getTransactionDisplayIcon(String type, String? note) {
    if (type == 'income') {
      final n = note?.toLowerCase() ?? '';
      if (n.contains('salary') || n.contains('salaire') || n.contains('paycheck') || n.contains('wage')) {
        return Icons.paid_rounded;
      }
    }
    return _getTransactionIcon(type);
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.arrow_downward;
      case 'income':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'withdrawal':
        return Icons.payments;
      case 'goal_contribution':
        return Icons.savings_rounded;
      case 'debt_payment':
        return Icons.credit_card_rounded;
      default:
        return Icons.receipt;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'expense':
        return AppTheme.error;
      case 'income':
        return AppTheme.success;
      case 'transfer':
        return AppTheme.info;
      case 'withdrawal':
        return AppTheme.warning;
      case 'goal_contribution':
        return AppTheme.goldPrimary;
      case 'debt_payment':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return 'Expense';
      case 'income':
        return 'Income';
      case 'transfer':
        return 'Transfer';
      case 'withdrawal':
        return 'Withdrawal';
      case 'goal_contribution':
        return 'Goal Savings';
      case 'debt_payment':
        return 'Debt Payment';
      default:
        return 'Transaction';
    }
  }
}
