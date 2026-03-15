import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isDark = provider.settings.isDarkMode;

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
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDarkTheme ? AppTheme.darkSurface : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDarkTheme ? [] : AppTheme.cardShadowLight,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

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
                            Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildThemeOption(context, icon: Icons.light_mode_rounded, label: 'Light', isSelected: !isDark, onTap: () { if (isDark) provider.toggleTheme(); }),
                                const SizedBox(width: 10),
                                _buildThemeOption(context, icon: Icons.dark_mode_rounded, label: 'Dark', isSelected: isDark, onTap: () { if (!isDark) provider.toggleTheme(); }),
                                const SizedBox(width: 10),
                                _buildThemeOption(context, icon: Icons.smartphone_rounded, label: 'System', isSelected: false, onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System theme coming soon'))); }),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

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
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(child: Text('💱', style: TextStyle(fontSize: 20))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Currency', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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

                      // Menu Items
                      Container(
                        decoration: AppTheme.premiumCard(context),
                        child: Column(
                          children: [
                            _buildMenuItem(context, icon: Icons.person_rounded, label: 'Account'),
                            Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                            _buildMenuItem(context, icon: Icons.notifications_rounded, label: 'Notifications'),
                            Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                            _buildMenuItem(context, icon: Icons.shield_rounded, label: 'Privacy'),
                            Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                            _buildMenuItem(context, icon: Icons.help_outline_rounded, label: 'Help & Support'),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      // Log Out
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout coming soon'))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: AppTheme.premiumCard(context),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                              const SizedBox(width: 14),
                              Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error, fontSize: 15)),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                      const SizedBox(height: 32),

                      Center(
                        child: Text('SafeSpend v1.0.0', style: Theme.of(context).textTheme.bodySmall),
                      ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
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

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label}) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label coming soon!'))),
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Select Currency', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
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
                    hintText: 'Search currency...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
        child: Center(child: Text('No currencies found', style: Theme.of(context).textTheme.bodySmall)),
      ));
    }

    return widgets;
  }
}
