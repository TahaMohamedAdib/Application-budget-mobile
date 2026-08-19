import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/l10n/translations_onboarding.dart';

/// Guards the onboarding string table.
///
/// Most of these locales are machine translated, so the risks are mechanical
/// rather than stylistic: a dropped key, a mangled `{placeholder}`, or a
/// character from the wrong script slipping in during editing. Each is
/// invisible in review and obvious to a native speaker in production.

/// Locales that legitimately use a non-Latin script. Everything else is
/// checked for stray Cyrillic, Greek or Arabic letters — the classic
/// copy-paste hazard where a Latin 'K' is replaced by Cyrillic 'К'.
const _nonLatinScripts = {'ar', 'ru', 'zh', 'ja', 'ko', 'hi'};

final _suspiciousScript = RegExp(
  r'[Ѐ-ӿ' // Cyrillic
  r'Ͱ-Ͽ' // Greek
  r'؀-ۿ' // Arabic
  r'一-鿿' // CJK
  r'ऀ-ॿ]', // Devanagari
);

/// Placeholders substituted at runtime; a translation that drops or renames
/// one silently prints the literal token to the user.
final _placeholder = RegExp(r'\{(\w+)\}');

void main() {
  final english = translationsOnboarding['en']!;

  test('English defines every key the S getters read', () {
    // A getter reading a key that no locale defines returns the key name
    // itself, which ships as visible gibberish.
    expect(english.keys, isNotEmpty);
    for (final entry in english.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} is blank');
    }
  });

  test('every supported locale is present', () {
    for (final locale in S.supportedLocales) {
      expect(
        translationsOnboarding.containsKey(locale.languageCode),
        isTrue,
        reason: '${locale.languageCode} has no onboarding strings',
      );
    }
  });

  group('per locale', () {
    for (final entry in translationsOnboarding.entries) {
      final locale = entry.key;
      final strings = entry.value;

      test('$locale covers every English key', () {
        final missing =
            english.keys.where((k) => !strings.containsKey(k)).toList();
        expect(missing, isEmpty, reason: 'missing in $locale: $missing');
      });

      test('$locale defines no key English does not', () {
        final extra =
            strings.keys.where((k) => !english.containsKey(k)).toList();
        expect(extra, isEmpty, reason: 'unknown keys in $locale: $extra');
      });

      test('$locale keeps every placeholder intact', () {
        for (final key in english.keys) {
          final expected = _placeholder
              .allMatches(english[key]!)
              .map((m) => m.group(1))
              .toSet();
          final actual = _placeholder
              .allMatches(strings[key] ?? '')
              .map((m) => m.group(1))
              .toSet();
          expect(
            actual,
            expected,
            reason: '$locale/$key placeholders drifted',
          );
        }
      });

      test('$locale has no blank strings', () {
        for (final e in strings.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$locale/${e.key}');
        }
      });

      if (!_nonLatinScripts.contains(locale)) {
        test('$locale contains no stray non-Latin characters', () {
          for (final e in strings.entries) {
            final hit = _suspiciousScript.firstMatch(e.value);
            expect(
              hit,
              isNull,
              reason: '$locale/${e.key} contains "${hit?.group(0)}" '
                  '— likely a wrong-script look-alike in "${e.value}"',
            );
          }
        });
      }
    }
  });

  test('S resolves onboarding strings for every locale', () {
    for (final locale in S.supportedLocales) {
      final s = S.forLocale(locale.languageCode);
      expect(s.obIncomeTitle, isNotEmpty);
      // A returned key name means the lookup fell through entirely.
      expect(s.obIncomeTitle, isNot('obIncomeTitle'));
      expect(s.obPayDayOfMonth(15), contains('15'));
      expect(s.obMonthlyEquivalent('X'), contains('X'));
      expect(s.obPayEveryWeekday('Y'), contains('Y'));
    }
  });
}
