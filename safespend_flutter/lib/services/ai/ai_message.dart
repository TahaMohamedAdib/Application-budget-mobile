import 'ai_attachment.dart';
import 'ai_tool_call.dart';

enum AIRole { user, assistant, tool }

/// One turn in a conversation, independent of any provider's wire format.
class AIMessage {
  final AIRole role;
  final String text;
  final List<AIAttachment> attachments;

  /// Tool calls the assistant requested on this turn.
  final List<AIToolCall> toolCalls;

  /// Result being handed back to the model, set on [AIRole.tool] messages.
  final AIToolResult? toolResult;

  final DateTime? createdAt;

  const AIMessage({
    required this.role,
    this.text = '',
    this.attachments = const [],
    this.toolCalls = const [],
    this.toolResult,
    this.createdAt,
  });

  const AIMessage.user(String text, {List<AIAttachment> attachments = const []})
      : this(role: AIRole.user, text: text, attachments: attachments);

  const AIMessage.assistant(String text,
      {List<AIToolCall> toolCalls = const []})
      : this(role: AIRole.assistant, text: text, toolCalls: toolCalls);

  AIMessage.toolResult(AIToolResult result)
      : this(role: AIRole.tool, toolResult: result);

  bool get hasAttachments => attachments.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
        if (toolCalls.isNotEmpty)
          'tool_calls': toolCalls.map((c) => c.toJson()).toList(),
        if (toolResult != null) 'tool_result': toolResult!.toJson(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
