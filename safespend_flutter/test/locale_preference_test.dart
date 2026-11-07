import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/models/settings.dart';

void main() {
  group('device locale resolution', () {
    test('uses the first supported language, ignoring region and script', () {
      expect(S.resolveDeviceLocale(const [Locale('ar', 'MA')]), 'ar');
      expect(S.resolveDeviceLocale(const [Locale('fr', 'CA')]), 'fr');
      expect(S.resolveDeviceLocale(const [Locale('zh', 'TW')]), 'zh');
    });

    test('skips unsupported preferences and falls back deterministically', () {
      expect(S.resolveDeviceLocale(const [Locale('sv'), Locale('fr', 'BE')]),
          'fr');
      expect(S.resolveDeviceLocale(const [Locale('sv'), Locale('da')]), 'en');
    });
  });

  test('manual locale choice survives persistence while legacy data opts in',
      () {
    const selected = Settings(locale: 'ar', localeManuallySelected: true);
    expect(Settings.fromJson(selected.toJson()).localeManuallySelected, isTrue);
    expect(Settings.fromJson({'locale': 'en'}).localeManuallySelected, isFalse);
  });
}
