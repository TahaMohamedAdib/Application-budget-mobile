import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/category.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/holding.dart';
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

  test('an overdrawn bank account reduces the combined bank balance',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    await p.addAccount(
        Account(id: 'a', name: 'Bank A', type: 'bank', balance: 500));
    await p.addAccount(
        Account(id: 'b', name: 'Bank B', type: 'bank', balance: -100));
    expect(p.getTotalByAccountType('bank'), 400);
  });

  test('excluded category expenses still change the actual bank balance',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    await p.addAccount(
        Account(id: 'bank', name: 'Bank', type: 'bank', balance: 5000));
    p.addCategory(Category(
      id: 'travel',
      name: 'Travel',
      group: 'variable',
      icon: 'flight',
      color: '#06b6d4',
      includeInMonthlyBudget: false,
    ));
    final expense = fixture.transaction(
      id: 'expense',
      type: 'expense',
      amount: 300,
      fees: 5,
      accountId: 'bank',
    ).copyWith(categoryId: 'travel');

    p.addTransaction(expense);
    p.addTransaction(expense);
    p.addTransaction(expense.copyWith(id: 'invalid', amount: double.nan));
    expect(p.transactions, hasLength(1));
    expect(p.accounts.single.balance, 4695);

    p.updateTransaction(expense.copyWith(amount: 200));
    expect(p.accounts.single.balance, 4795);
    p.deleteTransaction(expense.id);
    expect(p.accounts.single.balance, 5000);
  });

  test('a sale credits the account currency and cannot sell stale shares',
      () async {
    final p = await fixture.emptyProvider();
    addTearDown(p.dispose);
    await p.addAccount(
        Account(id: 'bank', name: 'Bank', type: 'bank', balance: 5000));
    final holding = Holding(
      id: 'shares',
      symbol: 'AAPL',
      shares: 3,
      costBasis: 175,
      currentPrice: 200,
    );
    p.addHolding(holding);

    p.sellHolding(
      holding: holding,
      sharesToSell: 2,
      sellPriceInAccountCurrency: 2000,
      accountId: 'bank',
      transactionId: 'sale',
    );
    expect(p.accounts.single.balance, 9000);
    expect(p.transactions.single.amount, 4000);
    expect(p.holdings.single.shares, 1);

    p.sellHolding(
      holding: holding,
      sharesToSell: 2,
      sellPriceInAccountCurrency: 2000,
      accountId: 'bank',
      transactionId: 'second-sale',
    );
    expect(p.accounts.single.balance, 9000);
    expect(p.transactions, hasLength(1));
    expect(p.holdings.single.shares, 1);
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
