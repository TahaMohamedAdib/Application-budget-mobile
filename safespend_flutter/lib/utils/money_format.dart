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
    required this.locale,
  });

  factory MoneyFormat.of(Settings settings) => MoneyFormat._(
        currency: settings.currency,
        hidden: settings.hideAmounts,
        decimalPlaces: settings.decimalPlaces,
        compact: settings.compactNumbers,
        locale: settings.locale,
      );

  /// Always shows the figure, whatever the hide setting says. For the one
  /// place the user has explicitly asked to see a value — a reveal tap, or a
  /// field they are editing.
  factory MoneyFormat.visible(Settings settings) => MoneyFormat._(
        currency: settings.currency,
        hidden: false,
        decimalPlaces: settings.decimalPlaces,
        compact: settings.compactNumbers,
        locale: settings.locale,
      );

  final String currency;
  final String locale;
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

  String format(num value) => hidden ? mask : '${number(value)} $symbol';

  /// Numeric part for layouts that give the currency its own visual hierarchy.
  String number(num value, {bool? compactOverride}) {
    if (hidden) return mask;
    final amount = value.toDouble();
    if (!amount.isFinite) return '—';
    if (compactOverride ?? compact) {
      return locale == 'en'
          ? _compact(amount)
          : NumberFormat.compact(locale: locale).format(amount);
    }
    // Past six figures the cents are noise: nobody reads the .00 on a
    // 2,498,865 balance, and those three glyphs are exactly what force a
    // hero figure to shrink. Small amounts keep them, where they matter.
    const centsCeiling = 100000;
    final decimals = amount.abs() >= centsCeiling ? 0 : _decimals;
    final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
    return NumberFormat(pattern, locale).format(amount);
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

  /// Largest compact unit. A value that rounds past this stays in trillions
  /// rather than gaining a unit no reader would recognise.
  static const _compactCeiling = 1000000000000;

  /// 12,400 → 12.4K. Keeps one decimal only when it adds information, so
  /// 12,000 reads as 12K rather than 12.0K. Runs to trillions, because a
  /// balance held in a low-denomination currency reaches 10^12 without being
  /// an unusual amount of money.
  String _compact(double value) {
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();

    const units = [
      (_compactCeiling, 'T'),
      (1000000000, 'B'),
      (1000000, 'M'),
      (1000, 'K'),
    ];

    for (final (threshold, suffix) in units) {
      if (abs < threshold) continue;

      // Rounding can carry a value into the unit above: 999,950 would read
      // "1000K" where "1M" is meant. Promote before choosing the suffix, so
      // the carry happens once and the top unit simply keeps its digits.
      var unit = threshold;
      var label = suffix;
      if (abs / unit >= 999.95 && unit != _compactCeiling) {
        final promoted = units.lastWhere((u) => u.$1 > unit);
        unit = promoted.$1;
        label = promoted.$2;
      }

      // Round to the precision actually shown before deciding whether the
      // decimal earns its place. Testing the raw quotient instead lets float
      // error through: 999,950 promotes to 0.99995T, which is not a whole
      // number, so it printed "1.0T" where the rounded value is plainly "1T".
      final scaled = (abs / unit * 10).round() / 10;
      // One decimal only when it adds information: 12,000 reads "12K", not
      // "12.0K". Past 100 of a unit the decimal is noise on a hero figure.
      final text = scaled >= 100 || scaled.roundToDouble() == scaled
          ? scaled.round().toString()
          : scaled.toStringAsFixed(1);
      return '$sign$text$label';
    }
    return sign + NumberFormat('#,##0', 'en_US').format(abs);
  }
}
