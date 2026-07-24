import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/transaction.dart';

void main() {
  group('Transaction.copyWith clear semantics', () {
    final base = Transaction(
      id: 't1',
      type: 'expense',
      amount: 10,
      date: '2026-07-24',
      accountId: 'a1',
      categoryId: 'cat1',
      goalId: 'g1',
      daretId: 'd1',
      note: 'lunch',
    );

    test('omitting a field keeps it', () {
      final copy = base.copyWith(amount: 20);
      expect(copy.categoryId, 'cat1');
      expect(copy.goalId, 'g1');
      expect(copy.daretId, 'd1');
      expect(copy.note, 'lunch');
      expect(copy.amount, 20);
    });

    test('passing null clears a nullable field', () {
      final copy = base.copyWith(categoryId: null);
      expect(copy.categoryId, isNull);
      // Other fields untouched.
      expect(copy.goalId, 'g1');
      expect(copy.daretId, 'd1');
    });

    test('null on several nullable fields clears each independently', () {
      final copy = base.copyWith(goalId: null, daretId: null, note: null);
      expect(copy.goalId, isNull);
      expect(copy.daretId, isNull);
      expect(copy.note, isNull);
      expect(copy.categoryId, 'cat1');
    });

    test('replacing with a new value works', () {
      final copy = base.copyWith(categoryId: 'cat2');
      expect(copy.categoryId, 'cat2');
    });
  });

  group('Account.copyWith clear semantics', () {
    final base = Account(
      id: 'a1',
      name: 'Bank',
      type: 'bank',
      balance: 100,
      salaryAmount: 5000,
      salaryDay: 1,
      bankName: 'Acme',
    );

    test('omitting keeps nullable fields', () {
      final copy = base.copyWith(balance: 200);
      expect(copy.salaryAmount, 5000);
      expect(copy.salaryDay, 1);
      expect(copy.bankName, 'Acme');
      expect(copy.balance, 200);
    });

    test('null clears the salary fields (e.g. removing auto-salary)', () {
      final copy = base.copyWith(salaryAmount: null, salaryDay: null);
      expect(copy.salaryAmount, isNull);
      expect(copy.salaryDay, isNull);
      expect(copy.bankName, 'Acme');
    });

    test('copyWith refreshes updatedAt on mutation', () {
      final copy = base.copyWith(balance: 200);
      expect(copy.updatedAt, isNotNull);
    });

    test('updatedAt can be pinned explicitly (restore from remote)', () {
      final copy = base.copyWith(balance: 200, updatedAt: '2020-01-01T00:00:00Z');
      expect(copy.updatedAt, '2020-01-01T00:00:00Z');
    });
  });
}
