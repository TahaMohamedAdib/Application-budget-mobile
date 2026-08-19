import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/providers/app_provider.dart';

/// Editing a salary after onboarding.
///
/// The trap here is that the schedule lives on the [Account] while budgeting
/// reads `settings.monthlyIncome`. Any path that changes one without the other
/// leaves safe-to-spend quietly wrong, which is the bug the onboarding
/// rework already had to fix once.

Account bankAccount({
  String id = 'a1',
  double? salary,
  String frequency = 'monthly',
  int day = 1,
}) =>
    Account(
      id: id,
      name: 'Main',
      type: 'bank',
      balance: 1000,
      salaryAmount: salary,
      salaryFrequency: salary == null ? null : frequency,
      salaryDay: salary == null ? null : day,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Account.withSalary', () {
    test('sets amount, frequency and day', () {
      final updated = bankAccount().withSalary(
        amount: 2000,
        frequency: 'weekly',
        day: DateTime.friday,
      );
      expect(updated.salaryAmount, 2000);
      expect(updated.salaryFrequency, 'weekly');
      expect(updated.salaryDay, DateTime.friday);
    });

    test('anchors a fortnightly cycle', () {
      final updated = bankAccount().withSalary(
        amount: 1000,
        frequency: 'biweekly',
        day: DateTime.friday,
      );
      expect(updated.salaryAnchorDate, isNotNull);
    });

    test('drops a stale anchor when moving off fortnightly', () {
      final fortnightly = bankAccount().withSalary(
        amount: 1000,
        frequency: 'biweekly',
        day: DateTime.friday,
      );
      final monthly = fortnightly.withSalary(
        amount: 1000,
        frequency: 'monthly',
        day: 1,
      );
      expect(monthly.salaryAnchorDate, isNull);
    });

    test('preserves the rest of the account', () {
      final updated = bankAccount().withSalary(
        amount: 500,
        frequency: 'monthly',
        day: 5,
      );
      expect(updated.id, 'a1');
      expect(updated.name, 'Main');
      expect(updated.balance, 1000);
    });
  });

  group('Account.withoutSalary', () {
    test('clears every salary field, which copyWith cannot', () {
      final cleared = bankAccount(salary: 3000).withoutSalary();
      expect(cleared.salaryAmount, isNull);
      expect(cleared.salaryFrequency, isNull);
      expect(cleared.salaryDay, isNull);
      expect(cleared.hasSalarySchedule, isFalse);
      expect(cleared.monthlySalaryEquivalent, 0);
    });

    test('copyWith really cannot — this is why the helper exists', () {
      final still = bankAccount(salary: 3000).copyWith(salaryAmount: null);
      expect(still.salaryAmount, 3000);
    });

    test('keeps the balance and identity', () {
      final cleared = bankAccount(salary: 3000).withoutSalary();
      expect(cleared.id, 'a1');
      expect(cleared.balance, 1000);
    });
  });

  group('AppProvider.setAccountSalary', () {
    Future<AppProvider> providerWith(Account account) async {
      final provider = AppProvider();
      for (var i = 0; i < 20 && !provider.localDataLoaded; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      provider.addAccount(account);
      return provider;
    }

    test('writes the schedule and the derived monthly income together',
        () async {
      final provider = await providerWith(bankAccount());

      provider.setAccountSalary('a1',
          amount: 2000, frequency: 'monthly', day: 1);

      expect(provider.accounts.first.salaryAmount, 2000);
      expect(provider.settings.monthlyIncome, 2000);
    });

    test('annualises a weekly wage into monthly income', () async {
      final provider = await providerWith(bankAccount());

      provider.setAccountSalary('a1',
          amount: 500, frequency: 'weekly', day: DateTime.friday);

      // 500 a week over 52 weeks, not 4 x 500.
      expect(provider.settings.monthlyIncome, closeTo(2166.67, 0.01));
    });

    test('a null amount removes the salary and zeroes the income', () async {
      final provider = await providerWith(bankAccount(salary: 2000));
      provider.setAccountSalary('a1', amount: 2000);
      expect(provider.settings.monthlyIncome, 2000);

      provider.setAccountSalary('a1', amount: null);

      expect(provider.accounts.first.hasSalarySchedule, isFalse);
      expect(provider.settings.monthlyIncome, 0);
    });

    test('a zero amount is treated as removal, not a zero salary', () async {
      final provider = await providerWith(bankAccount(salary: 2000));

      provider.setAccountSalary('a1', amount: 0);

      expect(provider.accounts.first.hasSalarySchedule, isFalse);
    });

    test('sums salaries across several accounts', () async {
      final provider = await providerWith(bankAccount(id: 'a1'));
      provider.addAccount(bankAccount(id: 'a2'));

      provider.setAccountSalary('a1', amount: 2000);
      provider.setAccountSalary('a2', amount: 500, frequency: 'weekly', day: 1);

      expect(
        provider.settings.monthlyIncome,
        closeTo(2000 + 2166.67, 0.01),
      );
      expect(provider.monthlyIncomeFromSalaries,
          closeTo(provider.settings.monthlyIncome, 0.001));
    });

    test('an unknown account id changes nothing', () async {
      final provider = await providerWith(bankAccount());
      final before = provider.settings.monthlyIncome;

      provider.setAccountSalary('does-not-exist', amount: 9999);

      expect(provider.settings.monthlyIncome, before);
    });

    test('notifies listeners so the settings row refreshes', () async {
      final provider = await providerWith(bankAccount());
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setAccountSalary('a1', amount: 2000);

      expect(notified, greaterThan(0));
    });
  });
}
