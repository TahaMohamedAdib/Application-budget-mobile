import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/models/transaction.dart';
import 'package:safespend_flutter/utils/balance_series.dart';

/// The balance chart is the only place the app makes a claim about the past,
/// so a wrong line is worse than no line — it looks authoritative.

Transaction tx({
  required String type,
  required double amount,
  required String date,
  String accountId = 'A',
  String? toAccountId,
}) =>
    Transaction(
      id: '$type-$date-$amount',
      type: type,
      amount: amount,
      date: date,
      accountId: accountId,
      toAccountId: toAccountId,
    );

final _now = DateTime(2026, 8, 18, 12);

List<BalancePoint> series(
  List<Transaction> txs, {
  double current = 1000,
  String frame = '1m',
  String? scope,
}) =>
    buildBalanceSeries(
      transactions: txs,
      currentBalance: current,
      timeframeKey: frame,
      scopeAccountId: scope,
      now: _now,
    );

void main() {
  group('shape', () {
    test('a month holds 31 points, ending now', () {
      final points = series(const []);
      expect(points.length, 31);
      expect(points.last.time, _now);
    });

    test('buckets land on day boundaries, not drifting fractions', () {
      final points = series(const []);
      // Every point bar the last closes a calendar day.
      for (final p in points.take(points.length - 1)) {
        expect(p.time.hour, 23);
        expect(p.time.minute, 59);
      }
    });

    test('a year is sampled monthly', () {
      expect(series(const [], frame: '1y').length, 13);
    });

    test('a day is sampled hourly', () {
      expect(series(const [], frame: '1d').length, 25);
    });
  });

  group('accuracy', () {
    test('the last point is exactly the current balance', () {
      final points = series(
        [tx(type: 'expense', amount: 200, date: '2026-08-15')],
        current: 800,
      );
      expect(points.last.balance, 800);
    });

    test('a flat history with no transactions stays flat', () {
      final points = series(const [], current: 500);
      expect(points.every((p) => p.balance == 500), isTrue);
    });

    test('an expense steps the line down on the day it happened', () {
      final points = series(
        [tx(type: 'expense', amount: 200, date: '2026-08-15')],
        current: 800,
      );
      final before = points.firstWhere((p) => p.time.day == 14);
      final after = points.firstWhere((p) => p.time.day == 15);
      expect(before.balance, 1000);
      expect(after.balance, 800);
    });

    test('income steps the line up', () {
      final points = series(
        [tx(type: 'income', amount: 300, date: '2026-08-10')],
        current: 1300,
      );
      expect(points.firstWhere((p) => p.time.day == 9).balance, 1000);
      expect(points.firstWhere((p) => p.time.day == 10).balance, 1300);
    });

    test('a withdrawal reduces the account balance', () {
      final points = series(
        [tx(type: 'withdrawal', amount: 100, date: '2026-08-12')],
        current: 900,
      );
      expect(points.firstWhere((p) => p.time.day == 11).balance, 1000);
      expect(points.firstWhere((p) => p.time.day == 12).balance, 900);
    });

    test('transactions outside the window do not move the line', () {
      final points = series(
        [tx(type: 'expense', amount: 500, date: '2026-01-01')],
        current: 1000,
      );
      expect(points.every((p) => p.balance == 1000), isTrue);
    });
  });

  group('transfers', () {
    test('an incoming transfer raises the destination account', () {
      // The old filter compared only `accountId`, so this transaction was
      // dropped entirely and money arriving never showed up.
      final points = series(
        [
          tx(
            type: 'transfer',
            amount: 250,
            date: '2026-08-14',
            accountId: 'B',
            toAccountId: 'A',
          ),
        ],
        current: 1250,
        scope: 'A',
      );
      expect(points.firstWhere((p) => p.time.day == 13).balance, 1000);
      expect(points.firstWhere((p) => p.time.day == 14).balance, 1250);
    });

    test('an outgoing transfer lowers the source account', () {
      final points = series(
        [
          tx(
            type: 'transfer',
            amount: 250,
            date: '2026-08-14',
            accountId: 'A',
            toAccountId: 'B',
          ),
        ],
        current: 750,
        scope: 'A',
      );
      expect(points.firstWhere((p) => p.time.day == 13).balance, 1000);
      expect(points.firstWhere((p) => p.time.day == 14).balance, 750);
    });

    test('across all accounts an internal transfer nets to nothing', () {
      final points = series(
        [
          tx(
            type: 'transfer',
            amount: 250,
            date: '2026-08-14',
            accountId: 'A',
            toAccountId: 'B',
          ),
        ],
        current: 1000,
      );
      expect(points.every((p) => p.balance == 1000), isTrue);
    });

    test('another account\'s spending does not move a scoped chart', () {
      final points = series(
        [tx(type: 'expense', amount: 400, date: '2026-08-14', accountId: 'B')],
        current: 1000,
        scope: 'A',
      );
      expect(points.every((p) => p.balance == 1000), isTrue);
    });
  });

  group('niceStep', () {
    test('snaps to a readable step', () {
      expect(niceStep(100, 4), 25);
      expect(niceStep(1000, 4), 250);
      expect(niceStep(8, 4), 2);
    });

    test('never returns zero or negative', () {
      expect(niceStep(0, 4), greaterThan(0));
      expect(niceStep(-50, 4), greaterThan(0));
    });
  });

  group('niceBounds', () {
    test('snaps outward so the data always fits inside', () {
      final b = niceBounds(347, 452);
      expect(b.min, lessThanOrEqualTo(347));
      expect(b.max, greaterThanOrEqualTo(452));
      expect(b.min % b.step, closeTo(0, 1e-9));
    });

    test('gives a flat series room instead of pinning it to an edge', () {
      final b = niceBounds(500, 500);
      expect(b.min, lessThan(500));
      expect(b.max, greaterThan(500));
    });

    test('handles a zero balance without dividing by nothing', () {
      final b = niceBounds(0, 0);
      expect(b.max, greaterThan(b.min));
      expect(b.step, greaterThan(0));
    });
  });

  group('labelIndices', () {
    test('always includes both ends', () {
      final labels = labelIndices(31);
      expect(labels.first, 0);
      expect(labels.last, 30);
    });

    test('never places two labels side by side once points are dense', () {
      // This is the collision that printed "17 Aug" over "18 Aug". It only
      // matters when points outnumber labels — with a handful of points they
      // are far apart on screen, so labelling every one is right.
      for (var count = 6; count <= 400; count++) {
        final labels = labelIndices(count);
        for (var i = 1; i < labels.length; i++) {
          expect(labels[i] - labels[i - 1], greaterThan(1),
              reason: 'adjacent labels at pointCount=$count: $labels');
        }
      }
    });

    test('labels every point when there are only a few', () {
      expect(labelIndices(4), [0, 1, 2, 3]);
    });

    test('stays within the requested budget', () {
      expect(labelIndices(31).length, lessThanOrEqualTo(5));
      expect(labelIndices(365, maxLabels: 6).length, lessThanOrEqualTo(6));
    });

    test('degenerate inputs do not throw', () {
      expect(labelIndices(0), isEmpty);
      expect(labelIndices(1), [0]);
      expect(labelIndices(2), [0, 1]);
    });

    test('indices stay in range', () {
      final labels = labelIndices(31);
      expect(labels.every((i) => i >= 0 && i < 31), isTrue);
    });
  });
}
