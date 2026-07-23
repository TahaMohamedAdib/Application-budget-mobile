import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/category.dart';
import 'package:safespend_flutter/models/daret.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/recurring_rule.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:safespend_flutter/providers/app_provider.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppProvider createProvider() {
    final provider = AppProvider(autoLoad: false);
    addTearDown(provider.dispose);
    return provider;
  }

  Account account(String id, double balance, {String type = 'bank'}) {
    return Account(
      id: id,
      name: id,
      type: type,
      balance: balance,
    );
  }

  Goal goal(
    String id, {
    String type = 'savings',
    double currentAmount = 0,
    double targetAmount = 1000,
  }) {
    return Goal(
      id: id,
      type: type,
      name: id,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
    );
  }

  double balanceOf(AppProvider provider, String accountId) {
    return provider.accounts.firstWhere((item) => item.id == accountId).balance;
  }

  double goalAmount(AppProvider provider, String goalId) {
    return provider.goals.firstWhere((item) => item.id == goalId).currentAmount;
  }

  group('transfers', () {
    test('addTransaction debits source and credits destination', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addAccount(account('destination', 100));

      provider.addTransaction(
        Transaction(
          id: 'transfer-add',
          type: 'transfer',
          amount: 200,
          date: DateTime.now().toIso8601String(),
          accountId: 'source',
          toAccountId: 'destination',
        ),
      );

      expect(balanceOf(provider, 'source'), 800);
      expect(balanceOf(provider, 'destination'), 300);
    });

    test('updateTransaction restores old destination and credits new one', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addAccount(account('old-destination', 100))
        ..addAccount(account('new-destination', 50));
      final original = Transaction(
        id: 'transfer-update',
        type: 'transfer',
        amount: 200,
        date: DateTime.now().toIso8601String(),
        accountId: 'source',
        toAccountId: 'old-destination',
      );
      provider.addTransaction(original);

      provider.updateTransaction(
        original.copyWith(
          amount: 150,
          toAccountId: 'new-destination',
        ),
      );

      expect(balanceOf(provider, 'source'), 850);
      expect(balanceOf(provider, 'old-destination'), 100);
      expect(balanceOf(provider, 'new-destination'), 200);
    });

    test('deleteTransaction restores both transfer balances', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addAccount(account('destination', 100));
      final transaction = Transaction(
        id: 'transfer-delete',
        type: 'transfer',
        amount: 200,
        date: DateTime.now().toIso8601String(),
        accountId: 'source',
        toAccountId: 'destination',
      );
      provider.addTransaction(transaction);

      provider.deleteTransaction(transaction.id);

      expect(balanceOf(provider, 'source'), 1000);
      expect(balanceOf(provider, 'destination'), 100);
      expect(provider.transactions, isEmpty);
    });

    test('updateTransaction can change a transfer into an expense', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addAccount(account('destination', 100));
      final original = Transaction(
        id: 'transfer-to-expense',
        type: 'transfer',
        amount: 200,
        date: DateTime.now().toIso8601String(),
        accountId: 'source',
        toAccountId: 'destination',
      );
      provider.addTransaction(original);

      provider.updateTransaction(
        Transaction(
          id: original.id,
          type: 'expense',
          amount: 50,
          date: original.date,
          accountId: 'source',
        ),
      );

      expect(balanceOf(provider, 'source'), 950);
      expect(balanceOf(provider, 'destination'), 100);
    });
  });

  group('linked goals and debts', () {
    test('goal contribution is linked, UUID-backed, and reversible', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addGoal(goal('savings-goal', currentAmount: 100));

      provider.contributeToGoalFromSource('savings-goal', 200, 'source');

      final transaction = provider.transactions.single;
      expect(transaction.goalId, 'savings-goal');
      expect(_uuidPattern.hasMatch(transaction.id), isTrue);
      expect(goalAmount(provider, 'savings-goal'), 300);
      expect(balanceOf(provider, 'source'), 800);

      provider.deleteTransaction(transaction.id);

      expect(goalAmount(provider, 'savings-goal'), 100);
      expect(balanceOf(provider, 'source'), 1000);
    });

    test('editing a debt payment adjusts the goal by the exact delta', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addGoal(goal(
          'debt-goal',
          type: 'debt',
          currentAmount: 50,
        ));

      provider.payDebt('debt-goal', 200, 'source');
      final original = provider.transactions.single;
      provider.updateTransaction(original.copyWith(amount: 125));

      expect(goalAmount(provider, 'debt-goal'), 175);
      expect(balanceOf(provider, 'source'), 875);
      expect(provider.transactions.single.goalId, 'debt-goal');
    });

    test('editing a linked transaction can move it to another goal', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addGoal(goal('first-goal'))
        ..addGoal(goal('second-goal'));
      provider.contributeToGoalFromSource('first-goal', 100, 'source');
      final original = provider.transactions.single;

      provider.updateTransaction(original.copyWith(goalId: 'second-goal'));

      expect(goalAmount(provider, 'first-goal'), 0);
      expect(goalAmount(provider, 'second-goal'), 100);
      expect(balanceOf(provider, 'source'), 900);
    });

    test('personal debt return and received payment remain linked', () {
      final provider = createProvider()
        ..addAccount(account('source', 1000))
        ..addAccount(account('destination', 100))
        ..addGoal(goal('owed-by-me', type: 'personal_debt'))
        ..addGoal(goal('owed-to-me', type: 'personal_debt'));

      provider.recordPersonalDebtReturn('owed-by-me', 80, 'source');
      provider.receiveDebtPayment('owed-to-me', 60, 'destination');

      expect(provider.transactions, hasLength(2));
      expect(
        provider.transactions.map((transaction) => transaction.goalId),
        containsAll(<String>['owed-by-me', 'owed-to-me']),
      );
      expect(
        provider.transactions.every(
          (transaction) => _uuidPattern.hasMatch(transaction.id),
        ),
        isTrue,
      );
      expect(goalAmount(provider, 'owed-by-me'), 80);
      expect(goalAmount(provider, 'owed-to-me'), 60);

      for (final transaction in List<Transaction>.from(provider.transactions)) {
        provider.deleteTransaction(transaction.id);
      }

      expect(goalAmount(provider, 'owed-by-me'), 0);
      expect(goalAmount(provider, 'owed-to-me'), 0);
      expect(balanceOf(provider, 'source'), 1000);
      expect(balanceOf(provider, 'destination'), 100);
    });
  });

  test('deleteCategory detaches transactions without changing balances', () {
    final provider = createProvider()
      ..addAccount(account('source', 1000))
      ..addCategory(
        Category(
          id: 'food',
          name: 'Food',
          group: 'variable',
          icon: 'restaurant',
          color: '#000000',
        ),
      );
    provider.addTransaction(
      Transaction(
        id: 'categorized-expense',
        type: 'expense',
        amount: 100,
        date: DateTime.now().toIso8601String(),
        accountId: 'source',
        categoryId: 'food',
      ),
    );
    final balanceBeforeDelete = balanceOf(provider, 'source');

    provider.deleteCategory('food');

    expect(provider.categories, isEmpty);
    expect(provider.transactions.single.categoryId, isNull);
    expect(balanceOf(provider, 'source'), balanceBeforeDelete);
  });

  test('processSubscriptions preserves type and is idempotent for a due date',
      () {
    final provider = createProvider()..addAccount(account('source', 1000));
    provider.addRecurringRule(
      RecurringRule(
        id: 'daret-rule',
        templateTransaction: Transaction(
          id: 'daret-template',
          type: 'daret_contribution',
          amount: 100,
          date: DateTime.now().toIso8601String(),
          accountId: 'source',
        ),
        frequency: 'monthly',
        nextDate: DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      ),
    );

    provider.processSubscriptions();
    provider.processSubscriptions();

    final generated = provider.transactions
        .where((transaction) => transaction.isRecurring)
        .toList();
    expect(generated, hasLength(1));
    expect(generated.single.type, 'daret_contribution');
    expect(balanceOf(provider, 'source'), 900);
  });

  test('getBalanceForAccount excludes investments and includes cash', () {
    final provider = createProvider()
      ..addAccount(account('bank', 100))
      ..addAccount(account('savings', 20, type: 'savings'))
      ..addAccount(account('investment', 1000, type: 'investment'));
    provider.addTransaction(
      Transaction(
        id: 'cash-withdrawal',
        type: 'withdrawal',
        amount: 40,
        date: DateTime.now().toIso8601String(),
        accountId: 'bank',
      ),
    );

    expect(balanceOf(provider, 'bank'), 60);
    expect(provider.totalCash, 40);
    expect(provider.getBalanceForAccount(null), 120);
    expect(provider.getBalanceForAccount('investment'), 1000);
  });

  test('getCategorySpending sums only current-month expenses', () {
    final provider = createProvider()..addAccount(account('source', 2000));
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 15);

    for (final transaction in <Transaction>[
      Transaction(
        id: 'current-food',
        type: 'expense',
        amount: 40,
        date: now.toIso8601String(),
        accountId: 'source',
        categoryId: 'food',
      ),
      Transaction(
        id: 'current-other',
        type: 'expense',
        amount: 25,
        date: now.toIso8601String(),
        accountId: 'source',
        categoryId: 'other',
      ),
      Transaction(
        id: 'old-food',
        type: 'expense',
        amount: 100,
        date: previousMonth.toIso8601String(),
        accountId: 'source',
        categoryId: 'food',
      ),
      Transaction(
        id: 'income-food',
        type: 'income',
        amount: 500,
        date: now.toIso8601String(),
        accountId: 'source',
        categoryId: 'food',
      ),
    ]) {
      provider.addTransaction(transaction);
    }

    expect(provider.getCategorySpending('food'), 40);
  });

  test('processSalaries credits at most once per calendar month', () {
    final now = DateTime.now();
    final provider = createProvider()
      ..addAccount(
        Account(
          id: 'salary-account',
          name: 'Salary',
          type: 'bank',
          balance: 1000,
          salaryAmount: 300,
          salaryDay: now.day,
        ),
      );

    provider.processSalaries();
    provider.processSalaries();

    expect(balanceOf(provider, 'salary-account'), 1300);
    expect(
      provider.transactions
          .where((transaction) => transaction.note == 'Salary'),
      hasLength(1),
    );
  });

  test('direct Daret contribution and payout use UUID transaction IDs', () {
    final now = DateTime.now();
    final provider = createProvider()
      ..addAccount(account('source', 1000))
      ..addAccount(account('destination', 100))
      ..addDaret(
        Daret(
          id: 'daret',
          name: 'Daret',
          contributionPerShare: 100,
          totalShares: 2,
          payoutMonths: const [1],
          startDate: DateTime(now.year, now.month, 1).toIso8601String(),
          paymentSourceId: 'source',
          destinationAccountId: 'destination',
        ),
      );

    provider.processDaretContribution('daret');
    provider.checkDaretPayout('daret');

    expect(provider.transactions, hasLength(2));
    expect(
      provider.transactions.every(
        (transaction) => _uuidPattern.hasMatch(transaction.id),
      ),
      isTrue,
    );
  });
}
