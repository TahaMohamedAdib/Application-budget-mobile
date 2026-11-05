import '../widgets/app_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/settings.dart';
import '../providers/app_provider.dart';
import '../widgets/unsynced_work_guard.dart';
import '../services/auth_service.dart';
import '../services/supabase_sync_service.dart';
import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';
import '../utils/money_format.dart';
import '../widgets/settings_ui.dart';
import '../widgets/stored_image.dart';
import 'account_screen.dart';
import 'onboarding/app_tour_screen.dart';
import 'settings/about_screen.dart';
import 'settings/appearance_screen.dart';
import 'settings/currency_format_screen.dart';
import 'settings/data_storage_screen.dart';
import 'settings/help_support_screen.dart';
import 'settings/language_screen.dart';
import 'settings/income_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/security_screen.dart';

/// Settings hub. Each row is a doorway to a focused screen rather than an
/// compact editor sheet, with room to explain each preference.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Selecting a record rather than watching the whole provider keeps the
    // hub from rebuilding on every transaction, while still reacting when the
    // income summary shown on the Income row changes.
    return Selector<AppProvider, ({Settings settings, double monthlyIncome})>(
      selector: (_, p) =>
          (settings: p.settings, monthlyIncome: p.monthlyIncomeFromSalaries),
      builder: (context, selected, _) {
        final settings = selected.settings;
        return SettingsScaffold(
          title: s.settings,
          children: [
            const _ProfileCard(),
            SettingsGroup(
              header: s.preferences,
              children: [
                SettingsRow(
                  icon: IOSIcons.light_mode_rounded,
                  label: s.appearance,
                  value: _themeLabel(s, settings.themeMode),
                  onTap: () => _open(context, const AppearanceScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.attach_money_rounded,
                  label: s.currencyAndFormat,
                  value: settings.currency,
                  onTap: () => _open(context, const CurrencyFormatScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.language_rounded,
                  label: s.language,
                  value: S.displayNameForLocale(settings.locale),
                  onTap: () => _open(context, const LanguageScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.payments_rounded,
                  label: s.incomeSettings,
                  value: selected.monthlyIncome > 0
                      ? MoneyFormat.of(settings).format(selected.monthlyIncome)
                      : s.incomeNoSalary,
                  onTap: () => _open(context, const IncomeScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.notifications_rounded,
                  label: s.notifications,
                  value: (settings.notificationsEnabled ?? true) ? s.on : s.off,
                  onTap: () => _open(context, const NotificationsScreen()),
                ),
              ],
            ),
            SettingsGroup(
              header: s.privacyAndData,
              children: [
                SettingsRow(
                  icon: IOSIcons.lock_rounded,
                  label: s.securityAndPrivacy,
                  value: settings.appLockEnabled ? s.locked : null,
                  onTap: () => _open(context, const SecurityScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.account_balance_wallet_rounded,
                  label: s.dataAndStorage,
                  onTap: () => _open(context, const DataStorageScreen()),
                ),
              ],
            ),
            SettingsGroup(
              header: s.support,
              children: [
                SettingsRow(
                  icon: IOSIcons.auto_awesome_rounded,
                  label: s.tourReplay,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (ctx) =>
                          AppTourScreen(onDone: () => Navigator.pop(ctx)),
                    ),
                  ),
                ),
                SettingsRow(
                  icon: IOSIcons.help_outline_rounded,
                  label: s.helpAndSupport,
                  onTap: () =>
                      _open(context, const HelpSupportScreen(), asSheet: false),
                ),
                SettingsRow(
                  icon: IOSIcons.info_outline_rounded,
                  label: s.about,
                  onTap: () =>
                      _open(context, const AboutScreen(), asSheet: false),
                ),
              ],
            ),
            SettingsGroup(
              children: [
                SettingsActionRow(
                  icon: IOSIcons.logout_rounded,
                  label: s.logOut,
                  destructive: true,
                  onTap: () => _logOut(context),
                ),
              ],
            ),
            Center(
              child: Text(
                'VVollet ${AboutScreen.appVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }

  static void _open(BuildContext context, Widget screen,
      {bool asSheet = true}) {
    if (asSheet) {
      showAppFormSheet(context: context, builder: (_) => screen);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  static String _themeLabel(S s, String mode) => switch (mode) {
        'light' => s.light,
        'dark' => s.dark,
        _ => s.system,
      };

  static Future<void> _logOut(BuildContext context) async {
    final s = S.of(context);
    final confirmed = await showSettingsConfirm(
      context,
      title: s.logOutConfirm,
      message: s.logOutDesc,
      confirmLabel: s.logOut,
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final provider = context.read<AppProvider>();

    // Signing out wipes the local database, so anything still queued would be
    // destroyed with it. Warn before that happens, not after.
    if (!await UnsyncedWorkGuard.confirm(context, provider)) return;
    if (!context.mounted) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.signOut();
    provider.clearData();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

/// Identity card at the top of the hub — who you're signed in as, and the
/// headline numbers the rest of settings applies to.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final auth = context.watch<AuthService>();
    final provider = context.watch<AppProvider>();

    final email = auth.user?.email;
    final displayName =
        (auth.user?.userMetadata?['display_name'] as String?)?.trim();
    final name = (displayName?.isNotEmpty ?? false)
        ? displayName!
        : (email?.split('@').first ?? s.user);

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ),
        child: GlassPanel(
          elevated: true,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              _Avatar(
                initial: initial,
                avatarPath: provider.settings.avatarPath,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? s.localMode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 22,
                height: 36,
                child: Center(
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      IOSIcons.chevron_right_rounded,
                      size: 19,
                      color: AppTheme.adaptiveIcon(context, alpha: 0.62),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.avatarPath});

  final String initial;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold300, AppTheme.gold700],
        ),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
      ),
    );

    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarPath == null || avatarPath!.isEmpty
            ? fallback
            : StoredImage(
                reference: avatarPath,
                bucket: SupabaseSyncService.avatarsBucket,
                width: 62,
                height: 62,
                borderRadius: BorderRadius.circular(31),
                errorWidget: fallback,
              ),
      ),
    );
  }
}
