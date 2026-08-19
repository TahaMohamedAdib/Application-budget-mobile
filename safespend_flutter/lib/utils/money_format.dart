import 'package:intl/intl.dart';

import '../models/settings.dart';
import 'currency_helper.dart';

/// The single place a money value becomes text.
///
/// Screens used to build a bare [NumberFormat] each, straight from the
/// currency code. That left three settings inert — `hideAmounts`,
/// `decimalPlaces` and `compactNumbers` were all stored, all shown as
/// switches, and none of them reached a single figure on screen.
///
/// Routing every amount through one formatter is what makes hiding
/// trustworthy: a privacy control that masks the balance card but leaves the
/// same number legible in a transaction row two screens away is worse than no
/// control at all, because it invites the user to rely on it.
///
/// Drop-in for the [NumberFormat] it replaced — [format] is the only method
/// the app ever called.
class MoneyFormat {
  const MoneyFormat._({
    required this.currency,
    required this.hidden,
    required this.decimalPlaces,
    required this.compact,
  });

  factory MoneyFormat.of(Settings settings) => MoneyFormat._(
        currency: settings.currency,
        hidden: settings.hideAmounts,
        decimalPlaces: settings.decimalPlaces,
        compact: settings.compactNumbers,
      );

  /// Always shows the figure, whatever the hide setting says. For the one
  /// place the user has explicitly asked to see a value — a reveal tap, or a
  /// field they are editing.
  factory MoneyFormat.visible(Settings settings) => MoneyFormat._(
        currency: settings.currency,
        hidden: false,
        decimalPlaces: settings.decimalPlaces,
        compact: settings.compactNumbers,
      );

  final String currency;
  final bool hidden;
  final int decimalPlaces;
  final bool compact;

  /// Fixed width regardless of the value. A mask whose length tracked the
  /// digits would leak the order of magnitude — the thing most worth hiding.
  static const mask = '••••';

  String get symbol => CurrencyHelper.getSymbol(currency);

  /// Currencies that are conventionally written without a fractional part;
  /// a "0.00" yen amount looks wrong to anyone who uses it.
  static const _noDecimalCurrencies = {
    'JPY', 'KRW', 'VND', 'IDR', 'HUF', 'CLP', 'ISK', //
    'UGX', 'KHR', 'MMK', 'RWF', 'XOF', 'XAF', 'IQD', 'IRR', 'LBP',
  };

  int get _decimals =>
      _noDecimalCurrencies.contains(currency) ? 0 : decimalPlaces;

  String format(num value) {
    if (hidden) return mask;

    final amount = value.toDouble();
    if (compact) return '${_compact(amount)} $symbol';

    final pattern = _decimals > 0 ? '#,##0.${'0' * _decimals}' : '#,##0';
    // The symbol is quoted so a currency written with letters (MAD, CHF) is
    // not read as number-format placeholders.
    final escaped = symbol.replaceAll("'", "''");
    return NumberFormat("$pattern '$escaped'", 'en_US').format(amount);
  }

  /// [value] with an explicit leading + or -, or the bare mask when hiding.
  ///
  /// Call sites used to build this themselves as `'+' + cf.format(x)`, which
  /// survives masking and leaves a lone "+" or "-" beside the dots — telling a
  /// bystander which way the money moved, and for a net-worth figure whether
  /// the user is underwater. Centralised so the next call site cannot get it
  /// wrong.
  String signed(num value, {bool? positive}) {
    if (hidden) return mask;
    final isPositive = positive ?? value >= 0;
    return '${isPositive ? '+' : '-'}${format(value.abs())}';
  }

  /// As [format], but only ever shows a minus — for totals where a leading
  /// plus would be noise. Still collapses to the mask when hiding.
  String negativeSigned(num value) {
    if (hidden) return mask;
    return value < 0 ? '-${format(value.abs())}' : format(value);
  }

  /// 12,400 → 12.4K. Keeps one decimal only when it adds information, so
  /// 12,000 reads as 12K rather than 12.0K.
  String _compact(double value) {
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();

    const units = [
      (1000000000, 'B'),
      (1000000, 'M'),
      (1000, 'K'),
    ];

    for (final (threshold, suffix) in units) {
      if (abs >= threshold) {
        final scaled = abs / threshold;
        final text = scaled >= 100 || scaled == scaled.roundToDouble()
            ? scaled.round().toString()
            : scaled.toStringAsFixed(1);
        return '$sign$text$suffix';
      }
    }
    return sign + NumberFormat('#,##0', 'en_US').format(abs);
  }
}
