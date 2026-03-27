import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

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

    double minY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.isEmpty ? 100 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final pad = range * 0.18;
    minY = (minY - pad).clamp(0.0, double.infinity);
    maxY = maxY + pad;

    final labelColor = isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
          // ── Header ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: labelColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cf.format(totalValue),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Period selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: periods.map((p) {
                    final active = selectedPeriod == p;
                    return GestureDetector(
                      onTap: () => onPeriodChanged(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: active ? lineColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : labelColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Chart ───────────────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(child: Text('No data available', style: Theme.of(context).textTheme.bodySmall))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: minY,
                      maxY: maxY,
                      // ── Axes ──────────────────────────────────────────
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: spots.length > 1 ? (spots.length - 1) / 3 : 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                              final totalDur = chartEnd.difference(chartStart);
                              final pointDate = chartStart.add(totalDur * (idx / (spots.length - 1).clamp(1, double.infinity)));
                              final label = formatXAxis != null
                                  ? formatXAxis!(pointDate)
                                  : _formatDate(pointDate, selectedPeriod);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
                              );
                            },
                          ),
                        ),
                      ),
                      // ── Crosshair touch ───────────────────────────────
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((i) {
                          return TouchedSpotIndicatorData(
                            FlLine(color: lineColor.withOpacity(0.5), strokeWidth: 1.5, dashArray: [4, 4]),
                            FlDotData(
                              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                radius: 5,
                                color: lineColor,
                                strokeWidth: 2.5,
                                strokeColor: isDark ? AppTheme.darkSurface : Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => isDark ? AppTheme.darkSurfaceElevated : const Color(0xFF1C1C1E),
                          tooltipRoundedRadius: 10,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                            cf.format(s.y),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          )).toList(),
                        ),
                      ),
                      // ── Line ──────────────────────────────────────────
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.42,
                          color: lineColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          shadow: Shadow(color: lineColor.withOpacity(0.4), blurRadius: 10),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.75],
                              colors: [lineColor.withOpacity(0.28), lineColor.withOpacity(0.0)],
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

  String _formatDate(DateTime date, String period) {
    switch (period) {
      case '1D': return DateFormat('HH:mm').format(date);
      case '1W':
      case '1M': return DateFormat('d MMM').format(date);
      default:   return DateFormat('MMM').format(date);
    }
  }
}
