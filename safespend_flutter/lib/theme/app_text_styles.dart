import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography builder for SafeSpend — uses Plus Jakarta Sans throughout.
class AppTextStyles {
  AppTextStyles._();

  /// Large currency / balance display (e.g. hero card amounts).
  static TextStyle money({
    Color color = Colors.white,
    double size = 36,
  }) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.0,
      );

  /// Compact stat / badge text (e.g. percentage chips, small labels).
  static TextStyle stat({
    Color color = Colors.white,
    double size = 13,
  }) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  /// Build a full [TextTheme] using Plus Jakarta Sans with tight display weights.
  static TextTheme buildTextTheme(
    Color primary,
    Color secondary,
    Color tertiary,
  ) {
    return GoogleFonts.plusJakartaSansTextTheme(TextTheme(
      displayLarge:  TextStyle(color: primary,   fontWeight: FontWeight.w800, fontSize: 40, letterSpacing: -1.8, height: 1.1),
      displayMedium: TextStyle(color: primary,   fontWeight: FontWeight.w800, fontSize: 34, letterSpacing: -1.2, height: 1.1),
      displaySmall:  TextStyle(color: primary,   fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.8, height: 1.2),
      headlineMedium:TextStyle(color: primary,   fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.4, height: 1.2),
      headlineSmall: TextStyle(color: primary,   fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.2, height: 1.3),
      titleLarge:    TextStyle(color: primary,   fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.1, height: 1.3),
      titleMedium:   TextStyle(color: primary,   fontWeight: FontWeight.w500, fontSize: 15, height: 1.4),
      titleSmall:    TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 13, height: 1.4),
      bodyLarge:     TextStyle(color: primary,   fontWeight: FontWeight.w400, fontSize: 15, height: 1.5),
      bodyMedium:    TextStyle(color: secondary, fontWeight: FontWeight.w400, fontSize: 14, height: 1.5),
      bodySmall:     TextStyle(color: tertiary,  fontWeight: FontWeight.w400, fontSize: 12, height: 1.4),
      labelLarge:    TextStyle(color: primary,   fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2, height: 1.4),
      labelMedium:   TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.1, height: 1.3),
      labelSmall:    TextStyle(color: tertiary,  fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.2, height: 1.3),
    ));
  }
}
