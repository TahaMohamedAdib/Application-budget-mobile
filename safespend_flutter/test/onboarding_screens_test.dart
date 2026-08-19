import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/onboarding/aha_screen.dart';
import 'package:safespend_flutter/screens/onboarding/hook_screen.dart';
import 'package:safespend_flutter/screens/onboarding/language_selection_screen.dart';
import 'package:safespend_flutter/screens/onboarding/onboarding_flow.dart';
import 'package:safespend_flutter/screens/onboarding/preview_screen.dart';
import 'package:safespend_flutter/screens/onboarding/setup_screen.dart';
import 'package:safespend_flutter/screens/onboarding/welcome_screen.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/theme/app_theme.dart';

/// Every first-run destination, so a screen that throws on build fails here
/// rather than in front of a user who has not yet decided to trust the app.
final _screens = <String, Widget>{
  'welcome': WelcomeScreen(onNext: () {}),
  'language': LanguageSelectionScreen(onNext: () {}, onBack: () {}),
  'hook': HookScreen(onNext: () {}, onBack: () {}),
  'aha': AhaScreen(onNext: () {}, onBack: () {}),
  'preview': PreviewScreen(onNext: () {}, onBack: () {}),
  'setup': SetupScreen(onComplete: () {}, onBack: () {}),
  'flow': OnboardingFlow(onComplete: () {}),
};

Widget _host(Widget screen, Brightness brightness, {String locale = 'en'}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppProvider()),
      ChangeNotifierProvider(create: (_) => AuthService()),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      locale: Locale(locale),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final brightness in Brightness.values) {
    for (final entry in _screens.entries) {
      testWidgets('${entry.key} builds in ${brightness.name} mode',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_host(entry.value, brightness));
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('every supported locale renders the questionnaire',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final locale in S.supportedLocales) {
      await tester.pumpWidget(
        _host(
          SetupScreen(onComplete: () {}, onBack: () {}),
          Brightness.dark,
          locale: locale.languageCode,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.takeException(),
        isNull,
        reason: 'setup screen threw in ${locale.languageCode}',
      );
    }
  });

  group('questionnaire', () {
    Future<void> pumpSetup(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(SetupScreen(onComplete: () {}, onBack: () {}), Brightness.dark),
      );
      await tester.pump(const Duration(seconds: 1));
    }

    /// Taps the primary action and lets the page transition finish. The bare
    /// pump starts the animation; the second one runs it past its 340ms.
    Future<void> tapNext(WidgetTester tester) async {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('opens on the currency step', (tester) async {
      await pumpSetup(tester);
      expect(find.text('Which currency?'), findsOneWidget);
      // Currency comes first so later steps can show the right symbol.
      expect(find.text('US Dollar'), findsOneWidget);
    });

    testWidgets('an unnamed account blocks the account step', (tester) async {
      await pumpSetup(tester);
      await tapNext(tester);
      expect(find.text('Your main account'), findsOneWidget);

      await tapNext(tester);
      // Still on the same step, with the reason shown inline.
      expect(find.text('Your main account'), findsOneWidget);
      expect(
        find.text('Give the account a name so you can tell it apart.'),
        findsOneWidget,
      );
    });

    testWidgets('a named account advances to the balance step', (tester) async {
      await pumpSetup(tester);
      await tapNext(tester);

      await tester.enterText(find.byType(TextField).first, 'Main Checking');
      await tester.pump();
      await tapNext(tester);

      expect(find.text('What\'s in it today?'), findsOneWidget);
    });

    testWidgets('a blank balance is refused, zero is accepted', (tester) async {
      await pumpSetup(tester);
      await tapNext(tester);
      await tester.enterText(find.byType(TextField).first, 'Main');
      await tester.pump();
      await tapNext(tester);

      await tapNext(tester);
      expect(
        find.text('Enter a balance, or 0 if the account is empty.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, '0');
      await tester.pump();
      await tapNext(tester);
      expect(find.text('How are you paid?'), findsOneWidget);
    });

    testWidgets('the income step can be skipped and says so on the summary',
        (tester) async {
      await pumpSetup(tester);
      await tapNext(tester);
      await tester.enterText(find.byType(TextField).first, 'Main');
      await tester.pump();
      await tapNext(tester);
      await tester.enterText(find.byType(TextField).first, '1200');
      await tester.pump();
      await tapNext(tester);

      expect(find.text('How are you paid?'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Ready to go'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('a weekly wage is restated as a monthly figure',
        (tester) async {
      await pumpSetup(tester);
      await tapNext(tester);
      await tester.enterText(find.byType(TextField).first, 'Main');
      await tester.pump();
      await tapNext(tester);
      await tester.enterText(find.byType(TextField).first, '0');
      await tester.pump();
      await tapNext(tester);

      await tester.enterText(find.byType(TextField).first, '500');
      await tester.pump();
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 500 a week is 52 packets a year, not 48 — 2,166.67 a month.
      expect(
        find.textContaining('2,166.67'),
        findsOneWidget,
        reason: 'weekly wage should be annualised over 52 weeks',
      );
    });
  });
}
