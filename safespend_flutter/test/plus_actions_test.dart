import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/widgets/add_transaction_modal.dart';
import 'package:safespend_flutter/widgets/quick_actions_sheet.dart';

Widget _host(Widget child, AppProvider provider, {String locale = 'en'}) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: Locale(locale),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

Future<AppProvider> _provider(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final provider = AppProvider();
  for (var i = 0; i < 100 && !provider.localDataLoaded; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transaction number parser accepts common locale formats', () {
    expect(parseTransactionNumber('1 234,56', const Locale('fr')), 1234.56);
    expect(parseTransactionNumber('1.234,56', const Locale('de')), 1234.56);
    expect(parseTransactionNumber('1,234.56', const Locale('en')), 1234.56);
    expect(parseTransactionNumber('1250.75', const Locale('fr')), 1250.75);
    expect(parseTransactionNumber('not money', const Locale('en')), isNull);
  });

  testWidgets('global plus panel exposes only transaction quick actions',
      (tester) async {
    final provider = await _provider(tester);
    final invoked = <String>[];

    await tester.pumpWidget(_host(
      QuickActionsPanel(
        onExpense: () => invoked.add('expense'),
        onIncome: () => invoked.add('income'),
        onWithdrawal: () => invoked.add('withdrawal'),
        onTransfer: () => invoked.add('transfer'),
      ),
      provider,
    ));

    for (final entry in <String, String>{
      'Expense': 'expense',
      'Income': 'income',
      'Withdraw': 'withdrawal',
      'Transfer': 'transfer',
    }.entries) {
      expect(find.text(entry.key), findsOneWidget);
      await tester.tap(find.text(entry.key));
      await tester.pump();
      expect(invoked.last, entry.value);
    }
    expect(find.text('Add Bill'), findsNothing);
  });

  for (final locale in S.supportedLocales) {
    for (final type in ['expense', 'income', 'withdrawal', 'transfer']) {
      testWidgets('$type quick action validates in ${locale.languageCode}',
          (tester) async {
        final provider = await _provider(tester);
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _host(AddTransactionModal(initialType: type), provider,
              locale: locale.languageCode),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(AddTransactionModal), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        await tester.ensureVisible(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(
          find.byKey(const Key('transaction-validation-message')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
