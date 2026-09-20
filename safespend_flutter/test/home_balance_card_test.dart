import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/today_screen.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/widgets/money_amount.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('balance card exposes every range and draws a smooth trend',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in const [
      ValueKey('home-total-balance-amount'),
      ValueKey('home-balance-evolution-amount'),
    ]) {
      final amount = tester.widget<MoneyAmount>(find.byKey(key));
      expect(amount.currencyInline, isTrue);
      final figure =
          find.descendant(of: find.byKey(key), matching: find.byType(Text));
      expect(
        tester.widget<Text>(figure.first).data,
        contains(amount.formatter.symbol),
      );
    }

    for (final range in ['1d', '1w', '1m', '6m', '1y']) {
      expect(find.byKey(ValueKey('balance-range-$range')), findsOneWidget);
    }

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final trend = chart.data.lineBarsData.single;
    expect(trend.isCurved, isTrue);
    expect(trend.curveSmoothness, 0.32);
    expect(trend.preventCurveOverShooting, isTrue);
    expect(trend.gradient, isNotNull);
    expect(chart.data.gridData.show, isFalse);
    expect(chart.data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
    expect(chart.data.titlesData.bottomTitles.sideTitles.showTitles, isTrue);

    final initialHighlight = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('balance-range-highlight')),
    );
    expect(initialHighlight.start, 62);
    expect(initialHighlight.duration, const Duration(milliseconds: 320));

    await tester.tap(find.byKey(const ValueKey('balance-range-1y')));
    await tester.pump();
    final movedHighlight = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('balance-range-highlight')),
    );
    expect(movedHighlight.start, 124);
    await tester.pumpAndSettle();

    final yearlyChart = tester.widget<LineChart>(find.byType(LineChart));
    final yearlyLine = yearlyChart.data.lineBarsData.single;
    final pointIndex = yearlyLine.spots.length ~/ 2;
    yearlyChart.data.lineTouchData.touchCallback!(
      FlTapDownEvent(TapDownDetails(localPosition: Offset.zero)),
      LineTouchResponse([
        TouchLineBarSpot(
          yearlyLine,
          0,
          yearlyLine.spots[pointIndex],
          0,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final selectedChart = tester.widget<LineChart>(find.byType(LineChart));
    expect(selectedChart.data.showingTooltipIndicators, hasLength(1));
    expect(
      find.byKey(ValueKey('balance-date-selected-$pointIndex')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Upcoming Subscriptions'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final subscriptionHeader = find
        .ancestor(
          of: find.text('Upcoming Subscriptions'),
          matching: find.byType(Row),
        )
        .first;
    final subscriptionSeeAll = find.descendant(
      of: subscriptionHeader,
      matching: find.text('See All'),
    );
    expect(
      tester.getCenter(find.text('Upcoming Subscriptions')).dx,
      lessThan(tester.getCenter(subscriptionSeeAll).dx),
    );
    expect(tester.takeException(), isNull);
  });
}
