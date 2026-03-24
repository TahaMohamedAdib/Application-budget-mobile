import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography builder for SafeSpend — uses Inter throughout.
/// Weights: 400 body · 500 labels/buttons · 600 titles · 700 balances/totals
class AppTextStyles {
  AppTextStyles._();

  /// Large currency / balance display (e.g. hero card amounts).
  static TextStyle money({
    Color color = Colors.white,
    double size = 36,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.0,
      );

  /// Compact stat / badge text (e.g. percentage chips, small labels).
  static TextStyle stat({
    Color color = Colors.white,
    double size = 13,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  /// Build a full [TextTheme] using Inter with clean readable weights.
  static TextTheme buildTextTheme(
    Color primary,
    Color secondary,
    Color tertiary,
  ) {
    return GoogleFonts.interTextTheme(TextTheme(
      displayLarge:  TextStyle(color: primary,   fontWeight: FontWeight.w700, fontSize: 40, letterSpacing: -1.5, height: 1.1),
      displayMedium: TextStyle(color: primary,   fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -1.0, height: 1.1),
      displaySmall:  TextStyle(color: primary,   fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.6, height: 1.2),
      headlineMedium:TextStyle(color: primary,   fontWeight: FontWeight.w600, fontSize: 24, letterSpacing: -0.3, height: 1.2),
      headlineSmall: TextStyle(color: primary,   fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.2, height: 1.3),
      titleLarge:    TextStyle(color: primary,   fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.1, height: 1.3),
      titleMedium:   TextStyle(color: primary,   fontWeight: FontWeight.w500, fontSize: 15, height: 1.45),
      titleSmall:    TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 13, height: 1.45),
      bodyLarge:     TextStyle(color: primary,   fontWeight: FontWeight.w400, fontSize: 15, height: 1.6),
      bodyMedium:    TextStyle(color: secondary, fontWeight: FontWeight.w400, fontSize: 14, height: 1.6),
      bodySmall:     TextStyle(color: tertiary,  fontWeight: FontWeight.w400, fontSize: 12, height: 1.5),
      labelLarge:    TextStyle(color: primary,   fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: 0.1, height: 1.4),
      labelMedium:   TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.0, height: 1.3),
      labelSmall:    TextStyle(color: tertiary,  fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.1, height: 1.3),
    ));
  }
}
