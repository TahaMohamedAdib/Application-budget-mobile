import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/models/settings.dart';
import 'package:safespend_flutter/utils/money_format.dart';

/// [MoneyFormat] is the only path from a number to text on screen, so a
/// mistake here is visible on every surface at once — and the masking branch
/// is a privacy control, where "mostly right" is not a passing grade.

Settings settings({
  String currency = 'USD',
  bool hide = false,
  int decimals = 2,
  bool compact = false,
}) =>
    Settings(
      currency: currency,
      hideAmounts: hide,
      decimalPlaces: decimals,
      compactNumbers: compact,
    );

void main() {
  group('plain formatting', () {
    test('groups thousands and appends the symbol', () {
      expect(MoneyFormat.of(settings()).format(8500), '8,500.00 \$');
    });

    test('uses the currency the settings name', () {
      expect(
          MoneyFormat.of(settings(currency: 'MAD')).format(550), '550.00 MAD');
    });

    test('honours a zero-decimal preference', () {
      expect(MoneyFormat.of(settings(decimals: 0)).format(1234.56), '1,235 \$');
    });

    test('yen never shows a fractional part, whatever the preference', () {
      // Writing ¥1,000.00 is wrong in a way a global decimals setting
      // should not be able to cause.
      expect(MoneyFormat.of(settings(currency: 'JPY')).format(1000), '1,000 ¥');
    });

    test('negatives keep their sign', () {
      expect(MoneyFormat.of(settings()).format(-42), '-42.00 \$');
    });

    test('zero formats normally', () {
      expect(MoneyFormat.of(settings()).format(0), '0.00 \$');
    });
  });

  group('hiding', () {
    test('masks the amount', () {
      expect(
          MoneyFormat.of(settings(hide: true)).format(8500), MoneyFormat.mask);
    });

    test('the mask does not leak magnitude', () {
      final f = MoneyFormat.of(settings(hide: true));
      // Every value must render identically — a mask that grew with the
      // number would give away the order of magnitude.
      expect(f.format(1), f.format(9999999));
      expect(f.format(0), f.format(1250000));
    });

    test('the mask does not leak the sign', () {
      final f = MoneyFormat.of(settings(hide: true));
      expect(f.format(-500), f.format(500));
    });

    test('the mask does not leak the currency', () {
      expect(
        MoneyFormat.of(settings(hide: true, currency: 'MAD')).format(1),
        MoneyFormat.of(settings(hide: true, currency: 'JPY')).format(1),
      );
    });

    test('hiding overrides compact and decimal preferences', () {
      final f = MoneyFormat.of(
        settings(hide: true, compact: true, decimals: 0),
      );
      expect(f.format(12400), MoneyFormat.mask);
    });

    test('the visible constructor ignores the hide setting', () {
      // For the one place the user has asked to see the number.
      expect(
        MoneyFormat.visible(settings(hide: true)).format(8500),
        '8,500.00 \$',
      );
    });

    test('exposes whether it is hiding, so callers can drop signs', () {
      expect(MoneyFormat.of(settings(hide: true)).hidden, isTrue);
      expect(MoneyFormat.of(settings()).hidden, isFalse);
    });
  });

  group('signed amounts', () {
    test('adds an explicit plus or minus when visible', () {
      final f = MoneyFormat.of(settings());
      expect(f.signed(50, positive: true), '+50.00 \$');
      expect(f.signed(50, positive: false), '-50.00 \$');
    });

    test('infers the sign from the value when not told', () {
      final f = MoneyFormat.of(settings());
      expect(f.signed(-50), '-50.00 \$');
      expect(f.signed(50), '+50.00 \$');
    });

    test('a hidden signed amount keeps no sign at all', () {
      // A lone "+" or "-" beside the dots still says which way money moved.
      final f = MoneyFormat.of(settings(hide: true));
      expect(f.signed(50, positive: true), MoneyFormat.mask);
      expect(f.signed(50, positive: false), MoneyFormat.mask);
      expect(f.signed(50, positive: true), f.signed(50, positive: false));
    });

    test('negativeSigned omits a redundant plus', () {
      final f = MoneyFormat.of(settings());
      expect(f.negativeSigned(1200), '1,200.00 \$');
      expect(f.negativeSigned(-1200), '-1,200.00 \$');
    });

    test('a hidden negativeSigned cannot reveal being underwater', () {
      final f = MoneyFormat.of(settings(hide: true));
      expect(f.negativeSigned(-1200), MoneyFormat.mask);
      expect(f.negativeSigned(-1200), f.negativeSigned(1200));
    });
  });

  group('compact', () {
    MoneyFormat compact({String currency = 'USD'}) =>
        MoneyFormat.of(settings(currency: currency, compact: true));

    test('thousands become K', () {
      expect(compact().format(12400), '12.4K \$');
    });

    test('a round thousand drops the pointless decimal', () {
      expect(compact().format(12000), '12K \$');
    });

    test('millions and billions get their own units', () {
      expect(compact().format(2500000), '2.5M \$');
      expect(compact().format(3000000000), '3B \$');
    });

    test('large values within a unit drop to whole numbers', () {
      expect(compact().format(125000), '125K \$');
    });

    test('below a thousand stays plain', () {
      expect(compact().format(750), '750 \$');
    });

    test('negatives keep their sign when compacted', () {
      expect(compact().format(-12400), '-12.4K \$');
    });
  });
}
