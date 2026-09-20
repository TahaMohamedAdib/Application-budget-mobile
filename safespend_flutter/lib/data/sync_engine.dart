import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
// `foundation` exports a `Category` annotation class that shadows the app's
// Category model; nothing here uses the annotation.
import 'package:flutter/foundation.dart' hide Category;

import '../models/account.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import '../services/supabase_sync_service.dart';
import 'entity_mappers.dart';
import 'local_repository.dart';
import 'sync_queue.dart';

/// What the UI shows about synchronisation.
enum SyncPhase { idle, syncing, offline, error }

/// A snapshot of sync state for the UI.
///
/// Deliberately coarse: users care whether their work is safe, not which of
/// forty operations is in flight.
@immutable
class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final SyncPhase phase;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  bool get hasPendingWork => pendingCount > 0;

  SyncStatusSnapshot copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncStatusSnapshot(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// How a push failed, which decides whether retrying can ever help.
enum _FailureKind {
  /// No route to the server. Not the operation's fault; retry when back.
  network,

  /// The server understood and refused. Retrying sends the identical bytes
  /// and gets the identical refusal, so the task is parked instead.
  permanent,

  /// Server-side fault or something unrecognised. Retried with backoff.
  transient,
}

/// Drains the sync queue and pulls server changes.
///
/// One worker, serialised. Two concurrent drains would race on the same queue
/// rows and could apply an update before the create it depends on, so
/// [_draining] gates the whole cycle rather than any individual request.
class SyncEngine {
  SyncEngine({
    required LocalRepository repository,
    Connectivity? connectivity,
  })  : _repository = repository,
        _connectivity = connectivity ?? Connectivity();

  final LocalRepository _repository;
  final Connectivity _connectivity;

  final ValueNotifier<SyncStatusSnapshot> status =
      ValueNotifier(const SyncStatusSnapshot());

  StreamSubscription<dynamic>? _connectivitySubscription;
  Timer? _periodicTimer;
  String? _userId;
  bool _draining = false;

  /// A drain arriving while one is running sets this instead of queueing a
  /// second worker, so the running cycle finishes and immediately repeats.
  bool _rerunRequested = false;

  /// A safety net for the case where connectivity events are missed — some
  /// Android builds do not emit one when a captive portal is signed into.
  static const Duration _periodicInterval = Duration(minutes: 5);

  /// Starts syncing for [userId].
  ///
  /// Recovers tasks stranded by a previous crash before anything else: they
  /// were mid-flight when the process died, and leaving them would silently
  /// drop the user's work.
  Future<void> start(String userId) async {
    if (_userId == userId && _connectivitySubscription != null) return;
    await stop();
    _userId = userId;

    await _repository.queue.recoverStuckTasks();
    await _refreshCounts();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((_) => sync());
    _periodicTimer = Timer.periodic(_periodicInterval, (_) => sync());

    unawaited(sync());
  }

  Future<void> stop() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _userId = null;
  }

  void dispose() {
    unawaited(stop());
    status.dispose();
  }

  /// Moves permanently-failed tasks back into the queue and syncs at once.
  ///
  /// A task that failed permanently (a rejected write, a constraint violation)
  /// stops retrying on its own by design, so without this the user's only
  /// route out is to discard the work. The UI offers this behind the failed
  /// count so a fixable server-side cause can be retried after it is fixed.
  Future<void> retryFailed() async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.queue.retryFailed(userId);
    await _refreshCounts();
    await sync();
  }

  /// Runs one full cycle: push everything queued, then pull server changes.
  ///
  /// Push before pull, always. Pulling first would hand the local row a server
  /// state that predates the user's queued edit, and while the edit still wins
  /// (its row is dirty), the user would watch their value flicker to the old
  /// one and back.
  Future<void> sync() async {
    final userId = _userId;
    if (userId == null) return;

    if (_draining) {
      _rerunRequested = true;
      return;
    }
    _draining = true;

    try {
      do {
        _rerunRequested = false;

        if (!await _isOnline()) {
          _emit(phase: SyncPhase.offline);
          return;
        }

        _emit(phase: SyncPhase.syncing, clearError: true);

        final pushOk = await _push(userId);
        if (!pushOk) return;

        await _pull(userId);

        _emit(phase: SyncPhase.idle, lastSyncedAt: DateTime.now());
      } while (_rerunRequested);
    } catch (error) {
      _emit(phase: SyncPhase.error, lastError: _describe(error));
    } finally {
      _draining = false;
      await _refreshCounts();
    }
  }

  /// Sends queued operations in order.
  ///
  /// Returns false when the network dropped mid-drain, so the caller skips the
  /// pull rather than following a half-finished push with a pull that would
  /// look like server state disagreeing with local state.
  Future<bool> _push(String userId) async {
    while (true) {
      final batch = await _repository.queue.claimBatch(userId: userId);
      if (batch.isEmpty) return true;

      for (final task in batch) {
        await _repository.queue.markInFlight(task.id);
        try {
          await _execute(userId, task);
          await _repository.queue.complete(task.id);

          if (task.operation == SyncOperation.delete) {
            await _repository.purgeTombstone(
              userId: userId,
              table: task.entityType,
              id: task.entityId,
            );
          } else {
            await _repository.markSynced(
              userId: userId,
              table: task.entityType,
              id: task.entityId,
              pushedUpdatedAt: task.updatedAt.millisecondsSinceEpoch,
            );
          }
        } catch (error) {
          final kind = _classify(error);

          if (kind == _FailureKind.network) {
            // Put the task back untouched. A dropped connection is not a
            // failed attempt, and counting it would burn the retry budget
            // during an ordinary tunnel journey.
            await _repository.queue.fail(task.id, error: _describe(error));
            _emit(phase: SyncPhase.offline);
            return false;
          }

          await _repository.queue.fail(
            task.id,
            error: _describe(error),
            permanent: kind == _FailureKind.permanent,
          );

          // Ordering is only guaranteed within an entity's own history, so a
          // sibling's failure must not stop the rest of the batch.
          continue;
        }
      }
      await _refreshCounts();
    }
  }

  /// Performs one queued operation against the server.
  ///
  /// Routes through the existing [SupabaseSyncService], which already knows
  /// each entity's remote table name and row shape. Reusing it keeps one
  /// definition of the wire format rather than a second that can drift.
  Future<void> _execute(String userId, SyncTask task) async {
    final payload = task.payload;

    switch (task.entityType) {
      case EntityType.accounts:
        if (task.operation == SyncOperation.delete) {
          await SupabaseSyncService.deleteAccountRemote(userId, task.entityId);
        } else {
          await SupabaseSyncService.saveAccountRemote(
            userId,
            _decodeAccount(payload!),
          );
        }
      case EntityType.transactions:
        if (task.operation == SyncOperation.delete) {
          await SupabaseSyncService.deleteTransactionRemote(
            userId,
            task.entityId,
          );
        } else {
          await SupabaseSyncService.saveTransactionRemote(
            userId,
            _decodeTransaction(payload!),
          );
        }
      case EntityType.goals:
        if (task.operation == SyncOperation.delete) {
          await SupabaseSyncService.deleteGoalRemote(userId, task.entityId);
        } else {
          await SupabaseSyncService.saveGoalRemote(
            userId,
            _decodeGoal(payload!),
          );
        }
      case EntityType.holdings:
        if (task.operation == SyncOperation.delete) {
          await SupabaseSyncService.deleteHoldingRemote(userId, task.entityId);
        } else {
          await SupabaseSyncService.saveHoldingRemote(
            userId,
            _decodeHolding(payload!),
          );
        }
      case EntityType.categories:
        if (task.operation == SyncOperation.delete) {
          await SupabaseSyncService.deleteCategoryRemote(userId, task.entityId);
        } else {
          await SupabaseSyncService.saveCategoryRemote(
            userId,
            _decodeCategory(payload!),
          );
        }
      case EntityType.recurringRules:
        if (task.operation == SyncOperation.delete) {
          await SupabaseSyncService.deleteRecurringRuleRemote(
            userId,
            task.entityId,
          );
        } else {
          await SupabaseSyncService.saveRecurringRuleRemote(
            userId,
            _decodeRecurringRule(payload!),
          );
        }
      case EntityType.settings:
        await SupabaseSyncService.saveProfileRemoteFromJson(userId, payload!);
      case EntityType.darets:
        // No remote table exists for darets yet, so there is nothing to push.
        // The row stays local and its queue entry completes, rather than
        // retrying forever against an endpoint that does not exist.
        return;
      default:
        return;
    }
  }

  // Payload decoders. The queue stores each entity's own `toJson`, so its
  // `fromJson` is the exact inverse and no second format exists to drift.

  Account _decodeAccount(Map<String, dynamic> json) => Account.fromJson(json);

  Transaction _decodeTransaction(Map<String, dynamic> json) =>
      Transaction.fromJson(json);

  Goal _decodeGoal(Map<String, dynamic> json) => Goal.fromJson(json);

  Holding _decodeHolding(Map<String, dynamic> json) => Holding.fromJson(json);

  Category _decodeCategory(Map<String, dynamic> json) =>
      Category.fromJson(json);

  RecurringRule _decodeRecurringRule(Map<String, dynamic> json) =>
      RecurringRule.fromJson(json);

  /// Pulls server changes into the local database.
  ///
  /// Incremental where the server supports it. Rows whose local copy is dirty
  /// are skipped by the repository, so a pull can never overwrite work the
  /// user has not yet had pushed.
  Future<void> _pull(String userId) async {
    // Delegated to the existing loaders, which return fully-formed models.
    // Each row is applied individually so the dirty check runs per entity
    // rather than per table.
    await _pullEntity<Account>(
      userId: userId,
      entityType: EntityType.accounts,
      load: () => SupabaseSyncService.loadAccounts(userId),
      idOf: (a) => a.id,
      rowOf: EntityMappers.accountToRow,
    );
    await _pullEntity<Category>(
      userId: userId,
      entityType: EntityType.categories,
      load: () => SupabaseSyncService.loadCategories(userId),
      idOf: (c) => c.id,
      rowOf: EntityMappers.categoryToRow,
    );
    await _pullEntity<Transaction>(
      userId: userId,
      entityType: EntityType.transactions,
      load: () => SupabaseSyncService.loadTransactions(userId),
      idOf: (t) => t.id,
      rowOf: EntityMappers.transactionToRow,
    );
    await _pullEntity<Goal>(
      userId: userId,
      entityType: EntityType.goals,
      load: () => SupabaseSyncService.loadGoals(userId),
      idOf: (g) => g.id,
      rowOf: EntityMappers.goalToRow,
    );
    await _pullEntity<Holding>(
      userId: userId,
      entityType: EntityType.holdings,
      load: () => SupabaseSyncService.loadHoldings(userId),
      idOf: (h) => h.id,
      rowOf: EntityMappers.holdingToRow,
    );
    await _pullEntity<RecurringRule>(
      userId: userId,
      entityType: EntityType.recurringRules,
      load: () => SupabaseSyncService.loadRecurringRules(userId),
      idOf: (r) => r.id,
      rowOf: EntityMappers.recurringRuleToRow,
    );
  }

  Future<void> _pullEntity<T>({
    required String userId,
    required String entityType,
    required Future<List<T>> Function() load,
    required String Function(T) idOf,
    required Map<String, Object?> Function(T) rowOf,
  }) async {
    final List<T> remote;
    try {
      remote = await load();
    } catch (error) {
      // One entity failing to pull must not abort the others; the cursor is
      // left untouched so the next cycle retries this type.
      debugPrint('sync: pull failed for $entityType: ${_describe(error)}');
      return;
    }

    final pulledAt = DateTime.now().millisecondsSinceEpoch;
    for (final item in remote) {
      await _repository.applyRemote(
        userId: userId,
        table: entityType,
        id: idOf(item),
        row: rowOf(item),
        remoteUpdatedAt: pulledAt,
      );
    }
    await _repository.setLastPulledAt(
      userId,
      entityType,
      DateTime.fromMillisecondsSinceEpoch(pulledAt),
    );
  }

  // Connectivity.

  /// Whether a sync is worth attempting.
  ///
  /// `connectivity_plus` reports the radio, not reachability: a phone attached
  /// to a hotel wifi that has not been signed into reports `wifi` while every
  /// request fails. So this is used only to skip obviously pointless attempts;
  /// the real verdict comes from whether the request succeeds, which is why a
  /// network failure during a push re-queues rather than parks.
  Future<bool> _isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Unknown, so assume online and let the request decide. Assuming offline
      // would strand the queue on any device where the plugin misbehaves.
      return true;
    }
  }

  _FailureKind _classify(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection closed') ||
        text.contains('connection refused') ||
        text.contains('timeoutexception') ||
        text.contains('clientexception')) {
      return _FailureKind.network;
    }

    // Postgres/PostgREST rejections that a retry cannot change: constraint
    // violations, malformed rows, and RLS refusals.
    if (text.contains('violates row-level security') ||
        text.contains('duplicate key') ||
        text.contains('violates foreign key') ||
        text.contains('violates check constraint') ||
        text.contains('invalid input syntax') ||
        text.contains('permission denied')) {
      return _FailureKind.permanent;
    }

    return _FailureKind.transient;
  }

  String _describe(Object error) {
    final text = error.toString();
    return text.length > 500 ? '${text.substring(0, 500)}…' : text;
  }

  Future<void> _refreshCounts() async {
    final userId = _userId;
    if (userId == null) return;
    final pending = await _repository.queue.pendingCount(userId);
    final failed = (await _repository.queue.failedTasks(userId)).length;
    _emit(pendingCount: pending, failedCount: failed);
  }

  void _emit({
    SyncPhase? phase,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    status.value = status.value.copyWith(
      phase: phase,
      pendingCount: pendingCount,
      failedCount: failedCount,
      lastSyncedAt: lastSyncedAt,
      lastError: lastError,
      clearError: clearError,
    );
  }
}
