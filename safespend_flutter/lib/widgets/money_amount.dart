import 'package:flutter/material.dart';

import '../utils/money_format.dart';

/// A money figure that fits its line without losing digits.
///
/// A balance is the one string on screen whose length the app does not
/// control: the user picks the currency, the decimal places and the compact
/// switch, and the value itself runs from "0.00" to thirteen digits. A fixed
/// font size therefore cannot be right for every value, and the failure mode
/// is the worst one Flutter has — the striped overflow banner across a card.
///
/// The order of concessions matters, because each one costs the reader
/// something different:
///
/// 1. Shrink the type, down to [minFontSize]. Costs nothing but size.
/// 2. Tighten the glyphs. Costs a little elegance, keeps every digit.
/// 3. Abbreviate to "2.5M". Costs precision, so it is the last resort — a
///    net worth of -2,498,865 shown as "-2.5M" hides 98,865 of real money.
///
/// Codex's first pass had these inverted: it jumped to abbreviation as soon
/// as the shrink hit the floor, so the hero on a 320px phone read "-2.5M"
/// while there was still room for the exact figure two points smaller.
///
/// The currency can sit beside the number or on a separate caption line.
///
/// Long press reveals the exact amount. Hidden balances stay masked in the
/// tooltip and in semantics, so the privacy control cannot be read around.
class MoneyAmount extends StatelessWidget {
  const MoneyAmount({
    super.key,
    required this.value,
    required this.formatter,
    this.fontSize = 32,
    this.minFontSize = 22,
    this.color,
    this.signed = false,
    this.alignEnd = false,
    this.allowCompact = true,
    this.currencyInline = false,
  });

  final num value;
  final MoneyFormat formatter;
  final double fontSize;
  final double minFontSize;
  final Color? color;

  /// Shows an explicit leading + on positive values. Negatives always carry
  /// their own minus from the formatter.
  final bool signed;

  final bool alignEnd;

  /// Whether abbreviating to "2.5M" is permitted as a last resort. Off for
  /// figures where a reader would reasonably compare exact digits.
  final bool allowCompact;

  /// Places the currency directly after the number. When false, the currency
  /// uses a caption line beneath the figure to preserve more width for digits.
  final bool currencyInline;

  /// The point below which a figure stops being readable at arm's length.
  /// [minFontSize] is the caller's preference and gives way to keeping the
  /// digits; this is the limit that does not.
  static const _legibilityFloor = 13.0;

  @override
  Widget build(BuildContext context) {
    String number({bool? compact}) {
      final text = formatter.number(value, compactOverride: compact);
      // The formatter supplies a minus for negatives; only the plus has to be
      // added here. Masked values take no sign at all, or a lone "+" beside
      // the dots would say which way the money went.
      return signed && value >= 0 && !formatter.hidden ? '+$text' : text;
    }

    String display({bool? compact}) {
      final valueText = number(compact: compact);
      return currencyInline && !formatter.hidden
          ? '$valueText ${formatter.symbol}'
          : valueText;
    }

    final exact = formatter.hidden
        ? MoneyFormat.mask
        : '${number(compact: false)} ${formatter.symbol}';
    final base = DefaultTextStyle.of(context).style.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: -0.4,
          height: 1.15,
          color: color,
        );

    return Semantics(
      label: exact,
      excludeSemantics: true,
      child: Tooltip(
        message: exact,
        child: LayoutBuilder(builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          double width(String text, double size) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: base.copyWith(fontSize: size)),
              textScaler: scaler,
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            final result = painter.width;
            painter.dispose();
            return result;
          }

          var text = display();
          var size = fontSize;
          if (constraints.hasBoundedWidth) {
            final available = constraints.maxWidth;

            // Text width is near-linear in font size, so the size that fits
            // is one ratio away and costs a single extra layout to find.
            double fittingSize(String candidate) {
              final natural = width(candidate, fontSize);
              if (natural <= available) return fontSize;
              return fontSize * available / natural;
            }

            final exactSize = fittingSize(text);
            if (exactSize >= minFontSize) {
              // Fits within the caller's preferred range. Nothing is lost.
              size = exactSize.clamp(minFontSize, fontSize);
            } else if (!allowCompact || exactSize >= _legibilityFloor) {
              // Below the preferred floor but still readable. Going smaller
              // costs elegance; abbreviating costs digits, and on a balance
              // those digits are real money — a net worth of -2,498,865
              // shown as "-2.5M" hides 98,865 of it. Take the smaller type.
              size = exactSize.clamp(_legibilityFloor, fontSize);
            } else {
              // Genuinely unreadable at any size that fits. Abbreviation is
              // the last resort, and only if it actually buys room: swapping
              // "1,000.00" for "1K" hides digits to save nothing.
              final compactText = display(compact: true);
              final compactSize = fittingSize(compactText);
              // Below six integer digits the exact figure is short enough to
              // be worth keeping at any size: "1,000.00" carries real
              // information that "1K" throws away for three saved glyphs.
              final digits = value.abs().truncate().toString().length;
              final worthIt = digits >= 6 &&
                  compactText.length + 2 <= text.length &&
                  compactSize > exactSize;
              if (worthIt) {
                text = compactText;
                size = compactSize.clamp(_legibilityFloor, fontSize);
              } else {
                size = exactSize.clamp(_legibilityFloor, fontSize);
              }
            }
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // The final fit handles unusually long compact units or extreme
              // accessibility scales, without ever cutting off financial digits.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: alignEnd
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Text(text,
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                    style: base.copyWith(fontSize: size)),
              ),
              if (!currencyInline && !formatter.hidden) ...[
                const SizedBox(height: 4),
                Text(formatter.symbol,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        )),
              ],
            ],
          );
        }),
      ),
    );
  }
}
