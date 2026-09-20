import 'dart:convert';

// sqflite exports its own `Transaction` (a DB transaction handle), which
// collides with the app's model of the same name. The model wins here; the DB
// handle is only ever used via the `DatabaseExecutor` supertype.
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../models/account.dart';
import '../models/category.dart';
import '../models/daret.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import 'entity_mappers.dart';
import 'local_database.dart';
import 'sync_queue.dart';

/// Identifiers used in the queue and in `sync_state`. They double as the
/// table names, which keeps the generic sync engine free of a lookup table.
class EntityType {
  const EntityType._();

  static const accounts = 'accounts';
  static const transactions = 'transactions';
  static const goals = 'goals';
  static const holdings = 'holdings';
  static const categories = 'categories';
  static const recurringRules = 'recurring_rules';
  static const darets = 'darets';
  static const settings = 'settings';
}

/// The app's data API: reads come from SQLite, writes go to SQLite and are
/// queued for the server.
///
/// Nothing here touches the network. That separation is what makes the app
/// genuinely offline-first rather than offline-tolerant: a create is complete
/// the moment this class returns, and whether the server has heard about it is
/// a background concern that never blocks the UI.
///
/// Every method takes a `userId` and every query filters on it. That is the
/// local half of the isolation guarantee — the server half is RLS, which this
/// cannot and does not replace.
class LocalRepository {
  LocalRepository({LocalDatabase? database, SyncQueue? queue})
      : _database = database ?? LocalDatabase.instance,
        _queue = queue ?? SyncQueue();

  final LocalDatabase _database;
  final SyncQueue _queue;

  SyncQueue get queue => _queue;

  Future<Database> get _db => _database.database;

  // Reads.
  //
  // All of them exclude tombstones: a soft-deleted row still exists so its
  // deletion can be pushed, but it is gone as far as the app is concerned.

  Future<List<Account>> accounts(String userId) async =>
      _readAll(userId, EntityType.accounts, EntityMappers.accountFromRow);

  Future<List<Transaction>> transactions(String userId) async => _readAll(
        userId,
        EntityType.transactions,
        EntityMappers.transactionFromRow,
        orderBy: 'date DESC',
      );

  Future<List<Goal>> goals(String userId) async =>
      _readAll(userId, EntityType.goals, EntityMappers.goalFromRow);

  Future<List<Holding>> holdings(String userId) async =>
      _readAll(userId, EntityType.holdings, EntityMappers.holdingFromRow);

  Future<List<Category>> categories(String userId) async =>
      _readAll(userId, EntityType.categories, EntityMappers.categoryFromRow);

  Future<List<RecurringRule>> recurringRules(String userId) async => _readAll(
        userId,
        EntityType.recurringRules,
        EntityMappers.recurringRuleFromRow,
      );

  Future<List<Daret>> darets(String userId) async =>
      _readAll(userId, EntityType.darets, EntityMappers.daretFromRow);

  Future<List<T>> _readAll<T>(
    String userId,
    String table,
    T Function(Map<String, Object?>) fromRow, {
    String? orderBy,
  }) async {
    final db = await _db;
    final rows = await db.query(
      table,
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: orderBy,
    );
    return rows.map(fromRow).toList();
  }

