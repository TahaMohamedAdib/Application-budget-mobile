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

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadowLight => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadowLight => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.18),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
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
      fillColor: const Color(0xFFF1F3F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: goldPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      labelStyle: const TextStyle(color: lightTextSecondary),
      hintStyle: const TextStyle(color: lightTextTertiary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
      fillColor: darkSurfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: goldPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextTertiary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
      borderRadius: BorderRadius.circular(16),
      border: isDark
          ? Border.all(color: Colors.white.withOpacity(0.07), width: 1)
          : null,
      boxShadow: isDark ? cardShadowDark : cardShadowLight,
    );
  }

  /// Elevated card — slightly raised surface.
  static BoxDecoration elevatedCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurfaceElevated : lightSurface,
      borderRadius: BorderRadius.circular(16),
      border: isDark
          ? Border.all(color: Colors.white.withOpacity(0.07), width: 1)
          : null,
      boxShadow: isDark ? cardShadowDark : elevatedShadowLight,
    );
  }

  /// Slate gradient hero card with white neon edge glow.
  static BoxDecoration goldCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF06080D)],
        stops: [0.0, 0.55, 1.0],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 1.5,
      ),
      boxShadow: [
        // White neon edge glow — tight inner ring
        BoxShadow(
          color: Colors.white.withOpacity(0.18),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        // White neon edge glow — soft outer halo
        BoxShadow(
          color: Colors.white.withOpacity(0.07),
          blurRadius: 32,
          spreadRadius: 4,
        ),
        // Depth shadow underneath
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
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
