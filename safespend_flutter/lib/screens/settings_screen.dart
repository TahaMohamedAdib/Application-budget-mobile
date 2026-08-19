import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/settings.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';
import '../utils/money_format.dart';
import '../widgets/settings_ui.dart';
import 'account_screen.dart';
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
/// inline dialog, so every preference has room to explain itself.
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
                  detail: s.appearanceDetail,
                  value: _themeLabel(s, settings.themeMode),
                  onTap: () => _open(context, const AppearanceScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.attach_money_rounded,
                  label: s.currencyAndFormat,
                  detail: s.currencyAndFormatDetail,
                  value: settings.currency,
                  onTap: () => _open(context, const CurrencyFormatScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.language_rounded,
                  label: s.language,
                  detail: s.languageDetail,
                  value: S.displayNameForLocale(settings.locale),
                  onTap: () => _open(context, const LanguageScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.payments_rounded,
                  label: s.incomeSettings,
                  detail: s.incomeSettingsDetail,
                  value: selected.monthlyIncome > 0
                      ? MoneyFormat.of(settings).format(selected.monthlyIncome)
                      : s.incomeNoSalary,
                  onTap: () => _open(context, const IncomeScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.notifications_rounded,
                  label: s.notifications,
                  detail: s.notificationsDetail,
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
                  detail: s.securityAndPrivacyDetail,
                  value: settings.appLockEnabled ? s.locked : null,
                  onTap: () => _open(context, const SecurityScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.account_balance_wallet_rounded,
                  label: s.dataAndStorage,
                  detail: s.dataAndStorageDetail,
                  onTap: () => _open(context, const DataStorageScreen()),
                ),
              ],
            ),
            SettingsGroup(
              header: s.support,
              children: [
                SettingsRow(
                  icon: IOSIcons.help_outline_rounded,
                  label: s.helpAndSupport,
                  detail: s.helpAndSupportDetail,
                  onTap: () => _open(context, const HelpSupportScreen()),
                ),
                SettingsRow(
                  icon: IOSIcons.info_outline_rounded,
                  label: s.about,
                  detail: s.aboutDetail,
                  onTap: () => _open(context, const AboutScreen()),
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
                'SafeSpend ${AboutScreen.appVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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

    final auth = Provider.of<AuthService>(context, listen: false);
    final provider = context.read<AppProvider>();
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
      padding: const EdgeInsets.only(bottom: 22),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ),
        child: GlassPanel(
          elevated: true,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              _Avatar(initial: initial),
              const SizedBox(width: 15),
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
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? s.localMode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Built by hand this printed an unseparated figure with
                      // the symbol jammed against it — and ignored the hide
                      // setting, leaving net worth legible on the one screen
                      // you open to turn hiding on.
                      '${provider.accounts.length} ${s.accounts.toLowerCase()} · '
                      '${MoneyFormat.of(provider.settings).negativeSigned(provider.getNetWorth())} '
                      '${s.netWorth.toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(IOSIcons.chevron_right_rounded,
                  size: 19, color: AppTheme.adaptiveIcon(context, alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.05),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
      ),
    );
  }
}
