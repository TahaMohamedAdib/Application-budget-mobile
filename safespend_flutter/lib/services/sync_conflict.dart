import 'package:flutter/foundation.dart';

/// Which side wins when the same record was edited on two devices offline.
enum SyncResolution {
  /// The local (incoming) write is newer or equal — proceed with the upsert.
  applyLocal,

  /// The remote row is newer — keep it, skip the local upsert.
  keepRemote,
}

/// Pure last-write-wins decision for a single synchronized record.
///
/// No field-level merge: the more recent `updated_at` wins wholesale. Ties go to
/// the local write so an in-progress save is never dropped. Missing/unparseable
/// timestamps are treated as "unknown" and default to applying the local write
/// (the historical behaviour before conflict detection existed), so a device
/// that has not yet received the `updated_at` migration keeps working.
class SyncConflictResolver {
  const SyncConflictResolver();

  /// Decides whether to apply the local write given the two `updated_at`
  /// values, as ISO-8601 strings (either may be null/absent).
  SyncResolution resolve({
    required String? localUpdatedAt,
    required String? remoteUpdatedAt,
    String entity = 'record',
    String? id,
  }) {
    final local = _parse(localUpdatedAt);
    final remote = _parse(remoteUpdatedAt);

    // No remote row, or remote timestamp unknown → nothing newer to protect.
    if (remote == null) return SyncResolution.applyLocal;
    // Local timestamp unknown → cannot prove local is newer; be conservative
    // and still apply local (matches pre-existing upsert behaviour) but log it.
    if (local == null) {
      _log(entity, id, local, remote, SyncResolution.applyLocal,
          note: 'local timestamp missing');
      return SyncResolution.applyLocal;
    }

    if (remote.isAfter(local)) {
      _log(entity, id, local, remote, SyncResolution.keepRemote);
      return SyncResolution.keepRemote;
    }

    // local >= remote → local wins (ties included).
    return SyncResolution.applyLocal;
  }

  static DateTime? _parse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  void _log(
    String entity,
    String? id,
    DateTime? local,
    DateTime? remote,
    SyncResolution winner, {
    String? note,
  }) {
    if (!kDebugMode) return;
    final idPart = id == null ? '' : ' id=$id';
    final notePart = note == null ? '' : ' ($note)';
    debugPrint(
      '[Sync conflict] $entity$idPart local=${local?.toIso8601String()} '
      'remote=${remote?.toIso8601String()} → '
      '${winner == SyncResolution.keepRemote ? 'KEEP REMOTE' : 'APPLY LOCAL'}'
      '$notePart',
    );
  }
}
