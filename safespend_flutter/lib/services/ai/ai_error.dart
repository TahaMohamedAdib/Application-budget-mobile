/// Failure categories the UI is allowed to distinguish.
///
/// Raw provider/model exceptions never reach the UI — implementations map them
/// onto one of these so the Coach can react (retry, re-auth, back off) without
/// pattern-matching on vendor error strings.
enum AIErrorKind {
  network,
  backendUnavailable,
  authExpired,
  rateLimited,
  invalidToolRequest,
  toolExecutionFailed,
  voiceConnectionFailed,
  attachmentFailed,
  notConfigured,
  unknown,
}

class AIException implements Exception {
  final AIErrorKind kind;

  /// Safe to display. Never contains provider payloads or stack traces.
  final String message;

  /// Diagnostic detail for logs only.
  final Object? cause;

  const AIException(this.kind, this.message, {this.cause});

  /// Default user-facing copy per category, so every implementation surfaces
  /// the same wording for the same failure.
  factory AIException.of(AIErrorKind kind, {Object? cause}) {
    final message = switch (kind) {
      AIErrorKind.network =>
        'Connection problem. Check your internet and try again.',
      AIErrorKind.backendUnavailable =>
        'SafeSpend AI is temporarily unavailable. Please try again shortly.',
      AIErrorKind.authExpired => 'Your session expired. Please sign in again.',
      AIErrorKind.rateLimited =>
        'SafeSpend AI is busy right now. Please wait a moment and try again.',
      AIErrorKind.invalidToolRequest =>
        "I couldn't complete that action — the request was incomplete.",
      AIErrorKind.toolExecutionFailed =>
        "That action couldn't be completed. Nothing was changed.",
      AIErrorKind.voiceConnectionFailed =>
        'Voice connection lost. Please try again.',
      AIErrorKind.attachmentFailed =>
        "That file couldn't be read. Try a different one.",
      AIErrorKind.notConfigured =>
        'SafeSpend AI is not configured yet. Please contact support.',
      AIErrorKind.unknown => 'Something went wrong. Please try again later.',
    };
    return AIException(kind, message, cause: cause);
  }

  /// Whether retrying the same request could plausibly succeed.
  bool get isRetryable => switch (kind) {
        AIErrorKind.network ||
        AIErrorKind.backendUnavailable ||
        AIErrorKind.rateLimited ||
        AIErrorKind.voiceConnectionFailed =>
          true,
        _ => false,
      };

  @override
  String toString() => 'AIException(${kind.name}): $message';
}
