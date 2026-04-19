import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

class SupabaseConfig {
  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  static String get authCallbackUrl => EnvConfig.supabaseAuthCallback;

  static bool isAvailable = false;

  static SupabaseClient? get client {
    if (!isAvailable) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      if (kDebugMode) debugPrint('[SupabaseConfig] URL or key empty — skipping init');
      isAvailable = false;
      return;
    }
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      isAvailable = true;
      if (kDebugMode) debugPrint('[SupabaseConfig] initialized OK — url=$supabaseUrl');
    } catch (e) {
      if (kDebugMode) debugPrint('[SupabaseConfig] init failed: $e');
      isAvailable = false;
    }
  }
}
