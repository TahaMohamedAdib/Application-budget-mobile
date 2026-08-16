import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_attachment.dart';
import 'ai_config.dart';
import 'ai_error.dart';
import 'ai_message.dart';
import 'ai_response.dart';
import 'ai_service.dart';
import 'ai_tool_call.dart';
import 'financial_context_service.dart';
import 'tools/ai_tool_registry.dart';

/// Client for the self-hosted SafeSpend AI backend.
///
/// The backend fronts Qwen3-Omni (multimodal) and Qwen3.6 (deep financial
/// reasoning) and decides which one serves a request. That routing is
/// deliberately server-side: the app posts to one endpoint and never names a
/// model, so routing policy can change without shipping a release.
///
/// Wire contract — `POST {baseUrl}/v1/chat`:
///
/// ```json
/// {
///   "conversation_id": "uuid|null",
///   "messages": [{"role": "user", "text": "...", "attachments": []}],
///   "financial_context": { ... },
///   "tools": [ ...schema... ],
///   "tool_results": [ ... ]
/// }
/// ```
///
/// Response:
///
/// ```json
/// {
///   "conversation_id": "uuid",
///   "type": "text|tool_call|confirmation_required|financial_insight|error",
///   "text": "...",
///   "tool_calls": [{"id": "...", "name": "...", "arguments": {}}],
///   "suggestions": [], "insights": [], "usage": {}
/// }
/// ```
///
/// Auth is the caller's Supabase session token via `Authorization: Bearer`.
/// The backend derives the user id from that token — never from the request
/// body, and never from model output.
class SafeSpendAIService implements AIService {
  final http.Client _client;
  final bool _ownsClient;

  /// Supplies the current Supabase access token. A callback rather than a
  /// value so a refreshed token is picked up without rebuilding the service.
  final Future<String?> Function() tokenProvider;

  final String baseUrl;

  SafeSpendAIService({
    required this.tokenProvider,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AIConfig.baseUrl,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  String get providerId => 'safespend';

  @override
  bool get isConfigured => baseUrl.isNotEmpty;

  @override
  bool get supportsTools => true;

  @override
  bool get supportsStreaming => true;

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

    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      return AIResponse.failure(AIException.of(AIErrorKind.authExpired));
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'conversation_id': conversationId,
              'messages': _messagesJson(history, attachments),
              'financial_context': context.toJson(),
              'tools': AIToolRegistry.toSchema(),
              if (toolResults != null && toolResults.isNotEmpty)
                'tool_results': toolResults.map((r) => r.toJson()).toList(),
            }),
          )
          .timeout(AIConfig.requestTimeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return AIResponse.failure(AIException.of(AIErrorKind.authExpired));
      }
      if (response.statusCode == 429) {
        return AIResponse.failure(AIException.of(AIErrorKind.rateLimited));
      }
      if (response.statusCode >= 500) {
        return AIResponse.failure(
            AIException.of(AIErrorKind.backendUnavailable));
      }
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              'SafeSpend AI error [${response.statusCode}]: ${response.body}');
        }
        return AIResponse.failure(AIException.of(AIErrorKind.unknown));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return AIResponse.failure(AIException.of(AIErrorKind.unknown));
      }
      return AIResponse.fromJson(decoded.cast<String, dynamic>());
    } on TimeoutException catch (e) {
      return AIResponse.failure(
          AIException.of(AIErrorKind.backendUnavailable, cause: e));
    } on SocketException catch (e) {
      return AIResponse.failure(AIException.of(AIErrorKind.network, cause: e));
    } on http.ClientException catch (e) {
      return AIResponse.failure(AIException.of(AIErrorKind.network, cause: e));
    } catch (e) {
      if (kDebugMode) debugPrint('SafeSpend AI unexpected error: $e');
      return AIResponse.failure(AIException.of(AIErrorKind.unknown, cause: e));
    }
  }

  /// Falls back to the non-streaming shim until the backend exposes SSE.
  /// Callers already consume [AIStreamEvent], so enabling real streaming later
  /// is a change here only.
  @override
  Stream<AIStreamEvent> streamMessage({
    required List<AIMessage> history,
    required FinancialContext context,
    List<AIAttachment>? attachments,
    String? conversationId,
    List<AIToolResult>? toolResults,
  }) async* {
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
    for (final call in response.toolCalls) {
      yield AIToolCallEvent(call);
    }
    yield AIStreamDone(response);
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }

  List<Map<String, dynamic>> _messagesJson(
    List<AIMessage> history,
    List<AIAttachment>? attachments,
  ) {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < history.length; i++) {
      final m = history[i];
      final json = m.toJson();
      final isLast = i == history.length - 1;
      if (isLast && m.role == AIRole.user && attachments != null &&
          attachments.isNotEmpty) {
        json['attachments'] = [
          ...m.attachments.map((a) => a.toJson()),
          ...attachments.map((a) => a.toJson()),
        ];
      }
      out.add(json);
    }
    return out;
  }
}
