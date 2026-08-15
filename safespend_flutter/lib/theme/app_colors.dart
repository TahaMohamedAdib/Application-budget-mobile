import 'package:flutter/material.dart';

/// Centralized color definitions for SafeSpend.
/// All hex values are defined once here — screens should reference AppColors or AppTheme aliases.
class AppColors {
  AppColors._();

  // ── Teal-Green palette ───────────────────────────────────────────────────
  static const Color goldPrimary = Color(0xFF0B715F); // rich teal-green
  static const Color gold600 = Color(0xFF095C4D); // darker teal
  static const Color gold700 = Color(0xFF07443A); // deep teal
  static const Color gold500 = Color(0xFF0B715F); // rich teal-green
  static const Color gold400 = Color(0xFF0D8A74); // slightly lighter
  static const Color gold300 = Color(0xFF11A88E); // medium teal
  static const Color gold200 = Color(0xFF5ECFBC); // soft teal
  static const Color gold100 = Color(0xFFC2EDE7); // pale teal
  static const Color gold50 = Color(0xFFE8F9F7); // very pale teal

  // ── AI accent (ChatGPT purple for premium features) ───────────────────────
  static const Color aiAccent = Color(0xFFAB68FF); // ChatGPT purple
  static const Color aiAccentDeep = Color(0xFF8E4EC6); // deep purple

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF0B715F); // teal-green — positive
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color warning = Color(0xFFFBBF24); // amber-400
  static const Color info = Color(0xFF0B715F); // teal-green — matches primary

  // ── Light theme (ChatGPT-inspired clean white) ────────────────────────────
  static const Color lightBackground =
      Color(0xFFFFFFFF); // pure white like ChatGPT
  static const Color lightSurface = Color(0xFFF7F7F8); // subtle gray surface
  static const Color lightTextPrimary = Color(0xFF202123); // ChatGPT dark text
  static const Color lightTextSecondary =
      Color(0xFF6E6E80); // ChatGPT gray text
  static const Color lightTextTertiary = Color(0xFF8E8EA0); // lighter gray
  static const Color lightBorder = Color(0xFFE5E5E5); // subtle border
  static const Color lightDivider = Color(0xFFECECF1); // ChatGPT divider

  // ── Dark theme ────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF181A1B); // VS Code charcoal
  static const Color darkSurface = Color(0xFF1A1A1A); // very dark gray surface
  static const Color darkSurfaceElevated =
      Color(0xFF2D2D2D); // elevated surface
  static const Color darkTextPrimary = Color(0xFFECECEC); // ChatGPT light text
  static const Color darkTextSecondary = Color(0xFFAAAAAA); // ChatGPT gray text
  static const Color darkTextTertiary = Color(0xFF8E8E8E); // muted gray
  static const Color darkBorder = Color(0xFF3A3A3A); // subtle border
  static const Color darkDivider = Color(0xFF2A2A2A); // subtle divider
}
