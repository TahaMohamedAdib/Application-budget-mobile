import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// ─── Constants ──────────────────────────────────────────────────────────────

const _kGreen = Color(0xFF1D9E75);
const _kRed = Color(0xFFE24B4A);
const _kBlue = Color(0xFF185FA5);
const _kAmber = Color(0xFFBA7517);
const _kSafeThreshold = 1500.0;
const _kStartBalance = 2800.0;

final _fmt = NumberFormat('#,##0', 'fr_FR');
String _fmtMAD(double v) => '${_fmt.format(v)} MAD';

// ─── Periods ────────────────────────────────────────────────────────────────

enum _Period { d7, d30, m3, y1 }

extension _PeriodX on _Period {
  String get label {
    switch (this) {
      case _Period.d7:
        return '7j';
      case _Period.d30:
        return '30j';
      case _Period.m3:
        return '3 mois';
      case _Period.y1:
        return '1 an';
    }
  }

  int get days {
    switch (this) {
      case _Period.d7:
        return 7;
      case _Period.d30:
        return 30;
      case _Period.m3:
        return 90;
      case _Period.y1:
        return 365;
    }
  }
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

class BalanceChart extends StatefulWidget {
  const BalanceChart({super.key});

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  _Period _period = _Period.d30;
  late List<FlSpot> _spots;
  late Set<int> _spikeIndices;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  // ── Data generation ────────────────────────────────────────────────────────

  void _regenerate() {
    final result = _generateSpots(_period.days);
    _spots = result.$1;
    _spikeIndices = result.$2;
  }

  /// Returns (spots, spikeIndices).
  (List<FlSpot>, Set<int>) _generateSpots(int days) {
    final spots = <FlSpot>[];
    final spikes = <int>{};

    // Spread ~3-4 spikes evenly across the range
    final spikeCount = 3 + _rng.nextInt(2); // 3 or 4
    final spikePositions = <int>{};
    while (spikePositions.length < spikeCount) {
      // avoid first and last index
      spikePositions.add(1 + _rng.nextInt(days - 2));
    }

    double balance = _kStartBalance;
    for (int i = 0; i < days; i++) {
      if (spikePositions.contains(i)) {
        // income spike: +800 to +2200 MAD
        balance += 800 + _rng.nextDouble() * 1400;
        spikes.add(i);
      } else {
        // daily drift: -80 to +30 MAD
        balance += -80 + _rng.nextDouble() * 110;
      }
      // clamp to realistic range
      balance = balance.clamp(800.0, 5000.0);
      spots.add(FlSpot(i.toDouble(), balance));
    }
    return (spots, spikes);
  }

  // ── Derived metrics ────────────────────────────────────────────────────────

  double get _currentBalance => _spots.last.y;

  double get _totalExpenses {
    // sum of negative deltas
    double total = 0;
    for (int i = 1; i < _spots.length; i++) {
      final delta = _spots[i].y - _spots[i - 1].y;
      if (delta < 0) total += delta.abs();
    }
    return total;
  }

  double get _netSavings => _currentBalance - _kStartBalance;

  // ── X-axis label ───────────────────────────────────────────────────────────

  String _xLabel(double value, int days) {
    final i = value.toInt();
    final now = DateTime.now();

    switch (_period) {
      case _Period.d7:
        final day = now.subtract(Duration(days: days - 1 - i));
        // short weekday in French
        const weekdays = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];
        return weekdays[(day.weekday - 1) % 7];

      case _Period.d30:
        if (i % 7 != 0) return '';
        final day = now.subtract(Duration(days: days - 1 - i));
        final month = DateFormat('MMM', 'fr_FR').format(day);
        return '${day.day} $month';

      case _Period.m3:
        if (i % 30 != 0) return '';
        final day = now.subtract(Duration(days: days - 1 - i));
        return DateFormat('MMM', 'fr_FR').format(day);

      case _Period.y1:
        if (i % 30 != 0) return '';
        final day = now.subtract(Duration(days: days - 1 - i));
        return DateFormat("MMM ''yy", 'fr_FR').format(day);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricRow(
          balance: _currentBalance,
          expenses: _totalExpenses,
          savings: _netSavings,
        ),
        const SizedBox(height: 16),
        _PeriodSelector(
          selected: _period,
          onSelect: (p) => setState(() {
            _period = p;
            _regenerate();
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _buildChart(),
        ),
        const SizedBox(height: 12),
        const _Legend(),
      ],
    );
  }

