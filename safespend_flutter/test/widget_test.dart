import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/models/transaction.dart';

void main() {
  test('transaction total includes bank fees', () {
    final transaction = Transaction(
      id: '00000000-0000-4000-8000-000000000001',
      type: 'expense',
      amount: 125,
      fees: 2.5,
      date: '2026-07-23T00:00:00.000Z',
      accountId: '00000000-0000-4000-8000-000000000002',
    );

    expect(transaction.totalWithFees, 127.5);
  });
}
