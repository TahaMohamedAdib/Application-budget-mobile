import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens and migrates the on-device SQLite database.
///
/// This is the app's source of truth. Every read the UI performs is served
/// from here, so the app behaves identically with or without a network; the
/// server is a replica that we push to and pull from in the background.
///
/// ## Why SQLite and not the old SharedPreferences blobs
///
/// The previous store held each entity list as one JSON string. Saving a
/// single transaction rewrote every transaction, so write cost grew with the
/// size of the dataset, and a crash mid-write could truncate the whole list.
/// Rows give us per-record writes, indexes, and real transactions.
///
/// ## Sync columns
///
/// Every synced table carries the same columns, which is what lets one
/// generic sync engine drive all of them:
///
///  * `user_id`    the owner. Every query filters on it, so a device that has
///                 held two accounts can never show one user's rows to the
///                 other.
///  * `updated_at` millis since epoch, set on every local write. Drives
///                 conflict resolution and the incremental pull cursor.
///  * `version`    server-assigned optimistic-lock counter. Null until the row
///                 has been acknowledged by the server at least once.
///  * `deleted_at` tombstone. Deletes are soft so the deletion itself can be
///                 synced; without this, a delete made offline is undone by
///                 the next pull, which re-inserts the row.
///  * `dirty`      1 when the row holds local changes the server has not
///                 acknowledged. Cleared only by a successful push.
class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const _fileName = 'safespend.db';

  /// Bumping this runs [_migrate] from the old version up to the new one.
  /// Never renumber or reuse a version: installed devices replay from
  /// whatever they last ran.
  static const int schemaVersion = 2;

  Database? _db;
  Completer<Database>? _opening;

  /// Overridden by tests to run against an in-memory database.
  @visibleForTesting
  static Future<Database> Function()? debugOpenOverride;

  /// The open database, opening it on first use.
  ///
  /// Concurrent callers share one open attempt; without the completer, two
  /// simultaneous first-callers would each run `openDatabase` and the loser's
  /// handle would leak.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final inFlight = _opening;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<Database>();
    _opening = completer;
    try {
      final db = await _open();
      _db = db;
      completer.complete(db);
      return db;
    } catch (error, stack) {
      completer.completeError(error, stack);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async {
    final override = debugOpenOverride;
    if (override != null) return override();

    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _fileName),
      version: schemaVersion,
      onConfigure: (db) async {
        // Off by default in SQLite; without it any FK clause is parsed and
        // then ignored.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
    );
  }

  /// Applies every migration step in `(from, to]`.
  ///
  /// Each step is guarded by the version it was introduced in, so a device
  /// upgrading from 1 to 4 runs steps 2, 3 and 4 in order and a fresh install
  /// (`from == 0`) runs all of them.
  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 1 && to >= 1) await _createV1(db);
    if (from < 2 && to >= 2) {
      await db.execute(
          'ALTER TABLE categories ADD COLUMN include_in_monthly_budget INTEGER NOT NULL DEFAULT 1');
    }
  }

  /// Lets tests build the real schema in an in-memory database, so the
  /// schema under test is by construction the one that ships.
  @visibleForTesting
  static Future<void> debugMigrate(Database db, int from, int to) =>
      _migrate(db, from, to);

  static Future<void> _createV1(Database db) async {
    final batch = db.batch();

    // Sync queue.
    //
    // Durable because it is a table: an operation enqueued offline survives a
    // force-quit, a crash and a reboot. Rows leave only on success or on an
    // explicit, user-visible discard.
    batch.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_attempt_at INTEGER NOT NULL DEFAULT 0,
        last_attempt_at INTEGER,
        last_error TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        sequence INTEGER NOT NULL
      )
    ''');
    // The worker's hot query: oldest ready operation for this user.
    batch.execute(
      'CREATE INDEX idx_queue_ready ON sync_queue '
      '(user_id, status, next_attempt_at, sequence)',
    );
    // Lets an enqueue collapse repeated edits of one entity into one row.
    batch.execute(
      'CREATE INDEX idx_queue_entity ON sync_queue '
      '(user_id, entity_type, entity_id, status)',
    );

    // Per-user sync bookkeeping. `last_pulled_at` is the incremental-pull
    // cursor: the next pull asks the server only for rows changed since it,
    // rather than for the whole dataset.
    batch.execute('''
      CREATE TABLE sync_state (
        user_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        last_pulled_at INTEGER,
        last_push_at INTEGER,
        PRIMARY KEY (user_id, entity_type)
      )
    ''');

    // Entity tables. Column sets mirror the Dart models; anything the model
    // treats as free-form is stored as JSON in one column, since we never
    // query inside it.

    batch.execute('''
      CREATE TABLE accounts (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        bank_name TEXT,
        color TEXT,
        include_in_net_worth INTEGER NOT NULL DEFAULT 1,
        image_path TEXT,
        added_at TEXT,
        salary_amount REAL,
        salary_frequency TEXT,
        salary_day INTEGER,
        salary_anchor_date TEXT,
        last_salary_date TEXT,
        debt_payment_amount REAL,
        debt_payment_day INTEGER,
        debt_payment_source_id TEXT,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');

    batch.execute('''
      CREATE TABLE transactions (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        fees REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        note TEXT,
        description TEXT,
        category_id TEXT,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        expense_sub_type TEXT,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');
    // The list screen reads newest-first within a user, skipping tombstones.
    batch.execute(
      'CREATE INDEX idx_tx_user_date ON transactions '
      '(user_id, deleted_at, date DESC)',
    );
    // Account detail and balance recomputation read by account.
    batch.execute(
      'CREATE INDEX idx_tx_account ON transactions '
      '(user_id, account_id, deleted_at)',
    );
    // Budget and spending screens aggregate by category.
    batch.execute(
      'CREATE INDEX idx_tx_category ON transactions '
      '(user_id, category_id, deleted_at)',
    );

    batch.execute('''
      CREATE TABLE goals (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        target_amount REAL NOT NULL DEFAULT 0,
        target_date TEXT,
        current_amount REAL NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 0,
        category_id TEXT,
        icon TEXT,
        image_path TEXT,
        color TEXT,
        monthly_payment REAL,
        payment_day INTEGER,
        payment_source_account_id TEXT,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');

    batch.execute('''
      CREATE TABLE holdings (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        symbol TEXT NOT NULL,
        title TEXT,
        shares REAL NOT NULL DEFAULT 0,
        cost_basis REAL NOT NULL DEFAULT 0,
        current_price REAL NOT NULL DEFAULT 0,
        notes TEXT,
        purchase_date TEXT,
        source_account_id TEXT,
        affects_source_balance INTEGER NOT NULL DEFAULT 0,
        source_amount REAL,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');

    // "group" is quoted throughout: it is a reserved word in SQL.
    batch.execute('''
      CREATE TABLE categories (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        "group" TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        budget_limit REAL NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');

    // `template` holds the embedded Transaction as JSON: it is never queried
    // by field, only rehydrated whole.
    batch.execute('''
      CREATE TABLE recurring_rules (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        template TEXT NOT NULL,
        frequency TEXT NOT NULL,
        next_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');

    // `payout_months` is a JSON int array, for the same reason.
    batch.execute('''
      CREATE TABLE darets (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        contribution_per_share REAL NOT NULL DEFAULT 0,
        total_shares INTEGER NOT NULL DEFAULT 0,
        user_shares INTEGER NOT NULL DEFAULT 1,
        payout_months TEXT NOT NULL,
        start_date TEXT NOT NULL,
        payment_source_id TEXT NOT NULL,
        destination_account_id TEXT NOT NULL,
        payment_day INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (user_id, id)
      )
    ''');

    // Settings is a singleton per user, so the whole object is one JSON blob
    // keyed by user. It is the one entity with no relational shape.
    batch.execute('''
      CREATE TABLE settings (
        user_id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// Every synced entity table, ordered so that a push sends parents before
  /// the rows that reference them.
  static const List<String> syncedTables = <String>[
    'accounts',
    'categories',
    'transactions',
    'goals',
    'holdings',
    'recurring_rules',
    'darets',
    'settings',
  ];

  /// Closes the handle. Used by tests and at sign-out.
  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null && db.isOpen) await db.close();
  }

  /// Deletes every row belonging to [userId].
  ///
  /// Used at sign-out when the user asks not to keep local data, and when a
  /// different account signs in on the same device. Runs in one transaction so
  /// a crash cannot leave half a user's data behind.
  Future<void> wipeUser(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in syncedTables) {
        await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      }
      await txn.delete('sync_queue', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('sync_state', where: 'user_id = ?', whereArgs: [userId]);
    });
  }
}
