import 'dart:typed_data';

import '../financial_context_service.dart';
import 'voice_audio_event.dart';

/// Bidirectional audio link to the voice backend.
///
/// Abstracted so WebSocket and WebRTC can be swapped without touching session
/// logic. No implementation ships yet — the Qwen3-Omni backend does not exist.
abstract class VoiceTransport {
  /// Events from the backend. Broadcast: UI and session logic both listen.
  Stream<VoiceAudioEvent> get events;

  bool get isConnected;

  /// Opens the link and starts a session.
  ///
  /// [context] is the same snapshot text chat sends, so the voice model starts
  /// with the user's real figures instead of asking for them.
  Future<void> connect({
    required FinancialContext context,
    String? conversationId,
  });

  /// Pushes captured microphone audio.
  void sendAudio(Uint8List chunk);

  /// Signals the user stopped talking, for backends that need an explicit
  /// end-of-turn rather than server-side VAD.
  void endTurn();

  /// Asks the backend to stop generating — the barge-in path.
  void interrupt();

  Future<void> disconnect();
}
