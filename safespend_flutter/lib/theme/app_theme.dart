import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Gold colors
  static const Color goldPrimary = Color(0xFFB8860B);
  static const Color gold600 = Color(0xFF9A6F09);
  static const Color gold700 = Color(0xFF7A5807);
  static const Color gold500 = Color(0xFFB8860B);
  static const Color gold400 = Color(0xFFD4A520);
  static const Color gold300 = Color(0xFFE5C158);
  static const Color gold200 = Color(0xFFF0D88A);
  static const Color gold100 = Color(0xFFFBF0C8);
  static const Color gold50 = Color(0xFFFDF8E8);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFF1F5F9);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A2029);
  static const Color darkSurfaceElevated = Color(0xFF232A35);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF2A3140);
  static const Color darkDivider = Color(0xFF1E2530);

  // Premium shadows
  static List<BoxShadow> get cardShadowLight => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
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
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: goldPrimary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static TextTheme _buildTextTheme(Color primary, Color secondary, Color tertiary) {
    return GoogleFonts.dmSansTextTheme(TextTheme(
      displayLarge: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 40, letterSpacing: -1.5, height: 1.1),
      displayMedium: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -1.0, height: 1.1),
      displaySmall: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.5, height: 1.2),
      headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.3, height: 1.2),
      headlineSmall: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.2, height: 1.3),
      titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.1, height: 1.3),
      titleMedium: TextStyle(color: primary, fontWeight: FontWeight.w500, fontSize: 15, height: 1.4),
      titleSmall: TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 13, height: 1.4),
      bodyLarge: TextStyle(color: primary, fontWeight: FontWeight.w400, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: secondary, fontWeight: FontWeight.w400, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: tertiary, fontWeight: FontWeight.w400, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3, height: 1.4),
      labelMedium: TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.2, height: 1.3),
      labelSmall: TextStyle(color: tertiary, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.3, height: 1.3),
    ));
  }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: lightDivider,
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1, space: 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: _buildTextTheme(lightTextPrimary, lightTextSecondary, lightTextTertiary),
    iconTheme: const IconThemeData(color: lightTextSecondary, size: 20),
    splashColor: goldPrimary.withOpacity(0.08),
    highlightColor: goldPrimary.withOpacity(0.04),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: darkDivider,
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1, space: 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary, darkTextTertiary),
    iconTheme: const IconThemeData(color: darkTextSecondary, size: 20),
    splashColor: goldPrimary.withOpacity(0.12),
    highlightColor: goldPrimary.withOpacity(0.06),
  );

  // Helper: premium card decoration
  static BoxDecoration premiumCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: isDark ? cardShadowDark : cardShadowLight,
    );
  }

  // Helper: elevated card decoration
  static BoxDecoration elevatedCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurfaceElevated : lightSurface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: isDark ? cardShadowDark : elevatedShadowLight,
    );
  }

  // Helper: gold gradient card
  static BoxDecoration goldCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC49B1A), Color(0xFF9A6F09), Color(0xFF7A5807)],
        stops: [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: goldGlow,
    );
  }

  // Helper: subtle border card
  static BoxDecoration borderedCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? darkBorder : lightBorder, width: 1),
    );
  }
}
