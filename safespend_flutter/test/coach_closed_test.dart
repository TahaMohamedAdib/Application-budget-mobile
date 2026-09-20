import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/coach_screen.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/theme/app_theme.dart';

/// The AI Coach is closed behind a "coming soon" screen. These cover the
/// things the feature-screens smoke test cannot: it only asserts that the
/// screen throws nothing, which an entirely blank screen also satisfies —
/// and a blank screen is exactly what shipped when the coming-soon branch
/// sat behind a loading guard that never completed offline.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(String locale, Brightness brightness) => MultiProvider(
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
          home: const CoachScreen(),
        ),
      );

  Future<void> pump(WidgetTester tester,
      {String locale = 'en', Brightness brightness = Brightness.dark}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(locale, brightness));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('shows the coming-soon message rather than a blank screen',
      (tester) async {
    await pump(tester);
    expect(find.text('AI Coach coming soon'), findsOneWidget);
  });

  testWidgets('renders without waiting on conversation loading',
      (tester) async {
    // No SharedPreferences, no Supabase, no secure storage: the screen must
    // paint on the very first frame instead of spinning. This is the
    // regression that shipped once — the coming-soon branch sat behind the
    // _ready guard, so an incomplete load left an endless spinner.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host('en', Brightness.dark));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('AI Coach coming soon'), findsOneWidget);
    // Let the entrance animation finish: tearing the tree down mid-flight
    // leaves its timer pending and fails the test on an unrelated invariant.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('offers no way to start a conversation', (tester) async {
    await pump(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('builds in every supported locale and both themes',
      (tester) async {
    for (final locale in S.supportedLocales) {
      for (final brightness in Brightness.values) {
        await pump(tester,
            locale: locale.languageCode, brightness: brightness);
        // Never a raw translation key on screen.
        expect(find.text('aiCoachComingSoon'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
