import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'local_database.dart';

/// What a queued operation asks the server to do.
enum SyncOperation { upsert, delete }

/// Where a queued operation stands.
///
/// `pending` is the only status the worker picks up. `failed` is terminal
/// until a human or a fresh edit intervenes: it means the server rejected the
/// operation in a way that retrying cannot fix (a validation error, a row the
/// user no longer owns), so spinning on it would burn battery forever.
enum SyncStatus { pending, inFlight, failed }

/// One durable unit of work: "push this entity to the server".
///
/// The payload is the entity's full current state rather than a diff, which
/// makes every operation idempotent. Re-sending it after an ambiguous failure
/// converges on the same row instead of double-applying a delta, so a timeout
/// whose request actually succeeded costs nothing.
class SyncTask {
  const SyncTask({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.retryCount,
    required this.nextAttemptAt,
    required this.sequence,
    this.lastAttemptAt,
    this.lastError,
    this.status = SyncStatus.pending,
  });

  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final DateTime nextAttemptAt;
  final int sequence;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final SyncStatus status;

  factory SyncTask.fromRow(Map<String, Object?> row) {
    final rawPayload = row['payload'] as String?;
    return SyncTask(
      id: row['id']! as String,
      userId: row['user_id']! as String,
      entityType: row['entity_type']! as String,
      entityId: row['entity_id']! as String,
      operation: SyncOperation.values.firstWhere(
        (op) => op.name == row['operation'],
        orElse: () => SyncOperation.upsert,
      ),
      payload: rawPayload == null
          ? null
          : jsonDecode(rawPayload) as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
      retryCount: row['retry_count']! as int,
      nextAttemptAt:
          DateTime.fromMillisecondsSinceEpoch(row['next_attempt_at']! as int),
      sequence: row['sequence']! as int,
      lastAttemptAt: row['last_attempt_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['last_attempt_at']! as int),
      lastError: row['last_error'] as String?,
      status: SyncStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => SyncStatus.pending,
      ),
    );
  }
}

/// The durable outbox.
///
/// Every local mutation enqueues here inside the same database transaction
/// that writes the entity row. That atomicity is the whole point: the app can
/// never end up showing a change it has no record of needing to push, nor
/// queue a push for a change that was rolled back.
class SyncQueue {
  SyncQueue({LocalDatabase? database, Uuid? uuid})
      : _database = database ?? LocalDatabase.instance,
        _uuid = uuid ?? const Uuid();

  final LocalDatabase _database;
  final Uuid _uuid;

  /// Give up automatic retries after this many failures and mark the task
  /// `failed`, so the user can be told rather than left to wonder.
  static const int maxRetries = 8;

  /// Backoff schedule, indexed by retry count. Capped at five minutes: longer
  /// gaps only delay recovery, since a connectivity change triggers an
  /// immediate flush anyway.
  static const List<Duration> backoff = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  static Duration delayFor(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    final index = retryCount - 1;
    return index < backoff.length ? backoff[index] : backoff.last;
  }

