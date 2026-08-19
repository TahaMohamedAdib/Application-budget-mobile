import 'dart:math' as math;

import '../models/transaction.dart';

/// One sampled point of the balance history.
class BalancePoint {
  const BalancePoint(this.time, this.balance);

  /// The instant the balance is stated *as of* — the close of the bucket, so
  /// a point labelled "12 Aug" means "where the balance stood at the end of
  /// 12 August", not somewhere inside it.
  final DateTime time;
  final double balance;
}

/// How a timeframe is sampled. Buckets land on real calendar boundaries
/// rather than on an evenly divided millisecond span: the old chart placed
/// its 30 points at `start + n × (duration / 29)`, which drifts a few hours
/// off midnight every step, so a label reading "12 Aug" was really showing
/// the balance partway through the 11th.
enum BalanceBucket { hour, day, week, month }

class BalanceTimeframe {
  const BalanceTimeframe(this.bucket, this.count);

  final BalanceBucket bucket;

  /// Number of buckets *before* the current one; the series always ends on a
  /// point for "now", so it holds [count] + 1 points.
  final int count;

  static const _byKey = <String, BalanceTimeframe>{
    '1d': BalanceTimeframe(BalanceBucket.hour, 24),
    '1w': BalanceTimeframe(BalanceBucket.day, 7),
    '1m': BalanceTimeframe(BalanceBucket.day, 30),
    '6m': BalanceTimeframe(BalanceBucket.week, 26),
    '1y': BalanceTimeframe(BalanceBucket.month, 12),
  };

  static BalanceTimeframe fromKey(String key) =>
      _byKey[key] ?? _byKey['1m']!;
}

/// Reconstructs the balance history for a scope of accounts.
///
/// [scopeAccountId] null means "all accounts combined"; otherwise the history
/// is for that one account.
///
/// Works backwards from the balance we know is right — the current one — and
/// then replays forward, so the final point always equals today's balance
/// exactly instead of accumulating rounding drift.
List<BalancePoint> buildBalanceSeries({
  required List<Transaction> transactions,
  required double currentBalance,
  required String timeframeKey,
  String? scopeAccountId,
  DateTime? now,
}) {
  final end = now ?? DateTime.now();
  final frame = BalanceTimeframe.fromKey(timeframeKey);

  final boundaries = _boundaries(end, frame);
  final start = boundaries.first;

  final relevant = transactions
      .where((t) => _touchesScope(t, scopeAccountId))
      .map((t) => (time: _parseDate(t.date), tx: t))
      .where((e) => e.time != null)
      .map((e) => (time: e.time!, tx: e.tx))
      .where((e) => !e.time.isBefore(start) && !e.time.isAfter(end))
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  // Rewind the known balance to the start of the window.
  var running = currentBalance;
  for (final entry in relevant) {
    running -= _delta(entry.tx, scopeAccountId);
  }

  final points = <BalancePoint>[];
  var index = 0;
  for (final boundary in boundaries) {
    while (index < relevant.length &&
        !relevant[index].time.isAfter(boundary)) {
      running += _delta(relevant[index].tx, scopeAccountId);
      index++;
    }
    points.add(BalancePoint(boundary, running));
  }
  return points;
}

/// Whether a transaction affects the scope at all.
///
/// The previous filter only compared `accountId`, so a transfer *into* the
/// selected account — where the account is the destination, not the source —
/// was dropped before it could be counted. Money arriving simply never
/// appeared on that account's chart.
bool _touchesScope(Transaction t, String? scope) =>
    scope == null || t.accountId == scope || t.toAccountId == scope;

/// Signed effect of [t] on the scope's balance.
double _delta(Transaction t, String? scope) {
  final fromScope = scope == null || t.accountId == scope;
  final intoScope = scope != null && t.toAccountId == scope;

  switch (t.type) {
    case 'transfer':
      // Across all accounts an internal transfer nets to nothing; it only
      // moves the balance when one specific account is in view.
      if (scope == null) return 0;
      if (intoScope) return t.amount;
      if (fromScope) return -t.amount;
      return 0;
    case 'income':
      return fromScope ? t.amount : 0;
    case 'expense':
    case 'withdrawal':
      return fromScope ? -t.amount : 0;
    default:
      return 0;
  }
}

