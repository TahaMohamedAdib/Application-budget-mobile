import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/daret.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/recurring_rule.dart';
import 'package:safespend_flutter/models/settings.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/utils/recurring_dates.dart';

Future<AppProvider> emptyProvider() async {
  SharedPreferences.setMockInitialValues({});
  final provider = AppProvider();
  for (var i = 0; i < 100 && !provider.localDataLoaded; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(provider.localDataLoaded, isTrue);
  return provider;
}

double balanceOf(AppProvider provider, String id) =>
    provider.accounts.singleWhere((a) => a.id == id).balance;

Transaction transaction({
  required String id,
  required String type,
  required double amount,
  required String accountId,
  String? toAccountId,
  String? date,
  double fees = 0,
}) =>
    Transaction(
      id: id,
      type: type,
      amount: amount,
      fees: fees,
      accountId: accountId,
      toAccountId: toAccountId,
      date: date ?? DateTime.now().toIso8601String(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('transaction balance integrity', () {
    test(
        'editing a transfer reverses its old destination and applies the new one',
        () async {
      final provider = await emptyProvider();
      provider.addAccount(
          Account(id: 'from', name: 'From', type: 'bank', balance: 1000));
      provider.addAccount(
          Account(id: 'old-to', name: 'Old', type: 'bank', balance: 100));
      provider.addAccount(
          Account(id: 'new-to', name: 'New', type: 'bank', balance: 200));

      final original = transaction(
        id: 'transfer',
        type: 'transfer',
        amount: 300,
        fees: 5,
        accountId: 'from',
        toAccountId: 'old-to',
      );
      provider.addTransaction(original);
      provider.updateTransaction(Transaction(
        id: original.id,
        type: 'transfer',
        amount: 250,
        fees: 2,
        date: original.date,
        accountId: 'from',
        toAccountId: 'new-to',
      ));

      expect(balanceOf(provider, 'from'), 748);
      expect(balanceOf(provider, 'old-to'), 100);
      expect(balanceOf(provider, 'new-to'), 450);
    });

    test('daret account movements can be added and deleted consistently',
        () async {
      final provider = await emptyProvider();
      provider.addAccount(
          Account(id: 'bank', name: 'Bank', type: 'bank', balance: 500));
      final contribution = transaction(
        id: 'daret-out',
        type: 'daret_contribution',
        amount: 80,
        accountId: 'bank',
      );

      provider.addTransaction(contribution);
      expect(balanceOf(provider, 'bank'), 420);
      provider.deleteTransaction(contribution.id);
      expect(balanceOf(provider, 'bank'), 500);
    });
  });

  group('safe to spend', () {
    test(
        'subtracts this month outflows and fees but ignores transfers and old rows',
        () async {
      final provider = await emptyProvider();
      provider.updateSettings(const Settings(monthlyIncome: 2000));
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 15);

      provider.addTransaction(transaction(
        id: 'expense',
        type: 'expense',
        amount: 300,
        fees: 5,
        accountId: AppProvider.cashOnHandId,
      ));
      provider.addTransaction(transaction(
        id: 'goal',
        type: 'goal_contribution',
        amount: 200,
        accountId: AppProvider.cashOnHandId,
      ));
      provider.addTransaction(transaction(
        id: 'transfer',
        type: 'transfer',
        amount: 400,
        accountId: AppProvider.cashOnHandId,
        toAccountId: 'some-account',
      ));
      provider.addTransaction(transaction(
        id: 'old',
        type: 'expense',
        amount: 900,
        accountId: AppProvider.cashOnHandId,
        date: previousMonth.toIso8601String(),
      ));

      expect(provider.getSafeToSpendMonth(), 1495);
      final daysRemaining =
          DateTime(now.year, now.month + 1, 0).day - now.day + 1;
      expect(provider.getSafeToSpendToday(), 1495 / daysRemaining);
    });
  });

  group('goal mutations', () {
    test('a contribution is capped at the remaining goal amount', () async {
      final provider = await emptyProvider();
      provider.addAccount(
          Account(id: 'bank', name: 'Bank', type: 'bank', balance: 500));
      provider.addGoal(Goal(
        id: 'goal',
        name: 'Emergency fund',
        targetAmount: 100,
        currentAmount: 90,
      ));

      provider.contributeToGoalFromSource('goal', 50, 'bank');

      expect(provider.goals.single.currentAmount, 100);
      expect(balanceOf(provider, 'bank'), 490);
      expect(provider.transactions.single.amount, 10);
      expect(provider.transactions.single.categoryId, 'goal');
    });

    test('an unknown goal is ignored instead of throwing', () async {
      final provider = await emptyProvider();
      expect(
        () => provider.contributeToGoalFromSource(
            'missing', 50, AppProvider.cashOnHandId),
        returnsNormally,
      );
      expect(provider.transactions, isEmpty);
    });
  });

  group('recurring processing', () {
    test('final debt instalment charges only the amount still owed', () async {
      final provider = await emptyProvider();
      provider.addAccount(
          Account(id: 'source', name: 'Source', type: 'bank', balance: 500));
      provider.addAccount(
          Account(id: 'debt', name: 'Debt', type: 'debt', balance: 50));
      final due = DateTime.now().subtract(const Duration(days: 1));
      provider.addRecurringRule(RecurringRule(
        id: 'debt_debt',
        frequency: 'monthly',
        nextDate: due.toIso8601String(),
        templateTransaction: transaction(
          id: 'template',
          type: 'expense',
          amount: 100,
          accountId: 'source',
          date: due.toIso8601String(),
        ),
      ));

      provider.processSubscriptions();

      expect(provider.transactions.single.amount, 50);
      expect(balanceOf(provider, 'source'), 450);
      expect(balanceOf(provider, 'debt'), 0);
      expect(provider.recurringRules.single.isActive, isFalse);
    });

    test('goal recurrence retains its transaction type and caps the last save',
        () async {
      final provider = await emptyProvider();
      provider.addAccount(
          Account(id: 'source', name: 'Source', type: 'bank', balance: 500));
      provider.addGoal(Goal(
        id: 'goal',
        name: 'Goal',
        targetAmount: 100,
        currentAmount: 90,
        paymentDay: DateTime.now().day,
      ));
      final due = DateTime.now().subtract(const Duration(days: 1));
      provider.addRecurringRule(RecurringRule(
        id: 'savingsgoal_goal',
        frequency: 'monthly',
        nextDate: due.toIso8601String(),
        templateTransaction: transaction(
          id: 'template',
          type: 'goal_contribution',
          amount: 25,
          accountId: 'source',
          date: '',
        ),
      ));

      provider.processSubscriptions();

      expect(provider.transactions.single.type, 'goal_contribution');
      expect(provider.transactions.single.amount, 10);
      expect(provider.goals.single.currentAmount, 100);
      expect(balanceOf(provider, 'source'), 490);
      expect(provider.recurringRules.single.isActive, isFalse);
    });
  });

  group('daret payouts', () {
    test('checking the same payout month twice credits it only once', () async {
      final provider = await emptyProvider();
      provider.addAccount(
          Account(id: 'bank', name: 'Bank', type: 'bank', balance: 0));
      final now = DateTime.now();
      provider.addDaret(Daret(
        id: 'daret',
        name: 'Family',
        contributionPerShare: 100,
        totalShares: 2,
        payoutMonths: const [1],
        startDate: now.toIso8601String(),
        paymentSourceId: AppProvider.cashOnHandId,
        destinationAccountId: 'bank',
      ));

      provider.checkDaretPayout('daret');
      provider.checkDaretPayout('daret');

      expect(provider.transactions.where((t) => t.type == 'daret_payout'),
          hasLength(1));
      expect(balanceOf(provider, 'bank'), 200);
    });
  });

  group('nullable copyWith fields', () {
    test(
        'goal schedules can be explicitly removed without clearing omitted fields',
        () {
      final goal = Goal(
        id: 'g',
        name: 'Goal',
        description: 'Keep me',
        targetAmount: 100,
        monthlyPayment: 10,
        paymentDay: 3,
        paymentSourceAccountId: 'bank',
      );

      final updated = goal.copyWith(
        monthlyPayment: null,
        paymentDay: null,
        paymentSourceAccountId: null,
      );

      expect(updated.description, 'Keep me');
      expect(updated.monthlyPayment, isNull);
      expect(updated.paymentDay, isNull);
      expect(updated.paymentSourceAccountId, isNull);
    });

    test(
        'remote profile clears remote account selection and keeps local settings',
        () {
      const local = Settings(
        selectedAccountId: 'deleted-account',
        locale: 'fr',
        themeMode: 'dark',
        hideAmounts: true,
      );
      const remote = Settings(
        currency: 'MAD',
        monthlyIncome: 4200,
        selectedAccountId: null,
      );

      final merged = local.withRemoteProfile(remote);

      expect(merged.currency, 'MAD');
      expect(merged.monthlyIncome, 4200);
      expect(merged.selectedAccountId, isNull);
      expect(merged.locale, 'fr');
      expect(merged.themeMode, 'dark');
      expect(merged.hideAmounts, isTrue);
    });
  });

  group('recurring calendar dates', () {
    test('a 31st schedule clamps to February then returns to the 31st', () {
      final february = advanceRecurringDate(
        DateTime(2026, 1, 31, 9, 30),
        'monthly',
        scheduledDay: 31,
      );
      final march = advanceRecurringDate(
        february,
        'monthly',
        scheduledDay: 31,
      );

      expect(february, DateTime(2026, 2, 28, 9, 30));
      expect(march, DateTime(2026, 3, 31, 9, 30));
    });

    test('a leap-day yearly recurrence clamps only in non-leap years', () {
      final next = advanceRecurringDate(
        DateTime(2024, 2, 29, 12),
        'yearly',
        scheduledDay: 29,
      );
      final leap = advanceRecurringDate(
        DateTime(2027, 2, 28, 12),
        'yearly',
        scheduledDay: 29,
      );

      expect(next, DateTime(2025, 2, 28, 12));
      expect(leap, DateTime(2028, 2, 29, 12));
    });
  });
}
