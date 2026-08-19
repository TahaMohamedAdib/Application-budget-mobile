import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../widgets/settings_ui.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<AppProvider>();
    final current = S.normalizeLocaleCode(provider.settings.locale);
    final entries = S.localeDisplayNames.entries.toList();

    return SettingsScaffold(
      title: s.language,
      subtitle: s.languageSubtitle,
      children: [
        SettingsGroup(
          footer: s.languageFooter,
          children: entries.map((entry) {
            return SettingsChoiceRow(
              label: entry.value,
              detail: entry.key.toUpperCase(),
              selected: entry.key == current,
              leading: Text(
                S.flagForLocale(entry.key),
                style: const TextStyle(fontSize: 22),
              ),
              onTap: () {
                context.read<AppProvider>().setLocale(entry.key);
                Navigator.of(context).maybePop();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
