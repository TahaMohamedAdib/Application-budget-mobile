import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/settings.dart';
import '../../providers/app_provider.dart';
import '../../services/app_lock_service.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/settings_ui.dart';
import '../account_screen.dart';
import 'pin_entry_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Selector<AppProvider, Settings>(
      selector: (_, p) => p.settings,
      builder: (context, settings, _) {
        final provider = context.read<AppProvider>();
        void update(Settings next) => provider.updateSettings(next);

        return SettingsScaffold(
          title: s.securityAndPrivacy,
          subtitle: s.securityAndPrivacySubtitle,
          children: [
            SettingsGroup(
              header: s.appLock,
              footer: s.appLockFooter,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.lock_rounded,
                  label: s.appLock,
                  detail: s.appLockDetail,
                  value: settings.appLockEnabled,
                  onChanged: (v) => _toggleLock(context, settings, v, update),
                ),
                if (settings.appLockEnabled) ...[
                  SettingsRow(
                    icon: IOSIcons.numbers,
                    label: s.changePin,
                    onTap: () => _changePin(context),
                  ),
                  SettingsRow(
                    icon: IOSIcons.access_time_rounded,
                    label: s.autoLock,
                    value: _autoLockLabel(s, settings.autoLockMinutes),
                    onTap: () => _pickAutoLock(context, settings, update),
                  ),
                ],
              ],
            ),

            SettingsGroup(
              header: s.privacy,
              footer: s.maskOnAppSwitchFooter,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.visibility_off_rounded,
                  label: s.maskOnAppSwitch,
                  detail: s.maskOnAppSwitchDetail,
                  value: settings.maskOnAppSwitch,
                  onChanged: (v) =>
                      update(settings.copyWith(maskOnAppSwitch: v)),
                ),
              ],
            ),

            SettingsGroup(
              header: s.account,
              children: [
                SettingsRow(
                  icon: IOSIcons.lock_outline_rounded,
                  label: s.changePassword,
                  detail: s.changePasswordDetail,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                ),
              ],
            ),

            SettingsGroup(
              header: s.diagnostics,
              footer: s.diagnosticsFooter,
              children: [
                SettingsSwitchRow(
                  icon: IOSIcons.pie_chart_outline_rounded,
                  label: s.usageAnalytics,
                  detail: s.usageAnalyticsDetail,
                  value: settings.analyticsEnabled,
                  onChanged: (v) =>
                      update(settings.copyWith(analyticsEnabled: v)),
                ),
                SettingsSwitchRow(
                  icon: IOSIcons.error_outline_rounded,
                  label: s.crashReports,
                  detail: s.crashReportsDetail,
                  value: settings.crashReportsEnabled,
                  onChanged: (v) =>
                      update(settings.copyWith(crashReportsEnabled: v)),
                ),
              ],
            ),

            SettingsGroup(
              children: [
                SettingsRow(
                  icon: IOSIcons.shield_rounded,
                  label: s.privacyPolicy,
                  onTap: () => _showPolicy(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> _toggleLock(
    BuildContext context,
    Settings settings,
    bool enable,
    ValueChanged<Settings> update,
  ) async {
    if (enable) {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const PinEntryScreen(mode: PinMode.create),
          fullscreenDialog: true,
        ),
      );
      if (created == true) update(settings.copyWith(appLockEnabled: true));
      return;
    }

    // Turning the lock off must still cost the PIN — otherwise anyone holding
    // the unlocked phone can simply switch it off.
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinEntryScreen(mode: PinMode.verify),
        fullscreenDialog: true,
      ),
    );
    if (verified == true) {
      await AppLockService.instance.clearPin();
      update(settings.copyWith(appLockEnabled: false));
    }
  }

  static Future<void> _changePin(BuildContext context) async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinEntryScreen(mode: PinMode.verify),
        fullscreenDialog: true,
      ),
    );
    if (verified != true || !context.mounted) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinEntryScreen(mode: PinMode.create),
        fullscreenDialog: true,
      ),
    );
    if (changed == true && context.mounted) {
      showSettingsToast(context, S.of(context).pinUpdated);
    }
  }

  static String _autoLockLabel(S s, int minutes) {
    if (minutes <= 0) return s.immediately;
    if (minutes == 1) return s.afterOneMinute;
    return s.afterNMinutes(minutes);
  }

  static Future<void> _pickAutoLock(
    BuildContext context,
    Settings settings,
    ValueChanged<Settings> update,
  ) async {
    final s = S.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPanel(
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final m in const [0, 1, 5, 15, 60])
                  SettingsChoiceRow(
                    label: _autoLockLabel(s, m),
                    selected: settings.autoLockMinutes == m,
                    onTap: () {
                      update(settings.copyWith(autoLockMinutes: m));
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showPolicy(BuildContext context) {
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s.privacyPolicy,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: SingleChildScrollView(
          child: Text(s.privacyDesc,
              style: const TextStyle(height: 1.5, fontSize: 13)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.gotIt)),
        ],
      ),
    );
  }
}
