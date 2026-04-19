import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/settings.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_helper.dart';
import '../l10n/app_localizations.dart';
import 'account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Selector<AppProvider, Settings>(
      selector: (_, p) => p.settings,
      builder: (context, settings, _) {
        final provider = context.read<AppProvider>();
        final isDark = settings.isDarkMode;
        final s = S.of(context);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.arrow_back_rounded, size: 22,
                              color: isDarkTheme ? Colors.white : Colors.black),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(s.settings, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ).animate().fadeIn(duration: 260.ms, curve: Curves.easeOut).slideY(begin: -0.05, end: 0, curve: Curves.easeOut),

                // Content
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    children: [
                      // Appearance
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.premiumCard(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.appearance, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildThemeOption(context, icon: Icons.light_mode_rounded, label: s.light, isSelected: settings.themeMode == 'light', onTap: () => provider.setThemeMode('light')),
                                const SizedBox(width: 10),
                                _buildThemeOption(context, icon: Icons.dark_mode_rounded, label: s.dark, isSelected: settings.themeMode == 'dark', onTap: () => provider.setThemeMode('dark')),
                                const SizedBox(width: 10),
                                _buildThemeOption(context, icon: Icons.smartphone_rounded, label: s.system, isSelected: settings.themeMode == 'system', onTap: () => provider.setThemeMode('system')),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 280.ms, delay: 80.ms, curve: Curves.easeOut),

                      const SizedBox(height: 16),

                      // Currency
                      GestureDetector(
                        onTap: () => _showCurrencyPicker(context, provider),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.premiumCard(context),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(child: Text('💱', style: TextStyle(fontSize: 20))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.currency, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${CurrencyHelper.getSymbol(provider.settings.currency)} · ${provider.settings.currency} · ${CurrencyHelper.getName(provider.settings.currency)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

                      const SizedBox(height: 16),

                      // Language
                      GestureDetector(
                        onTap: () => _showLanguagePicker(context, provider),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.premiumCard(context),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    S.flagForLocale(settings.locale),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.language, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(S.displayNameForLocale(settings.locale), style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 170.ms),

                      const SizedBox(height: 16),

                      // Menu Items
                      Container(
                        decoration: AppTheme.premiumCard(context),
                        child: Column(
                          children: [
                            _buildMenuItem(context, icon: Icons.person_rounded, label: s.account, onTap: () => _showAccountDialog(context)),
                            Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                            _buildMenuItem(context, icon: Icons.notifications_rounded, label: s.notifications, onTap: () => _showNotificationsDialog(context, provider)),
                            Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                            _buildMenuItem(context, icon: Icons.shield_rounded, label: s.privacy, onTap: () => _showPrivacyDialog(context)),
                            Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                            _buildMenuItem(context, icon: Icons.help_outline_rounded, label: s.helpAndSupport, onTap: () => _showHelpDialog(context)),
                          ],
                        ),
                      ).animate().fadeIn(duration: 280.ms, delay: 120.ms, curve: Curves.easeOut),

                      const SizedBox(height: 16),

                      // Log Out
                      GestureDetector(
                        onTap: () => _confirmLogOut(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: AppTheme.premiumCard(context),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                              const SizedBox(width: 14),
                              Text(s.logOut, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error, fontSize: 15)),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 280.ms, delay: 160.ms, curve: Curves.easeOut),

                      const SizedBox(height: 32),

                      Center(
                        child: Text(s.version, style: Theme.of(context).textTheme.bodySmall),
                      ).animate().fadeIn(duration: 280.ms, delay: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(
        currentCurrency: provider.settings.currency,
        onSelect: (code) {
          provider.updateSettings(provider.settings.copyWith(currency: code));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, {required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary.withOpacity(isDark ? 0.2 : 0.1) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? AppTheme.goldPrimary : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? AppTheme.goldPrimary : Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.goldPrimary : Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }

  void _showAccountDialog(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
  }

  void _showNotificationsDialog(BuildContext context, AppProvider provider) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.notifications_rounded, color: AppTheme.goldPrimary),
            const SizedBox(width: 10),
            Text(s.notifications, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: provider.settings.notificationsEnabled ?? true,
                onChanged: (v) {
                  provider.updateSettings(provider.settings.copyWith(notificationsEnabled: v));
                  setS(() {});
                },
                title: Text(s.pushNotifications),
                subtitle: Text(s.remindersForBills),
                activeColor: AppTheme.goldPrimary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.done))],
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.shield_rounded, color: AppTheme.goldPrimary),
          const SizedBox(width: 10),
          Text(s.privacy, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(s.privacyDesc, style: const TextStyle(height: 1.5, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.gotIt))],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.help_outline_rounded, color: AppTheme.goldPrimary),
          const SizedBox(width: 10),
          Text(s.helpAndSupport, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpItem(q: s.helpQ1, a: s.helpA1),
            const SizedBox(height: 12),
            _HelpItem(q: s.helpQ2, a: s.helpA2),
            const SizedBox(height: 12),
            _HelpItem(q: s.helpQ3, a: s.helpA3),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.close))],
      ),
    );
  }

  void _confirmLogOut(BuildContext context, AppProvider provider) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.logOutConfirm, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(s.logOutDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthService>(context, listen: false);
              await auth.signOut();
              provider.clearData();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(s.logOut),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppProvider provider) {
    final s = S.of(context);
    final currentLocale = S.normalizeLocaleCode(provider.settings.locale);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(s.selectLanguage, style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  children: S.localeDisplayNames.entries.map((entry) {
                    final code = entry.key;
                    final name = entry.value;
                    final flag = S.flagForLocale(code);
                    final isSelected = code == currentLocale;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        provider.setLocale(code);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.goldPrimary.withOpacity(isDark ? 0.15 : 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected ? Border.all(color: AppTheme.goldPrimary, width: 1.5) : null,
                        ),
                        child: Row(
                          children: [
                            Text(flag, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppTheme.goldPrimary : null)),
                                  Text(code.toUpperCase(), style: Theme.of(ctx).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppTheme.goldPrimary, size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String q;
  final String a;
  const _HelpItem({required this.q, required this.a});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 3),
      Text(a, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
    ]);
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onSelect;
  const _CurrencyPickerSheet({required this.currentCurrency, required this.onSelect});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _sections = {
    'Popular': ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY'],
    'Americas': ['BRL', 'MXN', 'ARS', 'CLP', 'COP', 'PEN', 'UYU', 'DOP', 'JMD', 'TTD', 'NZD'],
    'Europe': ['SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON', 'BGN', 'HRK', 'ISK', 'RUB', 'UAH', 'TRY', 'GEL'],
    'Asia & Pacific': ['INR', 'PKR', 'BDT', 'LKR', 'NPR', 'KRW', 'HKD', 'SGD', 'TWD', 'THB', 'VND', 'MYR', 'IDR', 'PHP', 'MMK', 'KHR'],
    'Middle East': ['AED', 'SAR', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'ILS', 'EGP', 'LBP', 'IQD', 'IRR'],
    'Africa': ['ZAR', 'NGN', 'KES', 'GHS', 'TZS', 'UGX', 'ETB', 'MAD', 'TND', 'DZD', 'XOF', 'XAF', 'RWF'],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(s.selectCurrency, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: s.searchCurrency,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(Icons.search_rounded, size: 18,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchController.clear(); setState(() => _query = ''); }) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Currency list
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              children: _buildSections(isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(bool isDark) {
    final widgets = <Widget>[];
    final s = S.of(context);

    for (final entry in _sections.entries) {
      final sectionName = entry.key;
      final codes = entry.value.where((code) {
        if (_query.isEmpty) return true;
        final name = CurrencyHelper.getName(code).toLowerCase();
        final symbol = CurrencyHelper.getSymbol(code).toLowerCase();
        return code.toLowerCase().contains(_query) || name.contains(_query) || symbol.contains(_query);
      }).toList();

      if (codes.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(sectionName, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ));

      widgets.add(Container(
        decoration: AppTheme.premiumCard(context),
        child: Column(
          children: codes.asMap().entries.map((e) {
            final code = e.value;
            final isLast = e.key == codes.length - 1;
            final isSelected = code == widget.currentCurrency;
            final symbol = CurrencyHelper.getSymbol(code);
            final name = CurrencyHelper.getName(code);

            return Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSelect(code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.goldPrimary.withOpacity(0.12) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(symbol, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? AppTheme.goldPrimary : Theme.of(context).textTheme.bodyMedium?.color))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: isSelected ? AppTheme.goldPrimary : null)),
                              Text(code, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppTheme.goldPrimary, size: 22),
                      ],
                    ),
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 68, color: Theme.of(context).dividerColor),
              ],
            );
          }).toList(),
        ),
      ));
    }

    if (widgets.isEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(child: Text(s.noCurrenciesFound, style: Theme.of(context).textTheme.bodySmall)),
      ));
    }

    return widgets;
  }
}
