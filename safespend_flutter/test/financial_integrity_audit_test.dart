import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/recurring_rule.dart';
import 'package:safespend_flutter/services/ai/financial_context_service.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'core_feature_logic_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in ['savings', 'debt', 'personal_debt']) {
    test('$kind payment edit and deletion restore progress and bank balance',
        () async {
      final p = await fixture.emptyProvider();
      addTearDown(p.dispose);
      p.addAccount(
          Account(id: 'bank', name: 'Bank', type: 'bank', balance: 500));
      p.addGoal(Goal(id: 'goal', type: kind, name: 'Goal', targetAmount: 100));
      if (kind == 'savings') {
        p.contributeToGoalFromSource('goal', 40, 'bank');
      } else if (kind == 'debt') {
        p.payDebt('goal', 40, 'bank');
      } else {
        p.receiveDebtPayment('goal', 40, 'bank');
      }
      final t = p.transactions.single;
      p.updateTransaction(t.copyWith(amount: 25));
      expect(p.goals.single.currentAmount, 25);
      expect(p.accounts.single.balance, kind == 'personal_debt' ? 525 : 475);
      p.deleteTransaction(t.id);
      expect(p.goals.single.currentAmount, 0);
      expect(p.accounts.single.balance, 500);
    });
  }

  test(
      'overfunded goals, non-finite payments and missing sources do not mutate',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    p.addGoal(
        Goal(id: 'goal', name: 'Goal', targetAmount: 100, currentAmount: 110));
    expect(
        () =>
            p.contributeToGoalFromSource('goal', 10, AppProvider.cashOnHandId),
        returnsNormally);
    p.updateGoal(p.goals.single.copyWith(currentAmount: 0));
    p.contributeToGoalFromSource('goal', double.nan, AppProvider.cashOnHandId);
    p.contributeToGoalFromSource('goal', 20, 'missing');
    expect(p.transactions, isEmpty);
    expect(p.goals.single.currentAmount, 0);
  });

  test(
      'net worth subtracts debt accounts and preserves money allocated to savings',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    p.addAccount(Account(id: 'bank', name: 'Bank', type: 'bank', balance: 500));
    p.addAccount(Account(id: 'debt', name: 'Loan', type: 'debt', balance: 100));
    expect(p.getNetWorth(), 400);
    p.addGoal(Goal(id: 'goal', name: 'Savings', targetAmount: 200));
    p.contributeToGoalFromSource('goal', 50, 'bank');
    expect(p.getNetWorth(), 400);
  });

  test('excluded investment accounts do not enter net worth', () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    p.addAccount(Account(
        id: 'investment',
        name: 'Excluded',
        type: 'investment',
        balance: 400,
        includeInNetWorth: false));
    expect(p.getNetWorth(), 0);
  });

  test('deleting an account reverses linked history and removes its schedules',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    p.addAccount(Account(id: 'a', name: 'A', type: 'bank', balance: 500));
    p.addAccount(Account(id: 'b', name: 'B', type: 'bank', balance: 100));
    final t = fixture.transaction(
        id: 't',
        type: 'transfer',
        amount: 50,
        accountId: 'a',
        toAccountId: 'b');
    p.addTransaction(t);
    p.addRecurringRule(RecurringRule(
        id: 'rule',
        templateTransaction: t,
        frequency: 'monthly',
        nextDate: DateTime.now().toIso8601String()));
    p.setSelectedAccount('a');
    p.deleteAccount('a');
    expect(p.transactions, isEmpty);
    expect(p.recurringRules, isEmpty);
    expect(p.accounts.single.balance, 100);
    expect(p.selectedAccountId, isNull);
  });

  test('recurring charges retain fees and reverse correctly', () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    p.addAccount(Account(id: 'a', name: 'A', type: 'bank', balance: 500));
    final due = DateTime.now().subtract(const Duration(days: 1));
    p.addRecurringRule(RecurringRule(
        id: 'rule',
        frequency: 'monthly',
        nextDate: due.toIso8601String(),
        templateTransaction: fixture.transaction(
            id: 't', type: 'expense', amount: 50, fees: 3, accountId: 'a')));
    p.processSubscriptions();
    expect(p.transactions.single.fees, 3);
    expect(p.accounts.single.balance, 447);
    p.deleteTransaction(p.transactions.single.id);
    expect(p.accounts.single.balance, 500);
  });

  test('Coach assets count investment cash once and carry the chosen locale',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    p.addAccount(
        Account(id: 'i', name: 'Investment', type: 'investment', balance: 400));
    p.setLocale('ar');
    final snapshot = FinancialContextService.build(p);
    expect(snapshot.totalAssets, 400);
    expect(snapshot.toJson()['locale'], 'ar');
  });
}
