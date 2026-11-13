import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/portfolio_screen.dart';
import 'package:safespend_flutter/screens/wealth_screen.dart';
import 'package:safespend_flutter/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host() => ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const WealthScreen(),
        ),
      );

  testWidgets('investments is marked upcoming and cannot open the portfolio',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 600));

    final investments = find.byKey(const Key('wealth-investments-upcoming'));
    await tester.ensureVisible(investments);
    await tester.pumpAndSettle();

    expect(find.text('Upcoming feature'), findsOneWidget);
    final node = tester.getSemantics(investments);
    expect(node.label, 'Investments. Upcoming feature');
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    semantics.dispose();

    await tester.tap(investments, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(WealthScreen), findsOneWidget);
    expect(find.byType(PortfolioScreen), findsNothing);
  });

  test('the upcoming-feature label is translated in every locale', () {
    for (final locale in S.supportedLocales) {
      expect(
        S.forLocale(locale.languageCode).upcomingFeature,
        isNot('upcomingFeature'),
        reason: locale.languageCode,
      );
    }
  });
}
