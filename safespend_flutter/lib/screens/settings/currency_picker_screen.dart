import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../utils/currency_helper.dart';
import '../../widgets/settings_ui.dart';

/// Searchable currency list, grouped by region.
class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({super.key});

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const _sections = <String, List<String>>{
    'Popular': ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY'],
    'Africa': [
      'MAD', 'ZAR', 'NGN', 'KES', 'GHS', 'TZS', 'UGX', 'ETB', //
      'TND', 'DZD', 'XOF', 'XAF', 'RWF',
    ],
    'Middle East': [
      'AED', 'SAR', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'ILS', //
      'EGP', 'LBP', 'IQD', 'IRR',
    ],
    'Americas': [
      'BRL', 'MXN', 'ARS', 'CLP', 'COP', 'PEN', 'UYU', 'DOP', //
      'JMD', 'TTD', 'NZD',
    ],
    'Europe': [
      'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON', 'BGN', //
      'HRK', 'ISK', 'RUB', 'UAH', 'TRY', 'GEL',
    ],
    'Asia & Pacific': [
      'INR', 'PKR', 'BDT', 'LKR', 'NPR', 'KRW', 'HKD', 'SGD', //
      'TWD', 'THB', 'VND', 'MYR', 'IDR', 'PHP', 'MMK', 'KHR',
    ],
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String code) {
    if (_query.isEmpty) return true;
    return code.toLowerCase().contains(_query) ||
        CurrencyHelper.getName(code).toLowerCase().contains(_query) ||
        CurrencyHelper.getSymbol(code).toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<AppProvider>();
    final current = provider.settings.currency;

    final groups = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: GlassPanel(
          radius: 16,
          child: TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: s.searchCurrency,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              prefixIcon: Icon(IOSIcons.search_rounded,
                  size: 18, color: AppTheme.adaptiveIcon(context)),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(IOSIcons.clear_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
      ),
    ];

    for (final entry in _sections.entries) {
      final codes = entry.value.where(_matches).toList();
      if (codes.isEmpty) continue;

      groups.add(SettingsGroup(
        header: entry.key,
        children: codes.map((code) {
          return SettingsChoiceRow(
            label: CurrencyHelper.getName(code),
            detail: code,
            selected: code == current,
            leading: _SymbolTile(
              symbol: CurrencyHelper.getSymbol(code),
              selected: code == current,
            ),
            onTap: () {
              context
                  .read<AppProvider>()
                  .updateSettings(provider.settings.copyWith(currency: code));
              Navigator.of(context).maybePop();
            },
          );
        }).toList(),
      ));
    }

    if (groups.length == 1) {
      groups.add(Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(s.noCurrenciesFound,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ));
    }

    return SettingsScaffold(
      title: s.selectCurrency,
      children: groups,
    );
  }
}

class _SymbolTile extends StatelessWidget {
  const _SymbolTile({required this.symbol, required this.selected});

  final String symbol;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        symbol,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