/// Bucket closing instants, oldest first, ending at [end].
List<DateTime> _boundaries(DateTime end, BalanceTimeframe frame) {
  final list = <DateTime>[];
  for (var i = frame.count; i > 0; i--) {
    list.add(switch (frame.bucket) {
      BalanceBucket.hour => DateTime(end.year, end.month, end.day, end.hour - i),
      // End of day, so a point covers the whole calendar day it names.
      BalanceBucket.day =>
        DateTime(end.year, end.month, end.day - i, 23, 59, 59),
      BalanceBucket.week =>
        DateTime(end.year, end.month, end.day - i * 7, 23, 59, 59),
      BalanceBucket.month =>
        DateTime(end.year, end.month - i + 1, 1).subtract(
          const Duration(seconds: 1),
        ),
    });
  }
  list.add(end);
  return list;
}

DateTime? _parseDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  // A bare 'yyyy-MM-dd' parses to midnight, which would sort a day's
  // transactions before the point that is meant to include them.
  return raw.length <= 10
      ? DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 58)
      : parsed;
}

// ── Axis scaling ────────────────────────────────────────────────────────────

/// A rounded axis step near [rawRange] / [targetTicks].
///
/// Gridlines used to be drawn at `range / 4`, which lands on values like
/// 23.7 — technically correct and impossible to read. This snaps to the
/// 1 / 2 / 2.5 / 5 × 10ⁿ series people actually recognise.
double niceStep(double rawRange, int targetTicks) {
  if (rawRange <= 0 || targetTicks <= 0) return 1;
  final rough = rawRange / targetTicks;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final normalized = rough / magnitude;

  final double factor;
  if (normalized <= 1) {
    factor = 1;
  } else if (normalized <= 2) {
    factor = 2;
  } else if (normalized <= 2.5) {
    factor = 2.5;
  } else if (normalized <= 5) {
    factor = 5;
  } else {
    factor = 10;
  }
  return factor * magnitude;
}

/// Axis bounds snapped outward to whole multiples of [step].
({double min, double max, double step}) niceBounds(
  double minValue,
  double maxValue, {
  int targetTicks = 4,
}) {
  // A dead-flat series has no range to divide; give it a band so the line
  // sits in the middle instead of being pinned to an edge.
  if (maxValue - minValue < 1e-9) {
    final centre = maxValue;
    final span = centre.abs() < 1 ? 1.0 : centre.abs() * 0.1;
    final step = niceStep(span * 2, targetTicks);
    return (
      min: (centre - span) - ((centre - span) % step),
      max: (centre + span) + (step - ((centre + span) % step)) % step,
      step: step,
    );
  }

  final step = niceStep(maxValue - minValue, targetTicks);
  final min = (minValue / step).floor() * step;
  final max = (maxValue / step).ceil() * step;
  return (min: min, max: max, step: step);
}

/// Indices of [pointCount] points that should carry an x-axis label.
///
/// Returns at most [maxLabels], always including the first and last, and
/// never two adjacent indices — the old chart used a fixed index interval
/// that left the last tick one step from the edge label, which is why "17
/// Aug" and "18 Aug" printed on top of each other.
List<int> labelIndices(int pointCount, {int maxLabels = 5}) {
  if (pointCount <= 0) return const [];
  if (pointCount == 1) return const [0];
  if (pointCount <= maxLabels) {
    return List<int>.generate(pointCount, (i) => i);
  }

  final last = pointCount - 1;
  final slots = maxLabels - 1;
  final indices = <int>{0};
  for (var i = 1; i < slots; i++) {
    indices.add((last * i / slots).round());
  }
  indices.add(last);

  final sorted = indices.toList()..sort();
  // Drop any label that would sit right next to the final one.
  return [
    for (var i = 0; i < sorted.length; i++)
      if (i == sorted.length - 1 || sorted[i + 1] - sorted[i] > 1) sorted[i],
  ];
}
