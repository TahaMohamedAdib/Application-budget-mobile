import 'ai/ai_config.dart';

/// Runtime environment configuration.
///
/// Supabase public keys have safe defaults (anon key is designed to be public;
/// Row Level Security on the server protects data).
///
/// **No model-provider API key belongs here.** Anything compiled into the app
/// ships inside the binary, where anyone who downloads it can read it. The AI
/// backend holds its credential server-side and authenticates callers with
/// their existing Supabase session instead.
class EnvConfig {
  const EnvConfig._();

  // ── Supabase (public keys — safe defaults for dev) ──
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://timctayytkcvxvpukvlq.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_YdjX8DrHstJGUlO7chqPLA_GUhjL-pv',
  );

  static const String supabaseAuthCallback = String.fromEnvironment(
    'SUPABASE_AUTH_CALLBACK',
    defaultValue: 'io.supabase.timctayytkcvxvpukvlq://login-callback/',
  );

  // ── AI provider selection ──
  // Concrete provider settings live in services/ai/ai_config.dart; these are
  // re-exposed here so `isConfigured` can reason about the active backend.
  //
  // Defaults must match AIConfig exactly. They used to be declared twice with
  // different values, so this file believed the app was on Gemini while the
  // factory had already built the backend service — the kind of split that
  // makes a security default look applied when it is not.
  static String get aiProvider => AIConfig.provider.name;

  /// Base URL of the self-hosted VVollet AI backend. No hosting credential
  /// is ever compiled into the app — the backend authenticates callers with
  /// their existing Supabase session token.
  static String get aiBaseUrl => AIConfig.baseUrl;

  // ── AI access control ──
  static const String _allowedEmailsRaw = String.fromEnvironment(
    'AI_ALLOWED_EMAILS',
    defaultValue: 'tahamohamedadib@gmail.com',
  );
  static List<String> get allowedEmails => _allowedEmailsRaw.isEmpty
      ? <String>[]
      : _allowedEmailsRaw.split(',').map((e) => e.trim().toLowerCase()).toList();

  static const bool aiOpenToAll = bool.fromEnvironment(
    'AI_OPEN_TO_ALL',
    defaultValue: false,
  );

  /// True when the app has everything it needs to reach its backends.
  /// No API key is part of this: the AI credential lives server-side.
  static bool get isConfigured =>
      AIConfig.isConfigured &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
