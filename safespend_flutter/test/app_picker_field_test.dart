import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/theme/app_icons.dart';
import 'package:safespend_flutter/widgets/app_picker_field.dart';

void main() {
  testWidgets('compact picker keeps every selected value on one line',
      (tester) async {
    const pickerKey = Key('transaction-type-picker');
    const items = [
      AppPickerItem(
        value: 'all',
        label: 'All',
        leadingIcon: AppIcons.list,
      ),
      AppPickerItem(
        value: 'expense',
        label: 'Expense',
        leadingIcon: AppIcons.expense,
      ),
      AppPickerItem(
        value: 'income',
        label: 'Income',
        leadingIcon: AppIcons.income,
      ),
      AppPickerItem(
        value: 'transfer',
        label: 'Transfer',
        leadingIcon: AppIcons.transfer,
      ),
      AppPickerItem(
        value: 'withdrawal',
        label: 'Withdrawal',
        leadingIcon: AppIcons.withdrawal,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 174,
              child: AppPickerField<String>(
                key: pickerKey,
                label: 'Type',
                value: 'withdrawal',
                prefixIcon: AppIcons.filter,
                items: items,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(pickerKey)).height, 64);
    expect(find.text('Withdrawal'), findsOneWidget);

    await tester.tap(find.byKey(pickerKey));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Withdrawal'), findsNWidgets(3));
  });
}
