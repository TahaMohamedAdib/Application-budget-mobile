import 'ai_error.dart';
import 'ai_tool_call.dart';

/// The shape of an assistant turn, so the Coach can render more than prose.
enum AIResponseType {
  text,
  toolCall,
  confirmationRequired,
  financialInsight,
  error,
}

/// A tappable follow-up the UI can offer as a chip.
class AISuggestion {
  final String label;

  /// Text to send when tapped. Defaults to [label].
  final String? prompt;

  const AISuggestion(this.label, {this.prompt});

  String get message => prompt ?? label;

  factory AISuggestion.fromJson(Map<String, dynamic> json) => AISuggestion(
        json['label'] as String? ?? '',
        prompt: json['prompt'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'label': label, if (prompt != null) 'prompt': prompt};
}

/// Token accounting, when the backend reports it.
class AIUsage {
  final int promptTokens;
  final int completionTokens;

  /// Which model actually served the request. Informational only — the app
  /// must not branch on it.
  final String? model;

  const AIUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.model,
  });

  int get totalTokens => promptTokens + completionTokens;

  factory AIUsage.fromJson(Map<String, dynamic> json) => AIUsage(
        promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
        completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
        model: json['model'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        if (model != null) 'model': model,
      };
}

/// A numeric fact the assistant is explaining.
///
/// Values here are always computed by SafeSpend, never by the model — see
/// `FinancialContextService`. Carrying them separately lets the UI render them
/// as data and keeps the model's role to explanation.
class AIFinancialInsight {
  final String label;
  final double value;
  final String? currency;
  final String? note;

  const AIFinancialInsight({
    required this.label,
    required this.value,
    this.currency,
    this.note,
  });

  factory AIFinancialInsight.fromJson(Map<String, dynamic> json) =>
      AIFinancialInsight(
        label: json['label'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String?,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        if (currency != null) 'currency': currency,
        if (note != null) 'note': note,
      };
}

class AIResponse {
  final AIResponseType type;
  final String text;
  final List<AIToolCall> toolCalls;
  final List<AISuggestion> suggestions;
  final List<AIFinancialInsight> insights;
  final AIUsage? usage;

  /// Set when [type] is [AIResponseType.error].
  final AIException? error;

  /// Echoed back so the UI can thread the reply.
  final String? conversationId;

  const AIResponse({
    this.type = AIResponseType.text,
    this.text = '',
    this.toolCalls = const [],
    this.suggestions = const [],
    this.insights = const [],
    this.usage,
    this.error,
    this.conversationId,
  });

  const AIResponse.text(String text, {String? conversationId})
      : this(
            type: AIResponseType.text,
            text: text,
            conversationId: conversationId);

  AIResponse.failure(AIException error)
      : this(
          type: AIResponseType.error,
          text: error.message,
          error: error,
        );

  bool get hasToolCalls => toolCalls.isNotEmpty;

  /// True when at least one requested tool mutates data, so the UI must confirm
  /// before anything executes.
  bool get requiresConfirmation =>
      type == AIResponseType.confirmationRequired;

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    final calls = (json['tool_calls'] as List?)
            ?.whereType<Map>()
            .map((e) => AIToolCall.fromJson(e.cast<String, dynamic>()))
            .toList() ??
        const <AIToolCall>[];
    return AIResponse(
      type: _parseType(json['type'] as String?, hasCalls: calls.isNotEmpty),
      text: json['text'] as String? ?? '',
      toolCalls: calls,
      suggestions: (json['suggestions'] as List?)
              ?.whereType<Map>()
              .map((e) => AISuggestion.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      insights: (json['insights'] as List?)
              ?.whereType<Map>()
              .map((e) =>
                  AIFinancialInsight.fromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      usage: json['usage'] is Map
          ? AIUsage.fromJson((json['usage'] as Map).cast<String, dynamic>())
          : null,
      conversationId: json['conversation_id'] as String?,
    );
  }

  static AIResponseType _parseType(String? raw, {required bool hasCalls}) {
    switch (raw) {
      case 'tool_call':
        return AIResponseType.toolCall;
      case 'confirmation_required':
        return AIResponseType.confirmationRequired;
      case 'financial_insight':
        return AIResponseType.financialInsight;
      case 'error':
        return AIResponseType.error;
      case 'text':
        return AIResponseType.text;
      default:
        return hasCalls ? AIResponseType.toolCall : AIResponseType.text;
    }
  }
}

/// Incremental events for streamed replies.
sealed class AIStreamEvent {
  const AIStreamEvent();
}

/// A chunk of assistant text.
class AITextDelta extends AIStreamEvent {
  final String text;
  const AITextDelta(this.text);
}

/// A fully-formed tool call arrived mid-stream.
class AIToolCallEvent extends AIStreamEvent {
  final AIToolCall call;
  const AIToolCallEvent(this.call);
}

/// Terminal event carrying the assembled response.
class AIStreamDone extends AIStreamEvent {
  final AIResponse response;
  const AIStreamDone(this.response);
}

/// Terminal event for a failed stream.
class AIStreamError extends AIStreamEvent {
  final AIException error;
  const AIStreamError(this.error);
}
