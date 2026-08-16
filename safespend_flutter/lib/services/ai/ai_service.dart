import 'ai_attachment.dart';
import 'ai_message.dart';
import 'ai_response.dart';
import 'ai_tool_call.dart';
import 'financial_context_service.dart';

/// The single seam between SafeSpend and whatever model serves it.
///
/// Nothing above this interface knows about Gemini, Qwen, prompt formats, or
/// tool-calling dialects. Swapping providers is a matter of binding a different
/// implementation in `AIServiceFactory` — the Coach UI does not change.
abstract class AIService {
  /// Stable identifier for logs and diagnostics, e.g. `gemini`, `safespend`.
  String get providerId;

  /// Whether the implementation has everything it needs to run.
  bool get isConfigured;

  /// True when the backend can serve tool calls. Implementations without
  /// function-calling return false, and the app keeps to plain conversation.
  bool get supportsTools => false;

  /// True when [streamMessage] is more than a single-chunk shim.
  bool get supportsStreaming => false;

  /// Whether attachments can be sent.
  bool get supportsAttachments => false;

  /// One conversational turn.
  ///
  /// Implementations must translate provider failures into [AIResponse] with
  /// [AIResponseType.error] carrying an `AIException`, rather than throwing raw
  /// transport errors at the UI.
  Future<AIResponse> sendMessage({
    required List<AIMessage> history,
    required FinancialContext context,
    List<AIAttachment>? attachments,
    String? conversationId,
    List<AIToolResult>? toolResults,
  });

  /// Incremental variant. The default adapts [sendMessage] into a two-event
  /// stream so callers can be written against streaming from day one, even
  /// while the active provider replies in one shot.
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
    if (response.type == AIResponseType.error && response.error != null) {
      yield AIStreamError(response.error!);
      return;
    }
    if (response.text.isNotEmpty) yield AITextDelta(response.text);
    for (final call in response.toolCalls) {
      yield AIToolCallEvent(call);
    }
    yield AIStreamDone(response);
  }

  /// Releases transport resources. Safe to call more than once.
  void dispose() {}
}
