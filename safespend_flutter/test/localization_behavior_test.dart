import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/utils/currency_helper.dart';
import 'package:safespend_flutter/utils/system_note.dart';
import 'package:safespend_flutter/l10n/translations.dart';

void main() {
  test('locale normalization accepts padded regional locale codes', () {
    expect(S.normalizeLocaleCode(' FR-ca '), 'fr');
    expect(S.normalizeLocaleCode('ar_MA'), 'ar');
    expect(S.normalizeLocaleCode('unknown'), 'en');
  });

  test('product name is VVollet in every locale', () {
    for (final locale in S.supportedLocales) {
      final copy = S.forLocale(locale.languageCode).tourWelcomeTitle;
      expect(copy, contains(S.appName), reason: locale.languageCode);
      expect(copy, isNot(contains('SafeSpend')), reason: locale.languageCode);
    }
  });

  for (final locale in S.supportedLocales) {
    final code = locale.languageCode;
    final s = S.forLocale(code);
    test('$code localizes stored system notes and preserves user content', () {
      final note = systemNote('savingsGoal', 'My custom name');
      expect(s.systemNote(note), '${s.savingsGoal}: My custom name');
      expect(s.systemNote(systemNote('systemSalary')), s.tr('systemSalary'));
      expect(s.systemNote('Savings: user-written text'),
          'Savings: user-written text');
      expect(s.systemNote('{not JSON'), '{not JSON');
      expect(s.systemNote(null), isNull);
    });
    test('$code has localized names for every selectable currency', () {
      for (final currency in CurrencyHelper.currencies.keys) {
        expect(translations[code], contains('currency_$currency'));
        expect(s.currencyName(currency), isNot(currency));
      }
    });
  }
}
