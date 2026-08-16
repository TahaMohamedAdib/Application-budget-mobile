import 'dart:typed_data';

import '../ai_error.dart';
import '../ai_tool_call.dart';

/// Events flowing from the backend during a voice session.
///
/// Transport-neutral: a WebSocket or WebRTC implementation both decode into
/// these, so `VoiceSessionService` never sees frames or data channels.
sealed class VoiceAudioEvent {
  const VoiceAudioEvent();
}

/// A chunk of assistant speech to play. Chunks arrive faster than realtime and
/// are queued by the player.
class VoiceAudioChunk extends VoiceAudioEvent {
  final Uint8List bytes;

  /// e.g. `audio/pcm;rate=24000`, `audio/opus`.
  final String mimeType;

  const VoiceAudioChunk(this.bytes, {required this.mimeType});
}

/// Live transcript. [isFinal] marks a settled segment rather than a guess
/// that may still be revised.
class VoiceTranscript extends VoiceAudioEvent {
  final String text;
  final bool isUser;
  final bool isFinal;

  const VoiceTranscript(this.text, {required this.isUser, this.isFinal = false});
}

/// Backend detected the user speaking over playback; stop audio immediately.
class VoiceInterrupted extends VoiceAudioEvent {
  const VoiceInterrupted();
}

/// The assistant wants to run a SafeSpend tool. Routed through the same
/// executor and confirmation flow as text — spoken intent grants no extra
/// authority to mutate data.
class VoiceToolCallEvent extends VoiceAudioEvent {
  final AIToolCall call;
  const VoiceToolCallEvent(this.call);
}

/// The assistant finished its turn.
class VoiceTurnComplete extends VoiceAudioEvent {
  const VoiceTurnComplete();
}

/// Session-level failure.
class VoiceErrorEvent extends VoiceAudioEvent {
  final AIException error;
  const VoiceErrorEvent(this.error);
}
