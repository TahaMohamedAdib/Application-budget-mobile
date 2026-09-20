import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/models/settings.dart';
import 'package:safespend_flutter/utils/money_format.dart';
import 'package:safespend_flutter/widgets/money_amount.dart';

void main() {
  for (final locale in S.supportedLocales) {
    for (final value in [
      -9876543210123.45,
      9876543210123.45,
      -2498865.0,
      0.0
    ]) {
      testWidgets(
          '${locale.languageCode} large amount $value fits at 2x text scale',
          (tester) async {
        final format = MoneyFormat.of(
            Settings(currency: 'MAD', locale: locale.languageCode));
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
                body: Center(
                    child: SizedBox(
              width: 160,
              child: MoneyAmount(value: value, formatter: format),
            ))),
          ),
        ));
        expect(tester.takeException(), isNull);
        expect(find.text('MAD'), findsOneWidget);
        expect(tester.widget<Tooltip>(find.byType(Tooltip)).message,
            '${format.number(value, compactOverride: false)} MAD');
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          expect(text.overflow, isNot(TextOverflow.ellipsis));
        }
      });
    }
  }

  testWidgets('hidden amount cannot leak through caption, tooltip or semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MoneyAmount(
      value: -987654321,
      formatter:
          MoneyFormat.of(const Settings(currency: 'MAD', hideAmounts: true)),
      signed: true,
    ))));
    expect(find.text('MAD'), findsNothing);
    expect(find.text(MoneyFormat.mask), findsOneWidget);
    expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message, MoneyFormat.mask);
    expect(find.bySemanticsLabel(RegExp('987654321|MAD')), findsNothing);
    semantics.dispose();
  });

  testWidgets('inline currency stays beside exact and compact figures',
      (tester) async {
    final format = MoneyFormat.of(const Settings(currency: 'MAD'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: MoneyAmount(
              value: 9999999999999,
              formatter: format,
              currencyInline: true,
            ),
          ),
        ),
      ),
    );

    final figure = tester.widget<Text>(find.byType(Text).first);
    expect(figure.data, contains('MAD'));
    expect(find.text('MAD'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('number grouping and decimal separators follow the selected language',
      () {
    final fr = MoneyFormat.of(const Settings(locale: 'fr', currency: 'EUR'));
    expect(fr.number(1234.56), contains(',56'));
    expect(fr.number(1234.56), isNot('1,234.56'));
    expect(fr.number(2500000, compactOverride: true), isNot('2.5M'));
  });
}
