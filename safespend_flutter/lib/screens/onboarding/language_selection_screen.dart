import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/onboarding_ui.dart';

/// Language picker, shown second so the rest of the flow can be read.
///
/// The list is driven off [S.supportedLocales] rather than a hardcoded copy,
/// so adding a locale to the app adds it here without a second edit — the old
/// duplicate list could silently fall out of step.
class LanguageSelectionScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LanguageSelectionScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<AppProvider>();
    final current = S.normalizeLocaleCode(provider.settings.locale);

    return OnboardingScaffold(
      onBack: onBack,
      footer: OnboardingButton(
        label: s.next,
        icon: IOSIcons.arrow_forward_rounded,
        onTap: onNext,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          OnboardingHero(
            icon: IOSIcons.language_rounded,
            title: s.obLanguageTitle,
            subtitle: s.obLanguageSubtitle,
          ),
          const SizedBox(height: 26),
          for (final locale in S.supportedLocales)
            OnboardingChoice(
              title: S.displayNameForLocale(locale.languageCode),
              subtitle: S.languageNames[locale.languageCode] == null
                  ? null
                  : locale.languageCode.toUpperCase(),
              selected: current == locale.languageCode,
              onTap: () =>
                  context.read<AppProvider>().setLocale(locale.languageCode),
              leading: _Flag(code: locale.languageCode),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Center(
        child: Text(
          S.flagForLocale(code),
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }
}
