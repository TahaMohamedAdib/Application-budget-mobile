import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/l10n/translations.dart';

final _placeholder = RegExp(r'\{(\w+)\}');

void main() {
  final supported =
      S.supportedLocales.map((locale) => locale.languageCode).toSet();
  final english = translations[S.fallbackLocale]!;

  test('catalog contains exactly the supported locales', () {
    expect(translations.keys.toSet(), supported);
  });

  test('every dynamic UI translation key exists in English', () {
    final usedKeys = <String>{};
    final expression = RegExp(r"\.tr\('([^']+)'");
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match in expression.allMatches(entity.readAsStringSync())) {
        final key = match.group(1)!;
        if (!key.contains(r'$')) usedKeys.add(key);
      }
    }

    final missing = usedKeys.where((key) => !english.containsKey(key)).toList()
      ..sort();
    expect(missing, isEmpty,
        reason: 'dynamic keys missing from English: $missing');
  });

  test('every typed localization getter exists in English', () {
    final source = File('lib/l10n/app_localizations.dart').readAsStringSync();
    final keys =
        RegExp(r"_t\('([^']+)'\)").allMatches(source).map((m) => m.group(1)!);
    expect(keys.where((key) => !english.containsKey(key)), isEmpty);
  });

  for (final locale in supported) {
    test('$locale has complete English-key parity', () {
      final localized = translations[locale]!;
      final missing = english.keys
          .where((key) => !localized.containsKey(key))
          .toList()
        ..sort();
      final extra = localized.keys
          .where((key) => !english.containsKey(key))
          .toList()
        ..sort();

      expect(missing, isEmpty, reason: '$locale is missing: $missing');
      expect(extra, isEmpty, reason: '$locale has unknown keys: $extra');
    });

    test('$locale preserves placeholders and has no blank values', () {
      final localized = translations[locale]!;
      for (final entry in english.entries) {
        final actual = localized[entry.key]!;
        expect(actual.trim(), isNotEmpty,
            reason: '$locale/${entry.key} is blank');

        final expectedPlaceholders = _placeholder
            .allMatches(entry.value)
            .map((match) => match.group(1))
            .toSet();
        final actualPlaceholders = _placeholder
            .allMatches(actual)
            .map((match) => match.group(1))
            .toSet();
        expect(
          actualPlaceholders,
          expectedPlaceholders,
          reason: '$locale/${entry.key} has different placeholders',
        );
      }
    });
  }
}
