import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/settings_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Kept in step with `version:` in pubspec.yaml. Reading the real build
  /// number would need package_info_plus, which the app doesn't ship.
  static const appVersion = '1.0.0';
  static const buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SettingsScaffold(
      title: s.about,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 26),
          child: Column(
            children: [
              AppLogoWidget(
                size: 68,
                onDark: Theme.of(context).brightness == Brightness.dark,
              ),
              const SizedBox(height: 14),
              Text(
                'SafeSpend',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.version} $appVersion ($buildNumber)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        SettingsGroup(
          children: [
            SettingsRow(
              icon: IOSIcons.info_outline_rounded,
              label: s.versionLabel,
              value: '$appVersion ($buildNumber)',
              showChevron: false,
            ),
            SettingsRow(
              icon: IOSIcons.notes_rounded,
              label: s.openSourceLicenses,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'SafeSpend',
                applicationVersion: appVersion,
              ),
            ),
          ],
        ),

        SettingsGroup(
          header: s.legal,
          children: [
            SettingsRow(
              icon: IOSIcons.shield_rounded,
              label: s.privacyPolicy,
              onTap: () => _showText(context, s.privacyPolicy, s.privacyDesc),
            ),
            SettingsRow(
              icon: IOSIcons.receipt_rounded,
              label: s.termsOfService,
              onTap: () => _showText(context, s.termsOfService, s.termsDesc),
            ),
          ],
        ),

        SettingsGroup(
          children: [
            SettingsRow(
              icon: IOSIcons.numbers,
              label: s.copyDiagnostics,
              detail: s.copyDiagnosticsDetail,
              onTap: () async {
                final view = View.of(context);
                final diagnostics = <String, Object>{
                  'app': 'SafeSpend $appVersion ($buildNumber)',
                  'locale': Localizations.localeOf(context).toString(),
                  'brightness':
                      Theme.of(context).brightness.name,
                  'devicePixelRatio': view.devicePixelRatio,
                  'size':
                      '${view.physicalSize.width.round()}x${view.physicalSize.height.round()}',
                };
                await Clipboard.setData(ClipboardData(
                  text: diagnostics.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                ));
                if (context.mounted) {
                  showSettingsToast(context, S.of(context).copiedToClipboard);
                }
              },
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Center(
            child: Text(
              s.madeWithCare,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  static void _showText(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(height: 1.5, fontSize: 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(ctx).close),
          ),
        ],
      ),
    );
  }
}
