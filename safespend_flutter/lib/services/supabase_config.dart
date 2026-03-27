import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://timctayytkcvxvpukvlq.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_YdjX8DrHstJGUlO7chqPLA_GUhjL-pv';
  static const String authCallbackUrl = 'io.supabase.timctayytkcvxvpukvlq://login-callback/';

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
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(const Duration(seconds: 5));
      isAvailable = true;
    } catch (e) {
      isAvailable = false;
      // Supabase unavailable or timed out — app will run in local-only mode
    }
  }
}