  /// The per-user settings blob, or null before one has been written.
  Future<Map<String, dynamic>?> settings(String userId) async {
    final db = await _db;
    final rows = await db.query(
      EntityType.settings,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data']! as String) as Map<String, dynamic>;
  }

  // Writes.
  //
  // Each one writes the entity row and enqueues its push inside a single
  // database transaction. If either half fails, both roll back, so the queue
  // can never disagree with the data.

  Future<void> saveAccount(String userId, Account account) => _upsert(
        userId: userId,
        table: EntityType.accounts,
        id: account.id,
        row: EntityMappers.accountToRow(account),
        payload: account.toJson(),
      );

  Future<void> saveTransaction(String userId, Transaction transaction) =>
      _upsert(
        userId: userId,
        table: EntityType.transactions,
        id: transaction.id,
        row: EntityMappers.transactionToRow(transaction),
        payload: transaction.toJson(),
      );

  Future<void> saveGoal(String userId, Goal goal) => _upsert(
        userId: userId,
        table: EntityType.goals,
        id: goal.id,
        row: EntityMappers.goalToRow(goal),
        payload: goal.toJson(),
      );

  Future<void> saveHolding(String userId, Holding holding) => _upsert(
        userId: userId,
        table: EntityType.holdings,
        id: holding.id,
        row: EntityMappers.holdingToRow(holding),
        payload: holding.toJson(),
      );

  Future<void> saveCategory(String userId, Category category) => _upsert(
        userId: userId,
        table: EntityType.categories,
        id: category.id,
        row: EntityMappers.categoryToRow(category),
        payload: category.toJson(),
      );

  Future<void> saveRecurringRule(String userId, RecurringRule rule) => _upsert(
        userId: userId,
        table: EntityType.recurringRules,
        id: rule.id,
        row: EntityMappers.recurringRuleToRow(rule),
        payload: rule.toJson(),
      );

  Future<void> saveDaret(String userId, Daret daret) => _upsert(
        userId: userId,
        table: EntityType.darets,
        id: daret.id,
        row: EntityMappers.daretToRow(daret),
        payload: daret.toJson(),
      );

  /// Writes several accounts at once, as one transaction and one queue entry
  /// per account.
  ///
  /// A transfer touches two balances; committing them separately would leave a
  /// window where money exists in neither account or in both.
  Future<void> saveAccounts(String userId, List<Account> accounts) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final account in accounts) {
        await _upsertIn(
          txn,
          userId: userId,
          table: EntityType.accounts,
          id: account.id,
          row: EntityMappers.accountToRow(account),
          payload: account.toJson(),
        );
      }
    });
  }

  Future<void> saveSettings(String userId, Map<String, dynamic> data) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert(
        EntityType.settings,
        {
          'user_id': userId,
          'data': jsonEncode(data),
          'updated_at': now,
          'dirty': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _queue.enqueue(
        userId: userId,
        entityType: EntityType.settings,
        entityId: userId,
        operation: SyncOperation.upsert,
        payload: data,
        txn: txn,
      );
    });
  }

  Future<void> _upsert({
    required String userId,
    required String table,
    required String id,
    required Map<String, Object?> row,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _upsertIn(
        txn,
        userId: userId,
        table: table,
        id: id,
        row: row,
        payload: payload,
      );
    });
  }

  Future<void> _upsertIn(
    DatabaseExecutor txn, {
    required String userId,
    required String table,
    required String id,
    required Map<String, Object?> row,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // `replace` rather than a read-then-branch: the primary key is
    // (user_id, id), so this is an upsert in one statement and cannot race
    // with a concurrent pull writing the same row.
    await txn.insert(
      table,
      {
        ...row,
        'user_id': userId,
        'updated_at': now,
        'deleted_at': null,
        'dirty': 1,
        // `version` is deliberately absent: a local edit does not know the
        // server's counter, and clearing it would discard the optimistic-lock
        // token the next push needs. `insert ... replace` would null it, so
        // the value is carried forward explicitly below.
        'version': await _existingVersion(txn, table, userId, id),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _queue.enqueue(
      userId: userId,
      entityType: table,
      entityId: id,
      operation: SyncOperation.upsert,
      payload: payload,
      txn: txn,
    );
  }

  Future<int?> _existingVersion(
    DatabaseExecutor txn,
    String table,
    String userId,
    String id,
  ) async {
    final rows = await txn.query(
      table,
      columns: ['version'],
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['version'] as int?;
  }

  // Deletes.
  //
  // Soft, always. A hard delete offline is invisible to the next pull, which
  // would faithfully re-insert the row the user just removed; the tombstone is
  // what carries the user's intent to the server.

  Future<void> deleteAccount(String userId, String id) =>
      _softDelete(userId, EntityType.accounts, id);

  Future<void> deleteTransaction(String userId, String id) =>
      _softDelete(userId, EntityType.transactions, id);

  Future<void> deleteGoal(String userId, String id) =>
      _softDelete(userId, EntityType.goals, id);

  Future<void> deleteHolding(String userId, String id) =>
      _softDelete(userId, EntityType.holdings, id);

  Future<void> deleteCategory(String userId, String id) =>
      _softDelete(userId, EntityType.categories, id);

  Future<void> deleteRecurringRule(String userId, String id) =>
      _softDelete(userId, EntityType.recurringRules, id);

  Future<void> deleteDaret(String userId, String id) =>
      _softDelete(userId, EntityType.darets, id);

  Future<void> _softDelete(String userId, String table, String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final updated = await txn.update(
        table,
        {'deleted_at': now, 'updated_at': now, 'dirty': 1},
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, id],
      );
      // Nothing to delete and nothing to tell the server about.
      if (updated == 0) return;

      await _queue.enqueue(
        userId: userId,
        entityType: table,
        entityId: id,
        operation: SyncOperation.delete,
        txn: txn,
      );
    });
  }

  // Sync-engine support.

  /// Rows the server has not acknowledged, used to warn before a sign-out
  /// that would strand them.
  Future<bool> hasUnsyncedChanges(String userId) async =>
      await _queue.pendingCount(userId) > 0;

  /// Applies a row that came from the server.
  ///
  /// Conflict rule: a local row with pending changes wins, because the user
  /// made those changes on this device and has seen them on screen. Silently
  /// replacing them with a server copy would be the app discarding the user's
  /// work — the one outcome offline support exists to prevent. The local
  /// change is still queued, so the server converges on it shortly.
  ///
  /// Returns true when the server row was written.
  Future<bool> applyRemote({
    required String userId,
    required String table,
    required String id,
    required Map<String, Object?> row,
    required int remoteUpdatedAt,
    int? remoteVersion,
    bool remoteDeleted = false,
  }) async {
    final db = await _db;
    return db.transaction<bool>((txn) async {
      final existing = await txn.query(
        table,
        columns: ['dirty', 'updated_at'],
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final isDirty = (existing.first['dirty'] as int? ?? 0) != 0;
        if (isDirty) return false;

        // Not dirty, so any difference is the server's to declare. Still
        // guard on the timestamp: an out-of-order or replayed pull must not
        // roll the row back to an older state.
        final localUpdatedAt = existing.first['updated_at'] as int? ?? 0;
        if (remoteUpdatedAt < localUpdatedAt) return false;
      }

      await txn.insert(
        table,
        {
          ...row,
          'id': id,
          'user_id': userId,
          'updated_at': remoteUpdatedAt,
          'version': remoteVersion,
          'deleted_at': remoteDeleted ? remoteUpdatedAt : null,
          'dirty': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    });
  }

  /// Marks a pushed row as acknowledged.
  ///
  /// Only clears `dirty` when the row has not changed since the push started;
  /// otherwise an edit made mid-flight would be marked clean and never sent.
  Future<void> markSynced({
    required String userId,
    required String table,
    required String id,
    required int pushedUpdatedAt,
    int? version,
  }) async {
    final db = await _db;
    await db.update(
      table,
      {'dirty': 0, if (version != null) 'version': version},
      where: 'user_id = ? AND id = ? AND updated_at <= ?',
      whereArgs: [userId, id, pushedUpdatedAt],
    );
  }

  /// Clears a tombstone once the server has confirmed the delete, since
  /// nothing needs it afterwards.
  Future<void> purgeTombstone({
    required String userId,
    required String table,
    required String id,
  }) async {
    final db = await _db;
    await db.delete(
      table,
      where: 'user_id = ? AND id = ? AND deleted_at IS NOT NULL AND dirty = 0',
      whereArgs: [userId, id],
    );
  }

  /// The incremental-pull cursor for one entity type.
  Future<DateTime?> lastPulledAt(String userId, String entityType) async {
    final db = await _db;
    final rows = await db.query(
      'sync_state',
      columns: ['last_pulled_at'],
      where: 'user_id = ? AND entity_type = ?',
      whereArgs: [userId, entityType],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.first['last_pulled_at'] as int?;
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> setLastPulledAt(
    String userId,
    String entityType,
    DateTime at,
  ) async {
    final db = await _db;
    await db.insert(
      'sync_state',
      {
        'user_id': userId,
        'entity_type': entityType,
        'last_pulled_at': at.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Replaces a user's entire local dataset.
  ///
  /// Used by the one-time migration off SharedPreferences and by a forced
  /// full refresh. Everything lands in one transaction so an interrupted run
  /// leaves the old data intact rather than a half-written mixture.
  Future<void> replaceAll({
    required String userId,
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required List<Holding> holdings,
    required List<Category> categories,
    required List<RecurringRule> recurringRules,
    required List<Daret> darets,
    Map<String, dynamic>? settings,
    bool markDirty = true,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dirty = markDirty ? 1 : 0;

    await db.transaction((txn) async {
      for (final table in LocalDatabase.syncedTables) {
        await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      }

      Future<void> insertAll<T>(
        String table,
        List<T> items,
        Map<String, Object?> Function(T) toRow,
      ) async {
        for (final item in items) {
          await txn.insert(
            table,
            {
              ...toRow(item),
              'user_id': userId,
              'updated_at': now,
              'deleted_at': null,
              'dirty': dirty,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await insertAll<Account>(
          EntityType.accounts, accounts, EntityMappers.accountToRow);
      await insertAll<Category>(
          EntityType.categories, categories, EntityMappers.categoryToRow);
      await insertAll<Transaction>(EntityType.transactions, transactions,
          EntityMappers.transactionToRow);
      await insertAll<Goal>(EntityType.goals, goals, EntityMappers.goalToRow);
      await insertAll<Holding>(
          EntityType.holdings, holdings, EntityMappers.holdingToRow);
      await insertAll<RecurringRule>(EntityType.recurringRules, recurringRules,
          EntityMappers.recurringRuleToRow);
      await insertAll<Daret>(EntityType.darets, darets, EntityMappers.daretToRow);

      if (settings != null) {
        await txn.insert(
          EntityType.settings,
          {
            'user_id': userId,
            'data': jsonEncode(settings),
            'updated_at': now,
            'dirty': dirty,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
