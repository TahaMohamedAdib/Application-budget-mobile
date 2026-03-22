import 'package:flutter/material.dart';

/// Centralized color definitions for SafeSpend.
/// All hex values are defined once here — screens should reference AppColors or AppTheme aliases.
class AppColors {
  AppColors._();

  // ── Slate palette (premium gray primary) ─────────────────────────────────
  static const Color goldPrimary = Color(0xFF475569); // slate-600
  static const Color gold600     = Color(0xFF334155); // slate-700
  static const Color gold700     = Color(0xFF1E293B); // slate-800
  static const Color gold500     = Color(0xFF475569); // slate-600
  static const Color gold400     = Color(0xFF64748B); // slate-500
  static const Color gold300     = Color(0xFF94A3B8); // slate-400
  static const Color gold200     = Color(0xFFCBD5E1); // slate-300
  static const Color gold100     = Color(0xFFE2E8F0); // slate-200
  static const Color gold50      = Color(0xFFF1F5F9); // slate-100

  // ── Secondary accent ─────────────────────────────────────────────────────
  static const Color teal      = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFF5EEAD4);
  static const Color tealDark  = Color(0xFF0F766E);

  // ── Portfolio / debt accents ─────────────────────────────────────────────
  static const Color purple      = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color error   = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info    = Color(0xFF60A5FA);

  // ── Light theme ──────────────────────────────────────────────────────────
  static const Color lightBackground    = Color(0xFFF0F1F7);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightTextPrimary   = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary  = Color(0xFF94A3B8);
  static const Color lightBorder        = Color(0xFFE2E8F0);
  static const Color lightDivider       = Color(0xFFEEEFF4);

  // ── Dark theme (deeper, more premium) ────────────────────────────────────
  static const Color darkBackground        = Color(0xFF06080D);
  static const Color darkSurface           = Color(0xFF0F1318);
  static const Color darkSurfaceElevated   = Color(0xFF171C24);
  static const Color darkTextPrimary       = Color(0xFFF1F5F9);
  static const Color darkTextSecondary     = Color(0xFF94A3B8);
  static const Color darkTextTertiary      = Color(0xFF64748B);
  static const Color darkBorder            = Color(0xFF1E2530);
  static const Color darkDivider           = Color(0xFF0E1117);
}
