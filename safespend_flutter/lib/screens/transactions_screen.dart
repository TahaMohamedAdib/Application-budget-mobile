import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/currency_helper.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';

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
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20),
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
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = filteredTransactions[index];
                              final date = DateTime.parse(transaction.date);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getTransactionColor(transaction.type).withOpacity(0.2),
                                    child: Icon(
                                      _getTransactionIcon(transaction.type),
                                      color: _getTransactionColor(transaction.type),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    transaction.note ?? _getTransactionTypeLabel(transaction.type),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    DateFormat('MMM d, yyyy • h:mm a').format(date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: Text(
                                    '\$${transaction.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getTransactionColor(transaction.type),
                                    ),
                                  ),
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
              SizedBox(height: 160, child: Center(child: Text('Not enough data', style: Theme.of(context).textTheme.bodySmall))),
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
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: LineChart(
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
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        return LineTooltipItem(cf.format(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12));
                      }).toList(),
                    ),
                  ),
                  minY: minY - yPadding,
                  maxY: maxY + yPadding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: lineColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            return GestureDetector(
              onTap: () => setState(() => _chartTimeframe = tf),
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
    );
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
        return Colors.red;
      case 'income':
        return AppTheme.gold500;
      case 'transfer':
        return Colors.blue;
      case 'withdrawal':
        return Colors.amber;
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
