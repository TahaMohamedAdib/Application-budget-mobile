import '../../widgets/app_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/settings.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../utils/currency_helper.dart';
import '../../widgets/settings_ui.dart';
import 'currency_picker_screen.dart';

class CurrencyFormatScreen extends StatelessWidget {
  const CurrencyFormatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Selector<AppProvider, Settings>(
      selector: (_, p) => p.settings,
      builder: (context, settings, _) {
        final provider = context.read<AppProvider>();
        void update(Settings next) => provider.updateSettings(next);

        return SettingsScaffold(
          title: s.currencyAndFormat,
          subtitle: s.currencyAndFormatSubtitle,
          children: [
            // Sample of every formatting choice on this screen at once.
            _FormatPreview(settings: settings),

            SettingsGroup(
              header: s.currency,
              children: [
                SettingsRow(
                  icon: IOSIcons.attach_money_rounded,
                  label: s.currency,
                  detail: S.of(context).currencyName(settings.currency),
                  value:
                      '${CurrencyHelper.getSymbol(settings.currency)} ${settings.currency}',
                  onTap: () => showAppFormSheet(
                    context: context,
                    builder: (_) => const CurrencyPickerScreen(),
                  ),
                ),
              ],
            ),

            SettingsGroup(
              header: s.numberFormat,
              footer: s.numberFormatFooter,
              children: [
                SettingsSegmented<int>(
                  value: settings.decimalPlaces,
                  onChanged: (v) => update(settings.copyWith(decimalPlaces: v)),
                  segments: {
                    0: (icon: null, label: s.decimalsNone),
                    2: (icon: null, label: s.decimalsTwo),
                  },
                ),
                SettingsSwitchRow(
                  icon: IOSIcons.numbers,
                  label: s.compactNumbers,
                  detail: s.compactNumbersDetail,
                  value: settings.compactNumbers,
                  onChanged: (v) =>
                      update(settings.copyWith(compactNumbers: v)),
                ),
              ],
            ),

            SettingsGroup(
              header: s.dateFormat,
              children: [
                for (final format in const [
                  'dd/MM/yyyy',
                  'MM/dd/yyyy',
                  'yyyy-MM-dd',
                  'd MMM yyyy',
                ])
                  SettingsChoiceRow(
                    label: DateFormat(format,
                            Localizations.localeOf(context).toLanguageTag())
                        .format(DateTime(2026, 8, 16)),
                    detail: format,
                    selected: settings.dateFormat == format,
                    onTap: () => update(settings.copyWith(dateFormat: format)),
                  ),
              ],
            ),

            SettingsGroup(
              header: s.firstDayOfWeek,
              footer: s.firstDayOfWeekFooter,
              children: [
                SettingsSegmented<int>(
                  value: settings.firstDayOfWeek,
                  onChanged: (v) =>
                      update(settings.copyWith(firstDayOfWeek: v)),
                  segments: {
                    DateTime.saturday: (icon: null, label: s.saturday),
                    DateTime.sunday: (icon: null, label: s.sunday),
                    DateTime.monday: (icon: null, label: s.monday),
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FormatPreview extends StatelessWidget {
  const _FormatPreview({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyHelper.getSymbol(settings.currency);
    final amount = settings.compactNumbers
        ? '12.4K'
        : NumberFormat.currency(
            symbol: '',
            decimalDigits: settings.decimalPlaces,
          ).format(12400).trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: GlassPanel(
        elevated: true,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).preview,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '$symbol$amount',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(IOSIcons.calendar_today_rounded,
                    size: 13, color: AppTheme.adaptiveIcon(context)),
                const SizedBox(width: 6),
                Text(
                  DateFormat(settings.dateFormat,
                          Localizations.localeOf(context).toLanguageTag())
                      .format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
