import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Modern chart widget matching ChatGPT-style UI
/// Features: smooth curves, subtle gradients, time period filters, dark theme optimized
class ModernChart extends StatelessWidget {
  final String title;
  final double totalValue;
  final String currency;
  final List<FlSpot> spots;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final List<String> periods;
  final Color lineColor;
  final DateTime chartStart;
  final DateTime chartEnd;
  final String Function(double)? formatYAxis;
  final String Function(DateTime)? formatXAxis;

  const ModernChart({
    super.key,
    required this.title,
    required this.totalValue,
    required this.currency,
    required this.spots,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.periods = const ['1D', '1W', '1M', '6M', '1Y'],
    required this.lineColor,
    required this.chartStart,
    required this.chartEnd,
    this.formatYAxis,
    this.formatXAxis,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    // Calculate Y-axis bounds
    double minY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.isEmpty ? 100 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.15;
    minY = (minY - padding).clamp(0.0, double.infinity);
    maxY = maxY + padding;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title, value, and period filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and value
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cf.format(totalValue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              ),
              // Period filters
              Row(
                children: periods.map((period) {
                  final isActive = selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => onPeriodChanged(period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFF0F0F0))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                                : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: (maxY - minY) / 4,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.min || value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              final formatted = formatYAxis != null
                                  ? formatYAxis!(value)
                                  : _formatCompact(value);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  formatted,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.darkTextTertiary
                                        : AppTheme.lightTextTertiary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: spots.length > 1 ? (spots.length - 1) / 3 : 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= spots.length) {
                                return const SizedBox.shrink();
                              }
                              
                              // Calculate date for this spot
                              final totalDuration = chartEnd.difference(chartStart);
                              final pointDuration = totalDuration * (idx / (spots.length - 1).clamp(1, double.infinity));
                              final pointDate = chartStart.add(pointDuration);
                              
                              final formatted = formatXAxis != null
                                  ? formatXAxis!(pointDate)
                                  : _formatDate(pointDate, selectedPeriod);
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  formatted,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.darkTextTertiary
                                        : AppTheme.lightTextTertiary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => isDark
                              ? AppTheme.darkSurfaceElevated
                              : const Color(0xFF2D2D2D),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                            return LineTooltipItem(
                              cf.format(s.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.4,
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
                                lineColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatDate(DateTime date, String period) {
    switch (period) {
      case '1D':
        return DateFormat('HH:mm').format(date);
      case '1W':
      case '1M':
        return DateFormat('d MMM').format(date);
      case '6M':
      case '1Y':
        return DateFormat('MMM').format(date);
      default:
        return DateFormat('d MMM').format(date);
    }
  }
}
