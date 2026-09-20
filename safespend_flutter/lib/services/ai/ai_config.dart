import '../env_config.dart';

/// The backends the app can talk to.
///
/// Only one remains. A `gemini` arm existed that called Google directly with
/// an API key compiled into the binary; it was removed because such a key is
/// extractable by anyone who downloads the app, and no client-side measure
/// can prevent that.
enum AIProvider { safespend }

/// Which backend the app talks to, and how to reach it.
///
/// Switching to the self-hosted stack is a build-flag change:
///
/// ```
/// --dart-define=AI_PROVIDER=safespend
/// --dart-define=AI_BASE_URL=https://ai.safespend.app
/// ```
///
/// No credential for the model-hosting infrastructure is compiled into the
/// app. The SafeSpend backend authenticates callers with the user's existing
/// Supabase session token, which is short-lived and already on the device.
class AIConfig {
  const AIConfig._();

  /// The active backend.
  ///
  /// Only one provider exists, so this is a constant rather than a build flag.
  /// `AI_PROVIDER` is still read and ignored so an existing build script that
  /// passes it does not fail; there is nothing left for it to select.
  static AIProvider get provider => AIProvider.safespend;

  static const String _baseUrlRaw = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: '',
  );

  /// Base URL of the SafeSpend AI backend.
  ///
  /// Falls back to the Edge Functions host of the configured Supabase project,
  /// where the `chat` function already lives. That keeps the default build
  /// working without compiling in a provider key: the function holds the
  /// credential server-side and authenticates callers with their existing
  /// Supabase session. Set `AI_BASE_URL` to point at a different backend.
  static String get baseUrl {
    if (_baseUrlRaw.isNotEmpty) return _baseUrlRaw;
    final supabase = EnvConfig.supabaseUrl.trim();
    if (supabase.isEmpty) return '';
    return '${supabase.replaceAll(RegExp(r'/+$'), '')}/functions';
  }

  /// WebSocket endpoint for realtime voice. Derived from [baseUrl] when unset.
  static const String _voiceUrlRaw = String.fromEnvironment(
    'AI_VOICE_URL',
    defaultValue: '',
  );

  static String get voiceUrl {
    if (_voiceUrlRaw.isNotEmpty) return _voiceUrlRaw;
    if (baseUrl.isEmpty) return '';
    final ws = baseUrl
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://');
    return '${ws.replaceAll(RegExp(r'/+$'), '')}/v1/voice';
  }

  static String get chatEndpoint =>
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/chat';

  /// Whether the backend has what it needs to run. No API key is involved:
  /// the credential lives server-side, and callers authenticate with their
  /// own Supabase session token.
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Request timeout for a single completion.
  static const Duration requestTimeout = Duration(seconds: 90);
}
