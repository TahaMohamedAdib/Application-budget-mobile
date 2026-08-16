import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_backend_service.dart';
import 'ai_config.dart';
import 'ai_service.dart';
import 'gemini_ai_service.dart';

/// Resolves the active [AIService] from configuration.
///
/// This is the only place that names a concrete provider. Moving to the
/// self-hosted stack means building with `AI_PROVIDER=safespend`; once that is
/// the default, `GeminiAIService` and this switch's other arm can be deleted
/// without touching the Coach.
class AIServiceFactory {
  const AIServiceFactory._();

  static AIService? _instance;

  static AIService get instance => _instance ??= create();

  static AIService create({AIProvider? provider}) {
    switch (provider ?? AIConfig.provider) {
      case AIProvider.safespend:
        return SafeSpendAIService(tokenProvider: _supabaseToken);
      case AIProvider.gemini:
        return GeminiAIService();
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
