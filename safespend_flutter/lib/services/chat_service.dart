import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'env_config.dart';

/// A single message in the conversation.
class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toGeminiContent({
    String? attachmentBase64,
    String? attachmentMimeType,
  }) {
    final parts = <Map<String, dynamic>>[];

    // Inline media (image or PDF) — only on the message that carries it
    if (attachmentBase64 != null && attachmentMimeType != null) {
      parts.add({
        'inlineData': {
          'mimeType': attachmentMimeType,
          'data': attachmentBase64,
        },
      });
    }

    if (content.isNotEmpty) {
      parts.add({'text': content});
    }

    return {
      'role': role == 'assistant' ? 'model' : 'user',
      'parts': parts,
    };
  }
}

class ChatService {
  static String get _apiKey => EnvConfig.geminiApiKey;
  static const String _model = 'gemini-2.5-flash';
  static String get _baseUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ── System prompt ────────────────────────────────────────────
  static String _systemPrompt(Map<String, dynamic> ctx) {
    final lines = ctx.entries.map((e) => '  • ${e.key}: ${e.value}').join('\n');
    return '''
You are SafeSpend AI — a specialized personal finance assistant built into the SafeSpend budgeting app.

YOUR ONLY PURPOSE is to help users with their personal finances:
  - Budgeting, expense tracking, and spending analysis
  - Savings strategies and financial goals
  - Debt management and payoff plans
  - Understanding their SafeSpend data (provided below)
  - Analyzing receipts, invoices, bank statements, or any financial document/image they share
  - Explaining financial concepts in simple terms

FORMATTING RULES — you MUST follow these for every response:
  - Use **bold** for key numbers, category names, and important terms.
  - Use relevant emojis to make responses friendly and scannable (e.g. 💰 for money, 📊 for analysis, 🎯 for goals, 💡 for tips, ⚠️ for warnings, ✅ for achievements, 📉 for decreases, 📈 for increases, 🏦 for savings).
  - Use bullet points or numbered lists for multiple items — never walls of text.
  - Keep paragraphs short (2-3 sentences max).
  - Start responses with a brief emoji + one-line summary, then expand below.

STRICT RULES — follow these at all times:
  1. Stay 100% on-topic. NEVER discuss politics, entertainment, coding, general trivia, relationships, health, or anything unrelated to personal finance and the user's money.
  2. If asked something off-topic, respond with exactly: "I'm your SafeSpend financial assistant — I can only help with questions about your finances. What would you like to know about your money?"
  3. When analyzing images or documents, extract ONLY financial information: amounts, dates, merchants, categories, totals. Suggest how the user could log it in SafeSpend.
  4. Be concise and actionable. Lead with the key insight. Skip unnecessary disclaimers.
  5. Always reference the user's real data below when relevant — make it personal.
  6. Format all amounts in ${ctx['currency'] ?? 'the user\'s currency'}.
  7. Never fabricate data. If you don't know something about the user's finances, say so clearly.

USER'S LIVE FINANCIAL SNAPSHOT:
$lines

Use this data to give personalized, specific advice — not generic tips.
${ctx.containsKey('project_context') ? '''

PROJECT CONTEXT:
This conversation belongs to a project. The user groups related conversations together under projects.
You have access to summaries of other conversations in this project. Use this context to understand what the user has previously discussed and provide continuity — if the user refers to something from another conversation in the project, you should know about it.

${ctx['project_context']}
''' : ''}''';
  }

  // ── Send message ─────────────────────────────────────────────
  static Future<String> sendMessage({
    required List<ChatMessage> history,
    required Map<String, dynamic> financialContext,
    required String token, // kept for API compatibility
    String? attachmentBase64,
    String? attachmentMimeType,
  }) async {
    if (_apiKey.isEmpty) {
      return 'SafeSpend AI is not configured yet. Please contact support.';
    }

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    // Build contents: apply attachment only to the last (current) user message
    // Merge consecutive same-role messages (Gemini requires alternating roles)
    final rawContents = history.asMap().entries.map((entry) {
      final isLast = entry.key == history.length - 1;
      final m = entry.value;
      return m.toGeminiContent(
        attachmentBase64: (isLast && m.role == 'user') ? attachmentBase64 : null,
        attachmentMimeType: (isLast && m.role == 'user') ? attachmentMimeType : null,
      );
    }).toList();

    // Merge consecutive same-role entries & drop entries with empty parts
    final contents = <Map<String, dynamic>>[];
    for (final c in rawContents) {
      final parts = c['parts'] as List<dynamic>? ?? [];
      if (parts.isEmpty) continue; // skip empty messages
      if (contents.isNotEmpty && contents.last['role'] == c['role']) {
        // merge parts into previous entry with same role
        (contents.last['parts'] as List<dynamic>).addAll(parts);
      } else {
        contents.add(c);
      }
    }

    // Ensure conversation starts with a user turn
    if (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.removeAt(0);
    }

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt(financialContext)},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 1500,
        'topP': 0.9,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      if (kDebugMode) debugPrint('Gemini API error [${response.statusCode}]: ${response.body}');
    }

    if (response.statusCode == 200) {
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return 'No response received.';
      final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return 'No response received.';
      // gemini-2.5-flash is a thinking model: skip parts with "thought":true
      for (final p in parts.reversed) {
        if (p is Map && p['thought'] != true && p['text'] != null) {
          return (p['text'] as String).trim();
        }
      }
      // Fallback: return first text part regardless
      for (final p in parts) {
        if (p is Map && p['text'] != null) {
          return (p['text'] as String).trim();
        }
      }
      return 'No response received.';
    } else {
      final errorMsg = decoded['error']?['message'] as String? ?? '';
      // Map API errors to user-friendly messages
      if (response.statusCode == 400 && errorMsg.contains('API key')) {
        return 'SafeSpend AI is temporarily unavailable. The service is being updated — please try again later.';
      }
      if (response.statusCode == 403 || errorMsg.toLowerCase().contains('leaked') || errorMsg.toLowerCase().contains('revoked')) {
        return 'SafeSpend AI is temporarily unavailable. The service is being updated — please try again later.';
      }
      if (response.statusCode == 429) {
        return 'SafeSpend AI is busy right now. Please wait a moment and try again.';
      }
      if (response.statusCode >= 500) {
        return 'The AI service is experiencing issues. Please try again in a few minutes.';
      }
      // Generic fallback — never expose raw API details to the user
      return 'Something went wrong. Please try again later.';
    }
  }
}
