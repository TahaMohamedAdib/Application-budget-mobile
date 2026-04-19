import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central theme provider for SafeSpend.
/// All color constants are backward-compatible aliases to AppColors.
class AppTheme {
  AppTheme._();

  // ── Backward-compat color aliases ────────────────────────────────────────
  static const Color goldPrimary         = AppColors.goldPrimary;
  static const Color gold600             = AppColors.gold600;
  static const Color gold700             = AppColors.gold700;
  static const Color gold500             = AppColors.gold500;
  static const Color gold400             = AppColors.gold400;
  static const Color gold300             = AppColors.gold300;
  static const Color gold200             = AppColors.gold200;
  static const Color gold100             = AppColors.gold100;
  static const Color gold50              = AppColors.gold50;

  // ── AI accent (sky blue, ChatGPT-inspired) ────────────────────────────────
  static const Color aiAccent     = AppColors.aiAccent;
  static const Color aiAccentDeep = AppColors.aiAccentDeep;

  static const Color success = AppColors.success;
  static const Color error   = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color info    = AppColors.info;

  static const Color lightBackground    = AppColors.lightBackground;
  static const Color lightSurface       = AppColors.lightSurface;
  static const Color lightTextPrimary   = AppColors.lightTextPrimary;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;
  static const Color lightTextTertiary  = AppColors.lightTextTertiary;
  static const Color lightBorder        = AppColors.lightBorder;
  static const Color lightDivider       = AppColors.lightDivider;

  static const Color darkBackground       = AppColors.darkBackground;
  static const Color darkSurface          = AppColors.darkSurface;
  static const Color darkSurfaceElevated  = AppColors.darkSurfaceElevated;
  static const Color darkTextPrimary      = AppColors.darkTextPrimary;
  static const Color darkTextSecondary    = AppColors.darkTextSecondary;
  static const Color darkTextTertiary     = AppColors.darkTextTertiary;
  static const Color darkBorder           = AppColors.darkBorder;
  static const Color darkDivider          = AppColors.darkDivider;

  // ── Shadows (cached — avoids re-allocation on every access) ────────────────
  static const _black05 = Color(0x0D000000); // black @ 5%
  static const _black15 = Color(0x26000000); // black @ 15%
  static const _black18 = Color(0x2E000000); // black @ 18%
  static const _slate08 = Color(0x140F172A); // 0F172A @ 8%
  static const _slate04 = Color(0x0A0F172A); // 0F172A @ 4%

  static final List<BoxShadow> cardShadowLight = const [
    BoxShadow(color: _black05, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static final List<BoxShadow> cardShadowDark = const [
    BoxShadow(color: _black15, blurRadius: 12, offset: Offset(0, 2)),
  ];

  static final List<BoxShadow> elevatedShadowLight = const [
    BoxShadow(color: _slate08, blurRadius: 24, offset: Offset(0, 8), spreadRadius: -2),
    BoxShadow(color: _slate04, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static final List<BoxShadow> goldGlow = const [
    BoxShadow(color: _black18, blurRadius: 20, offset: Offset(0, 6), spreadRadius: -2),
  ];

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: goldPrimary,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: goldPrimary,
      secondary: goldPrimary,
      surface: lightSurface,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: lightDivider,
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1, space: 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: AppTextStyles.buildTextTheme(
      lightTextPrimary, lightTextSecondary, lightTextTertiary,
    ),
    iconTheme: const IconThemeData(color: lightTextSecondary, size: 20),
    splashColor: goldPrimary.withOpacity(0.08),
    highlightColor: goldPrimary.withOpacity(0.04),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: lightTextTertiary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: const Color(0xFF1A2029),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? goldPrimary : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? goldPrimary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F3F6),
      selectedColor: goldPrimary.withOpacity(0.15),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: lightBorder),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: goldPrimary,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: goldPrimary,
      secondary: goldPrimary,
      surface: darkSurface,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: darkDivider,
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1, space: 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: AppTextStyles.buildTextTheme(
      darkTextPrimary, darkTextSecondary, darkTextTertiary,
    ),
    iconTheme: const IconThemeData(color: darkTextSecondary, size: 20),
    splashColor: goldPrimary.withOpacity(0.10),
    highlightColor: goldPrimary.withOpacity(0.05),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: darkTextTertiary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: darkSurfaceElevated,
      contentTextStyle: const TextStyle(color: darkTextPrimary, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? goldPrimary : darkTextTertiary),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? goldPrimary.withOpacity(0.35)
              : Colors.white.withOpacity(0.1)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceElevated,
      selectedColor: goldPrimary.withOpacity(0.2),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: darkTextSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: Colors.white.withOpacity(0.08)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // ── Card decoration helpers (backward-compat API) ─────────────────────────

  /// Standard surface card with subtle 1px border on dark mode.
  static BoxDecoration premiumCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(20),
      border: isDark
          ? Border.all(color: darkBorder, width: 1)
          : Border.all(color: lightBorder, width: 1),
      boxShadow: isDark ? cardShadowDark : cardShadowLight,
    );
  }

  /// Elevated card — slightly raised surface.
  static BoxDecoration elevatedCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurfaceElevated : lightSurface,
      borderRadius: BorderRadius.circular(20),
      border: isDark
          ? Border.all(color: darkBorder, width: 1)
          : Border.all(color: lightBorder, width: 1),
      boxShadow: isDark ? cardShadowDark : elevatedShadowLight,
    );
  }

  /// ChatGPT-style hero card with teal accent.
  static BoxDecoration goldCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2F2F2F), Color(0xFF212121), Color(0xFF1A1A1A)],
        stops: [0.0, 0.50, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
        width: 1.0,
      ),
      boxShadow: [
        // Soft teal glow — ChatGPT brand
        BoxShadow(
          color: const Color(0xFF0B715F).withOpacity(0.15),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        // Subtle depth shadow
        BoxShadow(
          color: Colors.black.withOpacity(0.30),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ],
    );
  }

  /// Subtle bordered card (outline style).
  static BoxDecoration borderedCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.09) : lightBorder,
        width: 1,
      ),
    );
  }

  /// Glass-style semi-transparent card for overlays.
  static BoxDecoration glassCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.white.withOpacity(0.72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.60),
        width: 1,
      ),
    );
  }

  /// Colored gradient accent card (red for debt, purple for portfolio, etc.).
  static BoxDecoration accentCard(Color baseColor) {
    final lighter = Color.lerp(baseColor, Colors.white, 0.18)!;
    final darker  = Color.lerp(baseColor, Colors.black, 0.25)!;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lighter, baseColor, darker],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: baseColor.withOpacity(0.30),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Consistent icon container decoration.
  static BoxDecoration iconContainer({
    required Color color,
    double radius = 14,
    double opacity = 0.12,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
