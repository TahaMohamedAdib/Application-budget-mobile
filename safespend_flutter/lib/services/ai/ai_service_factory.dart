import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_backend_service.dart';
import 'ai_config.dart';
import 'ai_service.dart';

/// Resolves the active [AIService] from configuration.
///
/// One provider remains: the VVollet backend, which holds the model
/// credential server-side and authenticates callers with their existing
/// Supabase session. The direct-to-Gemini implementation was removed because
/// it required an API key compiled into the app binary, where anyone who
/// downloads the app can extract it.
class AIServiceFactory {
  const AIServiceFactory._();

  static AIService? _instance;

  static AIService get instance => _instance ??= create();

  static AIService create({AIProvider? provider}) {
    switch (provider ?? AIConfig.provider) {
      case AIProvider.safespend:
        return VVolletAIService(tokenProvider: _supabaseToken);
    }
  }

  /// Overrides the active service. Intended for tests.
  @visibleForTesting
  static void override(AIService service) {
    _instance?.dispose();
    _instance = service;
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  /// Current Supabase access token, refreshed on each call so an expired one
  /// isn't captured for the life of the service.
  static Future<String?> _supabaseToken() async =>
      Supabase.instance.client.auth.currentSession?.accessToken;
}