  Widget _buildChart() {
    final days = _period.days;

    // Split spots into two datasets: above threshold (green) and below (red)
    final greenSpots = <FlSpot>[];
    final redSpots = <FlSpot>[];

    for (final s in _spots) {
      if (s.y >= _kSafeThreshold) {
        greenSpots.add(s);
        // bridge point so the two lines meet seamlessly
        if (redSpots.isNotEmpty) redSpots.add(s);
      } else {
        redSpots.add(s);
        if (greenSpots.isNotEmpty) greenSpots.add(s);
      }
    }

    // Spike dot data helper
    FlDotData _dotData(Color dotColor) => FlDotData(
          show: true,
          getDotPainter: (spot, _, __, index) {
            final originalIndex = _spots.indexWhere(
              (s) => s.x == spot.x && s.y == spot.y,
            );
            if (_spikeIndices.contains(originalIndex)) {
              return FlDotCirclePainter(
                radius: 5,
                color: _kRed,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            }
            return FlDotCirclePainter(radius: 0, color: Colors.transparent);
          },
        );

    LineChartBarData _barData(
      List<FlSpot> spots,
      Color lineColor,
      Color gradientTop,
    ) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.45,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: _dotData(lineColor),
          shadow: Shadow(color: lineColor.withOpacity(0.45), blurRadius: 10),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.75],
              colors: [gradientTop.withOpacity(0.30), gradientTop.withOpacity(0.0)],
            ),
          ),
        );

    final lineBars = <LineChartBarData>[];
    if (greenSpots.isNotEmpty) {
      lineBars.add(_barData(greenSpots, _kGreen, _kGreen));
    }
    if (redSpots.isNotEmpty) {
      lineBars.add(_barData(redSpots, _kRed, _kRed));
    }

    final minY = (_spots.map((s) => s.y).reduce(min) - 200).clamp(0.0, 800.0);
    final maxY = _spots.map((s) => s.y).reduce(max) + 300;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (days - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        // ── Grid ──────────────────────────────────────────────────────────
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        // ── Axes ──────────────────────────────────────────────────────────
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final label = _xLabel(value, days);
                if (label.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                  ),
                );
              },
            ),
          ),
        ),
        // ── Dashed threshold line ─────────────────────────────────────────
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _kSafeThreshold,
              color: _kAmber,
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 4),
                style: const TextStyle(
                  fontSize: 10,
                  color: _kAmber,
                  fontWeight: FontWeight.w600,
                ),
                labelResolver: (_) => 'Seuil ${_fmtMAD(_kSafeThreshold)}',
              ),
            ),
          ],
        ),
        // ── Tooltip + Crosshair ───────────────────────────────────────────
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((i) {
            return TouchedSpotIndicatorData(
              FlLine(color: barData.color?.withOpacity(0.5) ?? _kGreen.withOpacity(0.5),
                strokeWidth: 1.5, dashArray: [4, 4]),
              FlDotData(
                getDotPainter: (_, __, bar, ___) => FlDotCirclePainter(
                  radius: 5,
                  color: bar.color ?? _kGreen,
                  strokeWidth: 2.5,
                  strokeColor: Colors.white,
                ),
              ),
            );
          }).toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1C1C1E),
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem(
              _fmtMAD(s.y),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            )).toList(),
          ),
        ),
        lineBarsData: lineBars,
      ),
    );
  }
}

// ─── Metric Row ──────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.balance,
    required this.expenses,
    required this.savings,
  });

  final double balance;
  final double expenses;
  final double savings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricCard(label: 'Balance actuelle', value: _fmtMAD(balance), valueColor: _kGreen),
        const SizedBox(width: 8),
        _MetricCard(label: 'Dépenses / mois', value: _fmtMAD(expenses), valueColor: _kRed),
        const SizedBox(width: 8),
        _MetricCard(
          label: 'Épargne nette',
          value: (savings >= 0 ? '+' : '') + _fmtMAD(savings),
          valueColor: _kGreen,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF888888)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period Selector ─────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelect});

  final _Period selected;
  final ValueChanged<_Period> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Period.values.map((p) {
        final active = p == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _kGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _kGreen : const Color(0xFFCCCCCC),
                ),
              ),
              child: Text(
                p.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(0xFF888888),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendDot(color: _kGreen, label: 'Balance'),
        SizedBox(width: 16),
        _LegendDot(color: _kRed, label: 'Revenu entrant'),
        SizedBox(width: 16),
        _LegendDot(color: _kAmber, label: 'Seuil safe'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}
