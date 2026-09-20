import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:safespend_flutter/models/settings.dart';
import 'package:safespend_flutter/utils/money_format.dart';
import 'package:safespend_flutter/widgets/money_amount.dart';
import 'package:safespend_flutter/widgets/wealth_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('wealth UI fits a compact screen in ${brightness.name} mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var backPressed = false;
      var addPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    WealthPageHeader(
                      title: 'Personal Debts',
                      subtitle: 'Money other people owe you',
                      onBack: () => backPressed = true,
                      onAdd: () => addPressed = true,
                      addTooltip: 'Add personal debt',
                    ),
                    const SizedBox(height: 16),
                    WealthOverviewCard(
                      icon: IOSIcons.wealthPersonalDebts,
                      label: 'Still owed to you',
                      amountValue: 2500815.00,
                      formatter:
                          MoneyFormat.of(const Settings(currency: 'MAD')),
                      firstLabel: 'Total lent',
                      firstValue: '3,000,000.00 MAD',
                      secondLabel: 'Received',
                      secondValue: '499,185.00 MAD',
                      progress: 0.42,
                      progressLabel: '42% received',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<MoneyAmount>(find.byType(MoneyAmount).first)
            .currencyInline,
        isTrue,
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.tap(find.byTooltip('Add personal debt'));
      expect(backPressed, isTrue);
      expect(addPressed, isTrue);
    });
  }

  group('MoneyAmount', () {
    /// The value from the reported screenshot: a negative net worth in a
    /// currency written with three letters, on a narrow phone.
    const netWorth = -2498865.00;

    MoneyFormat fmt({bool hide = false, bool compact = false}) =>
        MoneyFormat.of(Settings(
          currency: 'MAD',
          hideAmounts: hide,
          compactNumbers: compact,
        ));

    Future<void> pump(
      WidgetTester tester, {
      required num value,
      double width = 241,
      double fontSize = 38,
      double minFontSize = 26,
      bool signed = false,
      bool allowCompact = true,
      double textScale = 1.0,
      MoneyFormat? formatter,
    }) async {
      await tester.binding.setSurfaceSize(const Size(329, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: MoneyAmount(
                  value: value,
                  formatter: formatter ?? fmt(),
                  fontSize: fontSize,
                  minFontSize: minFontSize,
                  signed: signed,
                  allowCompact: allowCompact,
                ),
              ),
            ),
          ),
        ),
      ));
    }

    /// The figure itself, ignoring the currency caption beneath it.
    Text figure(WidgetTester tester) =>
        tester.widget<Text>(find.byType(Text).first);

    testWidgets('keeps every digit of a seven-figure balance', (tester) async {
      // The reported bug: this rendered as "-2.5M", hiding 98,865 of real
      // money on a card with room to show it smaller.
      await pump(tester, value: netWorth);
      expect(figure(tester).data, contains('2,498,865'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shrinks the type rather than abbreviating', (tester) async {
      // minFontSize is the caller's preference, not a hard limit: keeping the
      // digits is worth more than keeping the type at a particular size, so
      // the figure is allowed below 26 here rather than becoming "-2.5M".
      await pump(tester, value: netWorth);
      final size = figure(tester).style?.fontSize ?? 0;
      expect(size, lessThan(38));
      expect(size, greaterThan(13));
    });

    testWidgets('a short amount keeps the full hero size', (tester) async {
      await pump(tester, value: 350);
      expect(figure(tester).style?.fontSize, 38);
    });

    testWidgets('shows the currency as its own caption', (tester) async {
      await pump(tester, value: netWorth);
      expect(find.text('MAD'), findsOneWidget);
    });

    testWidgets('abbreviates only when the exact figure cannot fit',
        (tester) async {
      // Thirteen digits in a 90px box: no font size in range shows them all.
      await pump(tester, value: -9999999999999.0, width: 90);
      expect(figure(tester).data, isNot(contains('9,999,999,999,999')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('never abbreviates when the caller forbids it', (tester) async {
      await pump(tester,
          value: -9999999999999.0, width: 90, allowCompact: false);
      expect(figure(tester).data, contains('9,999,999,999,999'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('marks a positive value with a plus when asked',
        (tester) async {
      await pump(tester, value: 1000, signed: true);
      expect(figure(tester).data, startsWith('+'));
    });

    testWidgets('a negative value keeps one minus and gains no plus',
        (tester) async {
      await pump(tester, value: -2500815.0, signed: true);
      final text = figure(tester).data!;
      expect(text, startsWith('-'));
      expect(text, isNot(contains('+')));
    });

    testWidgets('a hidden balance shows neither digits nor currency',
        (tester) async {
      await pump(tester, value: netWorth, formatter: fmt(hide: true));
      expect(find.text(MoneyFormat.mask), findsOneWidget);
      expect(find.text('MAD'), findsNothing);
    });

    testWidgets('a hidden balance does not leak its sign', (tester) async {
      await pump(tester,
          value: netWorth, signed: true, formatter: fmt(hide: true));
      final text = figure(tester).data!;
      expect(text, isNot(contains('-')));
      expect(text, isNot(contains('+')));
    });

    testWidgets('honours the compact preference without being forced',
        (tester) async {
      await pump(tester, value: netWorth, formatter: fmt(compact: true));
      expect(figure(tester).data, contains('M'));
    });

    testWidgets('a large text scale still fits on one line', (tester) async {
      await pump(tester, value: netWorth, textScale: 1.3);
      expect(figure(tester).maxLines, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an infinite value degrades instead of throwing',
        (tester) async {
      await pump(tester, value: double.infinity);
      expect(tester.takeException(), isNull);
    });
  });
}
