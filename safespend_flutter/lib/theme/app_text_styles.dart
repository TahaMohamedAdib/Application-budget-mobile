import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// SafeSpend's typography contract.
///
/// Ordinary copy inherits Inter from the app theme. Call sites choose a
/// semantic role instead of inventing a size: screen title, section title,
/// row title, description, or control label. Money remains responsive because
/// its width is determined by the user's value and currency.
class AppTextStyles {
  AppTextStyles._();

  static const fontFamily = GoogleFonts.family;

  static const double screenTitleSize = 24;
  static const double sectionTitleSize = 18;
  static const double itemTitleSize = 15;
  static const double descriptionSize = 13;
  static const double labelSize = 12;

  static TextStyle screenTitle(Color color) => GoogleFonts.inter(
        color: color,
        fontSize: screenTitleSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
      );

  static TextStyle sectionTitle(Color color) => GoogleFonts.inter(
        color: color,
        fontSize: sectionTitleSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
      );

  static TextStyle itemTitle(Color color) => GoogleFonts.inter(
        color: color,
        fontSize: itemTitleSize,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle description(Color color) => GoogleFonts.inter(
        color: color,
        fontSize: descriptionSize,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  /// Large currency / balance display. MoneyAmount adjusts this when an exact
  /// value needs more room.
  static TextStyle money({
    Color color = Colors.white,
    double size = 36,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -1.2,
        height: 1,
      );

  static TextStyle stat({
    Color color = Colors.white,
    double size = 13,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 0.1,
      );

  /// A complete theme prevents Material components from falling back to a
  /// platform font or an unrelated default size.
  static TextTheme buildTextTheme(
    Color primary,
    Color secondary,
    Color tertiary,
  ) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 40,
            letterSpacing: -1.5,
            height: 1.1),
        displayMedium: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 34,
            letterSpacing: -1,
            height: 1.1),
        displaySmall: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.6,
            height: 1.15),
        headlineLarge: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.6,
            height: 1.2),
        headlineMedium: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: screenTitleSize,
            letterSpacing: -0.4,
            height: 1.2),
        headlineSmall: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.2,
            height: 1.25),
        titleLarge: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: sectionTitleSize,
            letterSpacing: -0.1,
            height: 1.3),
        titleMedium: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: itemTitleSize,
            height: 1.4),
        titleSmall: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4),
        bodyLarge: TextStyle(
            color: primary,
            fontWeight: FontWeight.w400,
            fontSize: 15,
            height: 1.55),
        bodyMedium: TextStyle(
            color: secondary,
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.5),
        bodySmall: TextStyle(
            color: tertiary,
            fontWeight: FontWeight.w400,
            fontSize: descriptionSize,
            height: 1.45),
        labelLarge: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.1,
            height: 1.35),
        labelMedium: TextStyle(
            color: secondary,
            fontWeight: FontWeight.w600,
            fontSize: labelSize,
            height: 1.3),
        labelSmall: TextStyle(
            color: tertiary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.1,
            height: 1.3),
      ),
    );
  }
}
