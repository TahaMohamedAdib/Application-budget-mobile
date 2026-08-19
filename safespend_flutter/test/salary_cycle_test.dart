import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/models/account.dart';

/// Pay-cycle maths for [Account]. The onboarding questionnaire is the only
/// place most users ever set this up, so a wrong weekday or a mis-clamped
/// month day silently pays them on the wrong date forever.

Account payslip({
  required String frequency,
  required int day,
  double amount = 100,
  String? anchor,
}) =>
    Account(
      id: 'a',
      name: 'Main',
      type: 'bank',
      balance: 0,
      salaryAmount: amount,
      salaryFrequency: frequency,
      salaryDay: day,
      salaryAnchorDate: anchor,
    );

List<String> datesBetween(Account a, DateTime after, DateTime until) => a
    .payDatesBetween(after, until)
    .map((d) => d.toIso8601String().substring(0, 10))
    .toList();

void main() {
  group('monthly', () {
    test('pays on the chosen day of each month', () {
      final acc = payslip(frequency: 'monthly', day: 15);
      expect(
        datesBetween(acc, DateTime(2026, 1, 20), DateTime(2026, 4, 20)),
        ['2026-02-15', '2026-03-15', '2026-04-15'],
      );
    });

    test('clamps a 31st pay day into short months', () {
      final acc = payslip(frequency: 'monthly', day: 31);
      expect(
        datesBetween(acc, DateTime(2026, 1, 31), DateTime(2026, 4, 30)),
        ['2026-02-28', '2026-03-31', '2026-04-30'],
      );
    });

    test('leap February still pays on the 29th', () {
      final acc = payslip(frequency: 'monthly', day: 30);
      expect(
        datesBetween(acc, DateTime(2024, 2, 1), DateTime(2024, 2, 29)),
        ['2024-02-29'],
      );
    });

    test('excludes the boundary date itself so a packet is never doubled', () {
      final acc = payslip(frequency: 'monthly', day: 10);
      expect(
        datesBetween(acc, DateTime(2026, 3, 10), DateTime(2026, 3, 31)),
        isEmpty,
      );
    });
  });

  group('weekly', () {
    test('pays every chosen weekday', () {
      // 2026-03-02 is a Monday; salaryDay 5 = Friday.
      final acc = payslip(frequency: 'weekly', day: DateTime.friday);
      expect(
        datesBetween(acc, DateTime(2026, 3, 2), DateTime(2026, 3, 25)),
        ['2026-03-06', '2026-03-13', '2026-03-20'],
      );
    });

    test('a month away accrues every missed week, not one lump', () {
      final acc = payslip(frequency: 'weekly', day: DateTime.wednesday);
      // Every Wednesday in (1 Mar, 1 Apr] — the end date is inclusive, and
      // 1 Apr 2026 is itself a Wednesday, so five packets are owed.
      final dates =
          datesBetween(acc, DateTime(2026, 3, 1), DateTime(2026, 4, 1));
      expect(dates, [
        '2026-03-04',
        '2026-03-11',
        '2026-03-18',
        '2026-03-25',
        '2026-04-01'
      ]);
    });
  });

  group('biweekly', () {
    test('pays every other week on the anchor fortnight', () {
      final acc = payslip(
        frequency: 'biweekly',
        day: DateTime.friday,
        anchor: '2026-03-06',
      );
      expect(
        datesBetween(acc, DateTime(2026, 3, 6), DateTime(2026, 4, 20)),
        ['2026-03-20', '2026-04-03', '2026-04-17'],
      );
    });

    test('the off-fortnight is skipped, not paid', () {
      final acc = payslip(
        frequency: 'biweekly',
        day: DateTime.friday,
        anchor: '2026-03-06',
      );
      final dates =
          datesBetween(acc, DateTime(2026, 3, 6), DateTime(2026, 4, 20));
      expect(dates, isNot(contains('2026-03-13')));
      expect(dates, isNot(contains('2026-03-27')));
    });

    test('without an anchor it still pays on a stable fortnight', () {
      final acc = payslip(frequency: 'biweekly', day: DateTime.monday);
      final dates =
          datesBetween(acc, DateTime(2026, 3, 1), DateTime(2026, 4, 30));
      for (var i = 1; i < dates.length; i++) {
        final prev = DateTime.parse(dates[i - 1]);
        // Calendar comparison, not a Duration: these are local dates and a
        // DST change would make a true fortnight measure 13 days and 23 hours.
        expect(
          dates[i],
          DateTime(prev.year, prev.month, prev.day + 14)
              .toIso8601String()
              .substring(0, 10),
        );
      }
    });
  });

  group('monthly equivalent', () {
    test('weekly wage spreads over 52 weeks, not 48', () {
      final acc = payslip(frequency: 'weekly', day: 1, amount: 500);
      expect(acc.monthlySalaryEquivalent, closeTo(2166.67, 0.01));
    });

    test('biweekly wage spreads over 26 packets', () {
      final acc = payslip(frequency: 'biweekly', day: 1, amount: 1000);
      expect(acc.monthlySalaryEquivalent, closeTo(2166.67, 0.01));
    });

    test('monthly is passed through untouched', () {
      final acc = payslip(frequency: 'monthly', day: 1, amount: 3000);
      expect(acc.monthlySalaryEquivalent, 3000);
    });

    test('no salary means no income', () {
      final acc = Account(id: 'a', name: 'n', type: 'bank', balance: 0);
      expect(acc.monthlySalaryEquivalent, 0);
      expect(acc.hasSalarySchedule, isFalse);
    });
  });

  group('legacy rows', () {
    test('a null frequency is read as monthly', () {
      final acc = Account(
        id: 'a',
        name: 'n',
        type: 'bank',
        balance: 0,
        salaryAmount: 2000,
        salaryDay: 1,
      );
      expect(acc.effectiveSalaryFrequency, 'monthly');
      expect(acc.monthlySalaryEquivalent, 2000);
    });

    test('an unrecognised frequency falls back to monthly', () {
      final acc = payslip(frequency: 'fortnightly', day: 1, amount: 900);
      expect(acc.effectiveSalaryFrequency, 'monthly');
      expect(acc.monthlySalaryEquivalent, 900);
    });

    test('the new fields survive a JSON round trip', () {
      final acc = payslip(
        frequency: 'biweekly',
        day: DateTime.thursday,
        anchor: '2026-03-05',
      );
      final back = Account.fromJson(acc.toJson());
      expect(back.salaryFrequency, 'biweekly');
      expect(back.salaryDay, DateTime.thursday);
      expect(back.salaryAnchorDate, '2026-03-05');
    });
  });
}
