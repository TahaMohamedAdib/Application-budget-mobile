import 'translations_core.dart';
import 'translations_audit.dart';
import 'translations_currencies.dart';
import 'translations_extra.dart';
import 'translations_features.dart';
import 'translations_settings.dart';
import 'translations_settings_extra.dart';
import 'translations_onboarding.dart';
import 'translations_tester_feedback.dart';

/// All translations, keyed by locale then by string key.
///
/// The settings maps are merged *per locale* rather than spread over the top:
/// a plain `...translationsSettings` would replace an entire locale's map with
/// the settings-only one, dropping every pre-existing string in it.
final translations = _merge([
  translationsCore,
  translationsAudit,
  translationsCurrencies,
  translationsExtra,
  translationsFeatures,
  translationsSettings,
  translationsSettingsExtra,
  translationsOnboarding,
  translationsTesterFeedback,
]);

Map<String, Map<String, String>> _merge(
  List<Map<String, Map<String, String>>> sources,
) {
  final result = <String, Map<String, String>>{};
  for (final source in sources) {
    source.forEach((locale, strings) {
      (result[locale] ??= <String, String>{}).addAll(strings);
    });
  }
  return result;
}
