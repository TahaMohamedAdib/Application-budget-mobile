/// Runtime environment configuration.
///
/// Supabase public keys have safe defaults (anon key is designed to be public;
/// Row Level Security on the server protects data).
///
/// Sensitive keys like GEMINI_API_KEY have NO default — they must be injected
/// at build time via `--dart-define-from-file=.env.local`.
class EnvConfig {
  const EnvConfig._();

  // ── Gemini (no default — requires build flag) ──
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

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
  static const String aiProvider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'gemini',
  );

  /// Base URL of the self-hosted SafeSpend AI backend. No hosting credential
  /// is ever compiled into the app — the backend authenticates callers with
  /// their existing Supabase session token.
  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: '',
  );

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

  /// True when all required secrets are present for the active AI provider.
  static bool get isConfigured =>
      (aiProvider == 'safespend' ? aiBaseUrl.isNotEmpty : geminiApiKey.isNotEmpty) &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
