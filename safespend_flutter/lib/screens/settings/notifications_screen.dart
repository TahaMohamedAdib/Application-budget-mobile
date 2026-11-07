import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/settings.dart';
import '../../providers/app_provider.dart';
import '../../services/notifications/notification_service.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/settings_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Selector<AppProvider, Settings>(
      selector: (_, p) => p.settings,
      builder: (context, settings, _) {
        final provider = context.read<AppProvider>();
        void update(Settings next) => provider.updateSettings(next);

        // Every category is meaningless while the master switch is off, so the
        // whole list below dims and stops responding rather than silently
        // recording preferences that can't fire.
        final on = settings.notificationsEnabled ?? false;

        return SettingsScaffold(
          title: s.notifications,
          subtitle: s.notificationsSubtitle,
          children: [
            SettingsGroup(
              footer: s.pushNotificationsFooter,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.notifications_rounded,
                  label: s.pushNotifications,
                  detail: s.remindersForBills,
                  value: on,
                  onChanged: (v) async {
                    if (!v) {
                      update(settings.copyWith(notificationsEnabled: false));
                      return;
                    }
                    final granted =
                        await NotificationService.instance.requestPermission();
                    if (context.mounted && granted) {
                      update(settings.copyWith(notificationsEnabled: true));
                    }
                  },
                ),
              ],
            ),
            SettingsGroup(
              header: s.alerts,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.today,
                  label: 'Expense reminder',
                  detail: 'A daily local reminder to log spending',
                  enabled: on,
                  value: settings.expenseReminderEnabled,
                  onChanged: (v) =>
                      update(settings.copyWith(expenseReminderEnabled: v)),
                ),
                if (settings.expenseReminderEnabled)
                  SettingsRow(
                    icon: IOSIcons.access_time_rounded,
                    label: 'Reminder time',
                    value: _fmt(settings.expenseReminderMinutes),
                    onTap: on
                        ? () => _pickTime(
                            context,
                            settings.expenseReminderMinutes,
                            (m) => update(
                                settings.copyWith(expenseReminderMinutes: m)))
                        : null,
                  ),
                SettingsSwitchRow(
                  icon: IOSIcons.receipt_long_rounded,
                  label: s.billReminders,
                  detail: s.billRemindersDetail,
                  enabled: on,
                  value: settings.billReminders,
                  onChanged: (v) => update(settings.copyWith(billReminders: v)),
                ),
                SettingsSwitchRow(
                  icon: IOSIcons.pie_chart_outline_rounded,
                  label: s.budgetAlerts,
                  detail: s.budgetAlertsDetail,
                  enabled: on,
                  value: settings.budgetAlerts,
                  onChanged: (v) => update(settings.copyWith(budgetAlerts: v)),
                ),
              ],
            ),
            SettingsGroup(
              header: s.quietHours,
              footer: s.quietHoursFooter,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.dark_mode_rounded,
                  label: s.quietHours,
                  enabled: on,
                  value: settings.quietHoursEnabled,
                  onChanged: (v) =>
                      update(settings.copyWith(quietHoursEnabled: v)),
                ),
                if (settings.quietHoursEnabled) ...[
                  SettingsRow(
                    icon: IOSIcons.access_time_rounded,
                    label: s.from,
                    value: _fmt(settings.quietHoursStart),
                    onTap: on
                        ? () => _pickTime(
                              context,
                              settings.quietHoursStart,
                              (m) =>
                                  update(settings.copyWith(quietHoursStart: m)),
                            )
                        : null,
                  ),
                  SettingsRow(
                    icon: IOSIcons.access_time_rounded,
                    label: s.to,
                    value: _fmt(settings.quietHoursEnd),
                    onTap: on
                        ? () => _pickTime(
                              context,
                              settings.quietHoursEnd,
                              (m) =>
                                  update(settings.copyWith(quietHoursEnd: m)),
                            )
                        : null,
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  static String _fmt(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Future<void> _pickTime(
    BuildContext context,
    int current,
    ValueChanged<int> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) onPicked(picked.hour * 60 + picked.minute);
  }
}
