/// A tool invocation requested by the model.
///
/// Arguments are raw model output and are **never** trusted: the executor
/// validates every field, and identity-bearing arguments (user id, auth token)
/// are ignored entirely in favour of the authenticated session.
class AIToolCall {
  /// Correlation id so a result can be matched back to its call.
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const AIToolCall({
    required this.id,
    required this.name,
    this.arguments = const {},
  });

  factory AIToolCall.fromJson(Map<String, dynamic> json) => AIToolCall(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? json['tool'] as String? ?? '',
        arguments: (json['arguments'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arguments': arguments,
      };
}

/// Outcome of running a tool, sent back to the model on the next turn.
class AIToolResult {
  final String callId;
  final String name;
  final bool ok;

  /// Structured payload on success.
  final Map<String, dynamic>? data;

  /// Machine-readable failure reason on error (see [AIErrorKind] names).
  final String? errorCode;

  /// Short human-readable failure reason, safe to show a user.
  final String? errorMessage;

  const AIToolResult({
    required this.callId,
    required this.name,
    required this.ok,
    this.data,
    this.errorCode,
    this.errorMessage,
  });

  factory AIToolResult.success(
    AIToolCall call,
    Map<String, dynamic> data,
  ) =>
      AIToolResult(callId: call.id, name: call.name, ok: true, data: data);

  factory AIToolResult.failure(
    AIToolCall call, {
    required String code,
    required String message,
  }) =>
      AIToolResult(
        callId: call.id,
        name: call.name,
        ok: false,
        errorCode: code,
        errorMessage: message,
      );

  Map<String, dynamic> toJson() => {
        'call_id': callId,
        'name': name,
        'ok': ok,
        if (data != null) 'data': data,
        if (errorCode != null) 'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
      };
}
