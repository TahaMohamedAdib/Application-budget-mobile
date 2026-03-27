import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  String _range = 'week'; // week, month

  List<double> _getWeeklySpending(AppProvider provider) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final spending = List.filled(7, 0.0);
    for (final t in provider.transactions) {
      if (t.type == 'expense') {
        final date = DateTime.parse(t.date);
        final diff = date.difference(DateTime(monday.year, monday.month, monday.day)).inDays;
        if (diff >= 0 && diff < 7) {
          spending[diff] += t.amount;
        }
      }
    }
    return spending;
  }

  List<double> _getMonthlySpending(AppProvider provider) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Group into ~4 weeks
    final weeks = List.filled(5, 0.0);
    for (final t in provider.transactions) {
      if (t.type == 'expense') {
        final date = DateTime.parse(t.date);
        if (date.year == now.year && date.month == now.month) {
          final weekIdx = ((date.day - 1) / 7).floor().clamp(0, 4);
          weeks[weekIdx] += t.amount;
        }
      }
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);

        final weeklySpending = _getWeeklySpending(provider);
        final monthlySpending = _getMonthlySpending(provider);
        final isWeek = _range == 'week';
        final data = isWeek ? weeklySpending : monthlySpending;
        final totalSpending = data.fold(0.0, (a, b) => a + b);
        final labels = isWeek
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5'];

        // Recent expense transactions
        final expenseTransactions = provider.transactions
            .where((t) => t.type == 'expense')
            .toList()
          ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

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
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Spending', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // Range Toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: ['week', 'month'].map((r) {
                          final active = _range == r;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _range = r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? AppTheme.goldPrimary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Text(
                                    r == 'week' ? 'This Week' : 'This Month',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                ),

                // Total + Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.goldCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Spending',
                            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2)),
                          const SizedBox(height: 4),
                          Text(cf.format(totalSpending),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1.0)),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: data.reduce((a, b) => a > b ? a : b).clamp(10, double.infinity) * 1.35,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => const Color(0xFF1C1C1E),
                                    tooltipRoundedRadius: 10,
                                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(cf.format(rod.toY),
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13));
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= labels.length) return const SizedBox();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(labels[idx],
                                            style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: data.asMap().entries.map((entry) {
                                  final isHighlight = isWeek
                                      ? entry.key == DateTime.now().weekday - 1
                                      : entry.key == ((DateTime.now().day - 1) / 7).floor().clamp(0, 4);
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value > 0 ? entry.value : 0,
                                        gradient: isHighlight
                                            ? LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  AppTheme.success,
                                                  AppTheme.success.withOpacity(0.6),
                                                ],
                                              )
                                            : LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.white.withOpacity(0.22),
                                                  Colors.white.withOpacity(0.06),
                                                ],
                                              ),
                                        width: isWeek ? 26 : 36,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: data.reduce((a, b) => a > b ? a : b).clamp(10, double.infinity) * 1.35,
                                          color: Colors.white.withOpacity(0.04),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ),

                // Recent Expenses Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text('Recent Expenses', style: Theme.of(context).textTheme.titleLarge),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                ),

                // Recent Expenses List
                expenseTransactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: AppTheme.premiumCard(context),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 72, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text('No expenses yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                              children: expenseTransactions.take(15).toList().asMap().entries.map((entry) {
                                final t = entry.value;
                                final isLast = entry.key == (expenseTransactions.length > 15 ? 14 : expenseTransactions.length - 1);
                                final cat = t.categoryId != null
                                    ? provider.categories.where((c) => c.id == t.categoryId).firstOrNull
                                    : null;
                                final tDate = DateTime.parse(t.date);
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                                            child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.error, size: 20),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(t.note ?? 'Expense', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  t.description ?? DateFormat('MMM d, yyyy').format(tDate),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('-${cf.format(t.amount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.error)),
                                              if (cat != null) ...[
                                                const SizedBox(height: 3),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.error.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(cat.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.error)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLast) Divider(height: 1, indent: 76, color: Theme.of(context).dividerColor),
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
