import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../env_config.dart';
import 'ai_attachment.dart';
import 'ai_config.dart';
import 'ai_error.dart';
import 'ai_message.dart';
import 'ai_response.dart';
import 'ai_service.dart';
import 'ai_tool_call.dart';
import 'financial_context_service.dart';

/// Current production implementation, talking to Gemini directly.
///
/// Temporary by design: it exists so the Coach keeps working while the
/// SafeSpend backend is built, and is deleted once `AI_PROVIDER=safespend` is
/// the default. It deliberately reports `supportsTools == false` — Gemini is
/// wired here for conversation only, so the tool layer stays dormant rather
/// than half-working.
class GeminiAIService implements AIService {
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final http.Client _client;
  final bool _ownsClient;

  GeminiAIService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  String get providerId => 'gemini';

  @override
  bool get isConfigured => EnvConfig.geminiApiKey.isNotEmpty;

  @override
  bool get supportsTools => false;

  @override
  bool get supportsStreaming => false;

  @override
  bool get supportsAttachments => true;

  @override
  Future<AIResponse> sendMessage({
    required List<AIMessage> history,
    required FinancialContext context,
    List<AIAttachment>? attachments,
    String? conversationId,
    List<AIToolResult>? toolResults,
  }) async {
    if (!isConfigured) {
      return AIResponse.failure(AIException.of(AIErrorKind.notConfigured));
    }

    try {
      final contents = _buildContents(history, attachments);
      if (contents.isEmpty) {
        return const AIResponse.text('');
      }

      final response = await _client
          .post(
            Uri.parse('$_endpoint?key=${EnvConfig.geminiApiKey}'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': _systemPrompt(context)}
                ],
              },
              'contents': contents,
              'generationConfig': {
                'temperature': 0.6,
                'maxOutputTokens': 1500,
                'topP': 0.9,
              },
              'safetySettings': const [
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
                },
                {
                  'category': 'HARM_CATEGORY_HATE_SPEECH',
                  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
                },
                {
                  'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
                },
                {
                  'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
                },
              ],
            }),
          )
          .timeout(AIConfig.requestTimeout);

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              'Gemini error [${response.statusCode}]: ${response.body}');
        }
        return AIResponse.failure(_mapHttpError(response));
      }

      final text = _extractText(jsonDecode(response.body));
      return AIResponse(
        type: AIResponseType.text,
        text: text,
        conversationId: conversationId,
        usage: const AIUsage(model: _model),
      );
    } on TimeoutException catch (e) {
      return AIResponse.failure(
          AIException.of(AIErrorKind.backendUnavailable, cause: e));
    } on SocketException catch (e) {
      return AIResponse.failure(AIException.of(AIErrorKind.network, cause: e));
    } on http.ClientException catch (e) {
      return AIResponse.failure(AIException.of(AIErrorKind.network, cause: e));
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini unexpected error: $e');
      return AIResponse.failure(AIException.of(AIErrorKind.unknown, cause: e));
    }
  }

  @override
  Stream<AIStreamEvent> streamMessage({
    required List<AIMessage> history,
    required FinancialContext context,
    List<AIAttachment>? attachments,
    String? conversationId,
    List<AIToolResult>? toolResults,
  }) async* {
    // No native streaming here; the base-class shim shape is reproduced so
    // callers see identical event ordering across providers.
    final response = await sendMessage(
      history: history,
      context: context,
      attachments: attachments,
      conversationId: conversationId,
      toolResults: toolResults,
    );
    if (response.error != null) {
      yield AIStreamError(response.error!);
      return;
    }
    if (response.text.isNotEmpty) yield AITextDelta(response.text);
    yield AIStreamDone(response);
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }

  // ── Wire format ───────────────────────────────────────────────────────────

  /// Gemini requires alternating roles, a leading user turn, and rejects empty
  /// parts — so consecutive same-role turns are merged and blanks dropped.
  List<Map<String, dynamic>> _buildContents(
    List<AIMessage> history,
    List<AIAttachment>? attachments,
  ) {
    final merged = <Map<String, dynamic>>[];

    for (var i = 0; i < history.length; i++) {
      final m = history[i];
      if (m.role == AIRole.tool) continue; // not supported on this provider

      final isLast = i == history.length - 1;
      final parts = <Map<String, dynamic>>[];

      // Attachments ride on the final user turn only.
      final media = <AIAttachment>[
        ...m.attachments,
        if (isLast && m.role == AIRole.user) ...?attachments,
      ];
      for (final a in media) {
        parts.add({
          'inlineData': {'mimeType': a.mimeType, 'data': a.toBase64()},
        });
      }
      if (m.text.isNotEmpty) parts.add({'text': m.text});
      if (parts.isEmpty) continue;

      final role = m.role == AIRole.assistant ? 'model' : 'user';
      if (merged.isNotEmpty && merged.last['role'] == role) {
        (merged.last['parts'] as List).addAll(parts);
      } else {
        merged.add({'role': role, 'parts': parts});
      }
    }

    if (merged.isNotEmpty && merged.first['role'] != 'user') {
      merged.removeAt(0);
    }
    return merged;
  }

  /// gemini-2.5-flash is a thinking model: parts flagged `thought` are internal
  /// reasoning and must not be shown, so the last non-thought part wins.
  String _extractText(dynamic decoded) {
    if (decoded is! Map) return '';
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';

    for (final p in parts.reversed) {
      if (p is Map && p['thought'] != true && p['text'] is String) {
        return (p['text'] as String).trim();
      }
    }
    for (final p in parts) {
      if (p is Map && p['text'] is String) return (p['text'] as String).trim();
    }
    return '';
  }

  AIException _mapHttpError(http.Response response) {
    String message = '';
    try {
      message =
          (jsonDecode(response.body)['error']?['message'] as String?) ?? '';
    } catch (_) {
      // Body wasn't JSON; the status code alone drives the mapping.
    }
    final lower = message.toLowerCase();

    if (response.statusCode == 429) {
      return AIException.of(AIErrorKind.rateLimited);
    }
    if (response.statusCode >= 500) {
      return AIException.of(AIErrorKind.backendUnavailable);
    }
    if (response.statusCode == 403 ||
        lower.contains('leaked') ||
        lower.contains('revoked') ||
        (response.statusCode == 400 && lower.contains('api key'))) {
      // A bad key is a deployment fault, not something the user can act on.
      return AIException.of(AIErrorKind.backendUnavailable);
    }
    return AIException.of(AIErrorKind.unknown);
  }

  String _systemPrompt(FinancialContext context) {
    final json = context.toJson();
    final projectContext = json.remove('project_context');
    final lines =
        json.entries.map((e) => '  • ${e.key}: ${e.value}').join('\n');

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
  6. Format all amounts in ${context.currency}.
  7. Never fabricate data. The figures below are computed by SafeSpend — explain them, never recalculate or invent them. If you don't know something, say so clearly.

USER'S LIVE FINANCIAL SNAPSHOT:
$lines

Use this data to give personalized, specific advice — not generic tips.${projectContext == null ? '' : '''


PROJECT CONTEXT:
This conversation belongs to a project. The user groups related conversations together under projects.
You have access to summaries of other conversations in this project. Use this context to understand what the user has previously discussed and provide continuity — if the user refers to something from another conversation in the project, you should know about it.

$projectContext
'''}''';
  }
}
