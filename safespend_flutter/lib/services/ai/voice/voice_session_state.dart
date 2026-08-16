/// Lifecycle of a realtime voice conversation.
///
/// Mirrors what the user sees, so the Coach can drive its mic UI from this
/// single value rather than a spread of booleans.
enum VoiceSessionState {
  /// No session. Mic closed, nothing connected.
  idle,

  /// Opening the transport and negotiating the session.
  connecting,

  /// Mic open, streaming audio up.
  listening,

  /// Turn ended; the backend is thinking. No audio flowing either way.
  processing,

  /// Assistant audio is playing back.
  speaking,

  /// User spoke over the assistant; playback stopped mid-utterance.
  interrupted,

  /// Session failed. See `VoiceSessionService.lastError`.
  error,
}

extension VoiceSessionStateX on VoiceSessionState {
  /// Whether the mic should be capturing.
  bool get isCapturing => this == VoiceSessionState.listening;

  /// Whether a barge-in is possible right now.
  bool get canInterrupt =>
      this == VoiceSessionState.speaking ||
      this == VoiceSessionState.processing;

  /// Whether the session is live in any form.
  bool get isActive => switch (this) {
        VoiceSessionState.idle || VoiceSessionState.error => false,
        _ => true,
      };
}
