/// Runtime environment configuration.
///
/// Supabase public keys have safe defaults (anon key is designed to be public;
/// Row Level Security on the server protects data).
///
/// Sensitive provider keys are stored only as Supabase Edge Function secrets.
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

  // ── AI access control ──
  static const String _allowedEmailsRaw = String.fromEnvironment(
    'AI_ALLOWED_EMAILS',
    defaultValue: 'tahamohamedadib@gmail.com',
  );
  static List<String> get allowedEmails => _allowedEmailsRaw.isEmpty
      ? <String>[]
      : _allowedEmailsRaw
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .toList();

  static const bool aiOpenToAll = bool.fromEnvironment(
    'AI_OPEN_TO_ALL',
    defaultValue: false,
  );

  /// True when all required public client configuration is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
