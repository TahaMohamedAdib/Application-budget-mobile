import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/settings/about_screen.dart';
import 'package:safespend_flutter/screens/settings/appearance_screen.dart';
import 'package:safespend_flutter/screens/settings/currency_format_screen.dart';
import 'package:safespend_flutter/screens/settings/currency_picker_screen.dart';
import 'package:safespend_flutter/screens/settings/data_storage_screen.dart';
import 'package:safespend_flutter/screens/settings/help_support_screen.dart';
import 'package:safespend_flutter/screens/settings/income_screen.dart';
import 'package:safespend_flutter/screens/settings/language_screen.dart';
import 'package:safespend_flutter/screens/settings/notifications_screen.dart';
import 'package:safespend_flutter/screens/settings/pin_entry_screen.dart';
import 'package:safespend_flutter/screens/settings/security_screen.dart';
import 'package:safespend_flutter/screens/settings_screen.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/theme/app_theme.dart';

/// Every settings destination, so a screen that throws on build fails here
/// rather than in someone's hands.
final _screens = <String, Widget>{
  'hub': const SettingsScreen(),
  'appearance': const AppearanceScreen(),
  'currency_format': const CurrencyFormatScreen(),
  'currency_picker': const CurrencyPickerScreen(),
  'income': const IncomeScreen(),
  'language': const LanguageScreen(),
  'notifications': const NotificationsScreen(),
  'security': const SecurityScreen(),
  'data_storage': const DataStorageScreen(),
  'help': const HelpSupportScreen(),
  'about': const AboutScreen(),
  'pin': const PinEntryScreen(mode: PinMode.create),
};

Widget _host(Widget screen, Brightness brightness) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppProvider()),
      ChangeNotifierProvider(create: (_) => AuthService()),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      locale: const Locale('en'),
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
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('hub lists every settings destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(const SettingsScreen(), Brightness.light));
    await tester.pump(const Duration(milliseconds: 400));

    for (final label in const [
      'Appearance',
      'Currency & Format',
      'Language',
      'Notifications',
      'Security & Privacy',
      'Data & Storage',
      'Help & Support',
      'About',
      'Log Out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing row: $label');
    }
  });

  testWidgets('no settings string falls through to its raw key',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // A missing translation renders the key itself, which always looks like
    // lowerCamelCase with no spaces — easy to spot and never a real label.
    final rawKey = RegExp(r'^[a-z]+[A-Z][A-Za-z]*$');

    for (final entry in _screens.entries) {
      await tester.pumpWidget(_host(entry.value, Brightness.light));
      await tester.pump(const Duration(milliseconds: 400));

      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final text in texts) {
        final data = text.data;
        if (data == null) continue;
        expect(rawKey.hasMatch(data), isFalse,
            reason: 'untranslated key "$data" on ${entry.key}');
      }
    }
  });
}
