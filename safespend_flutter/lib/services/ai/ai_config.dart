import '../env_config.dart';

enum AIProvider { gemini, safespend }

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

  static const String _providerRaw = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'gemini',
  );

  static AIProvider get provider => switch (_providerRaw.toLowerCase().trim()) {
        'safespend' => AIProvider.safespend,
        _ => AIProvider.gemini,
      };

  /// Base URL of the SafeSpend AI backend. Ignored for the Gemini provider.
  static const String baseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: '',
  );

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

  /// Whether the selected provider has what it needs to run.
  static bool get isConfigured => switch (provider) {
        AIProvider.gemini => EnvConfig.geminiApiKey.isNotEmpty,
        AIProvider.safespend => baseUrl.isNotEmpty,
      };

  /// Request timeout for a single completion.
  static const Duration requestTimeout = Duration(seconds: 90);
}