  /// Enqueues a push, reusing an existing transaction when given one.
  ///
  /// Callers that are already inside a `db.transaction` MUST pass their
  /// executor as [txn]; opening a nested transaction on the same connection
  /// would deadlock.
  ///
  /// Repeated edits to one entity collapse onto a single pending row. Pushing
  /// three intermediate states of a transaction the user tweaked three times
  /// offline wastes requests when only the final state matters, and the
  /// full-state payload means the last write already carries everything.
  Future<void> enqueue({
    required String userId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    Map<String, dynamic>? payload,
    DatabaseExecutor? txn,
  }) async {
    final executor = txn ?? await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await executor.query(
      'sync_queue',
      columns: ['id', 'sequence'],
      where:
          'user_id = ? AND entity_type = ? AND entity_id = ? AND status != ?',
      whereArgs: [userId, entityType, entityId, SyncStatus.inFlight.name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Keep the original sequence so an entity that was created before
      // another still pushes before it, even when its payload is refreshed.
      await executor.update(
        'sync_queue',
        {
          'operation': operation.name,
          'payload': payload == null ? null : jsonEncode(payload),
          'updated_at': now,
          // A fresh local edit is new information, so the backoff earned by
          // the previous attempt no longer applies. Resetting also revives a
          // task that had been parked as `failed`.
          'retry_count': 0,
          'next_attempt_at': now,
          'last_error': null,
          'status': SyncStatus.pending.name,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return;
    }

    final nextSequence = await _nextSequence(executor);
    await executor.insert('sync_queue', {
      'id': _uuid.v4(),
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.name,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': now,
      'updated_at': now,
      'retry_count': 0,
      'next_attempt_at': now,
      'last_attempt_at': null,
      'last_error': null,
      'status': SyncStatus.pending.name,
      'sequence': nextSequence,
    });
  }

  /// A monotonic counter shared across users on this device.
  ///
  /// Ordering matters: an account must be created on the server before a
  /// transaction that references it, or the insert fails its foreign key.
  /// Wall-clock timestamps are not enough because two operations can land in
  /// the same millisecond.
  Future<int> _nextSequence(DatabaseExecutor executor) async {
    final result = await executor
        .rawQuery('SELECT COALESCE(MAX(sequence), 0) AS s FROM sync_queue');
    return ((result.first['s'] as int?) ?? 0) + 1;
  }

  /// The next batch of operations ready to attempt, oldest first.
  ///
  /// Excludes tasks whose backoff has not elapsed and tasks parked as
  /// `failed`, so a single poisoned operation never blocks the ones behind it.
  Future<List<SyncTask>> claimBatch({
    required String userId,
    int limit = 50,
    DateTime? now,
  }) async {
    final db = await _database.database;
    final cutoff = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final rows = await db.query(
      'sync_queue',
      where: 'user_id = ? AND status = ? AND next_attempt_at <= ?',
      whereArgs: [userId, SyncStatus.pending.name, cutoff],
      orderBy: 'sequence ASC',
      limit: limit,
    );
    return rows.map(SyncTask.fromRow).toList();
  }

  /// Marks a task as being attempted right now.
  Future<void> markInFlight(String taskId) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'sync_queue',
      {
        'status': SyncStatus.inFlight.name,
        'last_attempt_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Removes a task that the server accepted.
  Future<void> complete(String taskId) async {
    final db = await _database.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [taskId]);
  }

  /// Records a failed attempt and schedules the next one.
  ///
  /// [permanent] is for errors that retrying cannot fix — a 4xx validation
  /// rejection, or a row the server says this user does not own. Those park
  /// immediately instead of consuming the whole retry budget.
  Future<void> fail(
    String taskId, {
    required String error,
    bool permanent = false,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'sync_queue',
      columns: ['retry_count'],
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final retryCount = (rows.first['retry_count']! as int) + 1;
    final exhausted = permanent || retryCount >= maxRetries;
    final now = DateTime.now();

    await db.update(
      'sync_queue',
      {
        'retry_count': retryCount,
        'status':
            exhausted ? SyncStatus.failed.name : SyncStatus.pending.name,
        'next_attempt_at': exhausted
            ? now.millisecondsSinceEpoch
            : now.add(delayFor(retryCount)).millisecondsSinceEpoch,
        'last_error': error,
        'last_attempt_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Returns any `inFlight` tasks to `pending`.
  ///
  /// Called once at startup. A task left `inFlight` means the process died
  /// mid-request, so we cannot know whether the server applied it; because
  /// payloads are full-state and therefore idempotent, re-sending is safe and
  /// is the only way the change is not silently lost.
  Future<int> recoverStuckTasks() async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      'sync_queue',
      {
        'status': SyncStatus.pending.name,
        'next_attempt_at': now,
        'updated_at': now,
      },
      where: 'status = ?',
      whereArgs: [SyncStatus.inFlight.name],
    );
  }

  /// How many operations are waiting, for the UI's pending indicator.
  Future<int> pendingCount(String userId) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_queue WHERE user_id = ? AND status != ?',
      [userId, SyncStatus.failed.name],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Operations that gave up, so the UI can surface them rather than let the
  /// user believe work was saved to the server when it was not.
  Future<List<SyncTask>> failedTasks(String userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'sync_queue',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, SyncStatus.failed.name],
      orderBy: 'sequence ASC',
    );
    return rows.map(SyncTask.fromRow).toList();
  }

  /// Puts failed tasks back in line, for a user-initiated "try again".
  Future<void> retryFailed(String userId) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'sync_queue',
      {
        'status': SyncStatus.pending.name,
        'retry_count': 0,
        'next_attempt_at': now,
        'updated_at': now,
        'last_error': null,
      },
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, SyncStatus.failed.name],
    );
  }

  /// Discards every queued operation for a user.
  ///
  /// Destructive: the local rows stay but their changes will never reach the
  /// server. Only call this behind an explicit confirmation, never as silent
  /// cleanup.
  Future<void> discardAll(String userId) async {
    final db = await _database.database;
    await db.delete('sync_queue', where: 'user_id = ?', whereArgs: [userId]);
  }
}
