import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../ai_error.dart';
import '../ai_tool_call.dart';
import '../financial_context_service.dart';
import 'voice_audio_event.dart';
import 'voice_session_state.dart';
import 'voice_transport.dart';

/// Drives a realtime voice conversation and exposes it as a listenable state
/// machine the Coach can bind to.
///
/// Owns *orchestration only* — no audio capture, no playback, no transport.
/// Those arrive with the Qwen3-Omni backend; this class exists now so the UI
/// and the tool/confirmation flow can be built against a stable surface.
///
/// Tool calls raised by voice are surfaced through [onToolCall] and go through
/// the same executor and confirmation as typed requests. Speaking a mutation
/// does not bypass approval.
class VoiceSessionService extends ChangeNotifier {
  final VoiceTransport transport;

  /// Invoked when the assistant requests a SafeSpend tool.
  final void Function(AIToolCall call)? onToolCall;

  VoiceSessionService({required this.transport, this.onToolCall});

  VoiceSessionState _state = VoiceSessionState.idle;
  VoiceSessionState get state => _state;

  AIException? _lastError;
  AIException? get lastError => _lastError;

  final StringBuffer _userTranscript = StringBuffer();
  final StringBuffer _assistantTranscript = StringBuffer();

  /// Best-effort transcript of what the user said this turn.
  String get userTranscript => _userTranscript.toString();

  /// Best-effort transcript of the assistant's reply.
  String get assistantTranscript => _assistantTranscript.toString();

  StreamSubscription<VoiceAudioEvent>? _sub;

  /// Assistant audio ready to play, in arrival order. A player drains this;
  /// [interrupt] clears it so a barge-in cuts off instantly rather than after
  /// the buffer finishes.
  final List<VoiceAudioChunk> pendingPlayback = [];

  Future<void> start({
    required FinancialContext context,
    String? conversationId,
  }) async {
    if (_state.isActive) return;
    _setState(VoiceSessionState.connecting);
    _lastError = null;
    _userTranscript.clear();
    _assistantTranscript.clear();

    try {
      _sub = transport.events.listen(_onEvent, onError: (Object e) {
        _fail(AIException.of(AIErrorKind.voiceConnectionFailed, cause: e));
      });
      await transport.connect(
          context: context, conversationId: conversationId);
      _setState(VoiceSessionState.listening);
    } catch (e) {
      _fail(AIException.of(AIErrorKind.voiceConnectionFailed, cause: e));
    }
  }

  /// Feeds a microphone chunk upstream. Ignored unless listening, so audio
  /// captured during playback isn't echoed back as input.
  void pushAudio(Uint8List chunk) {
    if (_state != VoiceSessionState.listening) return;
    transport.sendAudio(chunk);
  }

  /// Marks the end of the user's turn.
  void endTurn() {
    if (_state != VoiceSessionState.listening) return;
    transport.endTurn();
    _setState(VoiceSessionState.processing);
  }

  /// Barge-in: stop the assistant and hand the floor back to the user.
  void interrupt() {
    if (!_state.canInterrupt) return;
    pendingPlayback.clear();
    transport.interrupt();
    _setState(VoiceSessionState.interrupted);
    // Interruption is transient — the user is expected to speak next.
    _setState(VoiceSessionState.listening);
  }

  Future<void> stop() async {
    _sub?.cancel();
    _sub = null;
    pendingPlayback.clear();
    await transport.disconnect();
    _setState(VoiceSessionState.idle);
  }

  void _onEvent(VoiceAudioEvent event) {
    switch (event) {
      case VoiceAudioChunk chunk:
        pendingPlayback.add(chunk);
        if (_state != VoiceSessionState.speaking) {
          _setState(VoiceSessionState.speaking);
        } else {
          notifyListeners();
        }
      case VoiceTranscript t:
        (t.isUser ? _userTranscript : _assistantTranscript).write(t.text);
        notifyListeners();
      case VoiceInterrupted():
        pendingPlayback.clear();
        _setState(VoiceSessionState.listening);
      case VoiceToolCallEvent e:
        onToolCall?.call(e.call);
      case VoiceTurnComplete():
        _assistantTranscript.clear();
        _userTranscript.clear();
        _setState(VoiceSessionState.listening);
      case VoiceErrorEvent e:
        _fail(e.error);
    }
  }

  void _fail(AIException error) {
    _lastError = error;
    pendingPlayback.clear();
    _setState(VoiceSessionState.error);
  }

  void _setState(VoiceSessionState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    transport.disconnect();
    super.dispose();
  }
}
