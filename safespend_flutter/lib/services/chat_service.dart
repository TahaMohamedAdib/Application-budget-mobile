import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

/// A single message in the conversation.
class ChatMessage {
  final String role;    // 'user' | 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Calls the Supabase Edge Function that proxies DeepSeek.
class ChatService {
  static const String _functionPath = '/functions/v1/chat';

  static Future<String> sendMessage({
    required List<ChatMessage> history,
    required Map<String, dynamic> financialContext,
    required String token,
  }) async {
    final uri = Uri.parse('${SupabaseConfig.supabaseUrl}$_functionPath');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'apikey': SupabaseConfig.supabaseAnonKey,
          },
          body: jsonEncode({
            'messages': history.map((m) => m.toJson()).toList(),
            'financial_context': financialContext,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body['reply'] as String? ?? 'No response.';
    } else {
      throw Exception(body['error'] ?? 'HTTP ${response.statusCode}');
    }
  }
}
