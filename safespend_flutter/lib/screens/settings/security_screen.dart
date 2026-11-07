import '../../widgets/app_form_sheet.dart';
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
      final created = await showAppFormSheet<bool>(
          context: context,
          builder: (_) => const PinEntryScreen(mode: PinMode.create));
      if (created == true) update(settings.copyWith(appLockEnabled: true));
      return;
    }

    // Turning the lock off must still cost the PIN — otherwise anyone holding
    // the unlocked phone can simply switch it off.
    final verified = await showAppFormSheet<bool>(
        context: context,
        builder: (_) => const PinEntryScreen(mode: PinMode.verify));
    if (verified == true) {
      await AppLockService.instance.clearPin();
      update(settings.copyWith(appLockEnabled: false));
    }
  }

  static Future<void> _changePin(BuildContext context) async {
    final verified = await showAppFormSheet<bool>(
        context: context,
        builder: (_) => const PinEntryScreen(mode: PinMode.verify));
    if (verified != true || !context.mounted) return;

    final changed = await showAppFormSheet<bool>(
        context: context,
        builder: (_) => const PinEntryScreen(mode: PinMode.create));
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
    await showAppFormSheet<void>(
      context: context,
      builder: (ctx) => AppFormSheet(
        header: Text(s.autoLock, style: Theme.of(ctx).textTheme.titleLarge),
        body: Column(children: [
          for (final m in const [0, 1, 5, 15, 60])
            SettingsChoiceRow(
              label: _autoLockLabel(s, m),
              selected: settings.autoLockMinutes == m,
              onTap: () {
                update(settings.copyWith(autoLockMinutes: m));
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  static void _showPolicy(BuildContext context) {
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s.privacyPolicy),
        content: SingleChildScrollView(
          child: Text(s.privacyDesc),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.gotIt)),
        ],
      ),
    );
  }
}
