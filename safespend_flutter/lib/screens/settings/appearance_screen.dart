import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/settings.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../utils/currency_helper.dart';
import '../../widgets/settings_ui.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  /// Text size staged by the slider. Null until the user moves it, so the
  /// saved value stays the source of truth until then.
  ///
  /// Unlike the switches on this screen, resizing every label in the app is
  /// disruptive to undo by dragging back, so the change is previewed here and
  /// only written once the user confirms it.
  double? _stagedScale;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Selector<AppProvider, Settings>(
      selector: (_, p) => p.settings,
      builder: (context, settings, _) {
        final provider = context.read<AppProvider>();

        void update(Settings next) => provider.updateSettings(next);

        final stagedScale = _stagedScale ?? settings.textScale;
        final hasPendingScale = stagedScale != settings.textScale;

        return SettingsScaffold(
          title: s.appearance,
          subtitle: s.appearanceSubtitle,
          children: [
            SettingsGroup(
              header: s.theme,
              footer: s.themeFooter,
              children: [
                SettingsSegmented<String>(
                  value: settings.themeMode,
                  onChanged: provider.setThemeMode,
                  segments: {
                    'light': (icon: IOSIcons.light_mode_rounded, label: s.light),
                    'dark': (icon: IOSIcons.dark_mode_rounded, label: s.dark),
                    'system': (
                      icon: IOSIcons.smartphone_rounded,
                      label: s.system
                    ),
                  },
                ),
              ],
            ),

            // Live preview — the point of a text-size control is seeing the
            // result, so the sample renders at the staged scale.
            SettingsGroup(
              header: s.textSize,
              footer: s.textSizeFooter,
              children: [
                _TextSizePreview(scale: stagedScale),
                SettingsSliderRow(
                  label: s.textSize,
                  value: stagedScale,
                  min: 0.9,
                  max: 1.3,
                  divisions: 4,
                  valueLabel: _scaleLabel(s, stagedScale),
                  onChanged: (v) => setState(() => _stagedScale = _snap(v)),
                ),
                SettingsConfirmRow(
                  label: s.textSizeApply,
                  onConfirm: hasPendingScale
                      ? () {
                          update(settings.copyWith(textScale: stagedScale));
                          setState(() => _stagedScale = null);
                          showSettingsToast(context, s.textSizeApplied);
                        }
                      : null,
                ),
              ],
            ),

            SettingsGroup(
              header: s.display,
              footer: s.hideAmountsFooter,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.visibility_off_rounded,
                  label: s.hideAmounts,
                  detail: s.hideAmountsDetail,
                  value: settings.hideAmounts,
                  onChanged: (v) =>
                      update(settings.copyWith(hideAmounts: v)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // The slider is divided into 5 stops; snapping avoids values like 1.0499999.
  static double _snap(double v) => (v * 20).round() / 20;

  static String _scaleLabel(S s, double scale) {
    if (scale <= 0.9) return s.textSizeSmall;
    if (scale < 1.0) return s.textSizeCompact;
    if (scale == 1.0) return s.textSizeDefault;
    if (scale < 1.25) return s.textSizeLarge;
    return s.textSizeLarger;
  }
}

class _TextSizePreview extends StatelessWidget {
  const _TextSizePreview({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final currency = provider.settings.currency;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: MediaQuery.withNoTextScaling(
        child: Row(
          children: [
            const SettingsIconTile(icon: IOSIcons.shopping_bag_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).textSizePreviewTitle,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.of(context).textSizePreviewSubtitle,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-${CurrencyHelper.getSymbol(currency)}42.00',
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.expenseIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
