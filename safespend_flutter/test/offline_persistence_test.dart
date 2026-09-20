import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/data/local_database.dart';
import 'package:safespend_flutter/data/local_repository.dart';
import 'package:safespend_flutter/data/sync_queue.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/category.dart';
import 'package:safespend_flutter/models/transaction.dart';
// sqflite re-exports its own `Transaction`; the app model is the one under
// test here.
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// Covers the local store and the durable queue: the two pieces that decide
/// whether work done offline survives.
///
/// Each test gets its own in-memory database, so nothing leaks between them
/// and the suite stays order-independent.
void main() {
  late LocalRepository repository;
  late SyncQueue queue;

  const userA = 'user-a';
  const userB = 'user-b';

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    LocalDatabase.debugOpenOverride = () => databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: LocalDatabase.schemaVersion,
            onCreate: (db, version) async {
              // The production opener runs the same migration; going through
              // it here keeps the test schema from drifting from the real one.
              await LocalDatabase.debugMigrate(db, 0, version);
            },
          ),
        );
    await LocalDatabase.instance.close();
    queue = SyncQueue();
    repository = LocalRepository(queue: queue);
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
    LocalDatabase.debugOpenOverride = null;
  });

  Account account(String id, {double balance = 100}) => Account(
        id: id,
        name: 'Account $id',
        type: 'bank',
        balance: balance,
      );

  Transaction transaction(String id, {String accountId = 'acc-1'}) =>
      Transaction(
        id: id,
        type: 'expense',
        amount: 25,
        date: '2026-09-19',
        accountId: accountId,
      );

  group('local writes', () {
    test('a created account is readable immediately', () async {
      await repository.saveAccount(userA, account('acc-1'));

      final stored = await repository.accounts(userA);
      expect(stored, hasLength(1));
      expect(stored.single.id, 'acc-1');
      expect(stored.single.balance, 100);
    });

    test('an update replaces rather than duplicates', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.saveAccount(userA, account('acc-1', balance: 250));

      final stored = await repository.accounts(userA);
      expect(stored, hasLength(1));
      expect(stored.single.balance, 250);
    });

    test('a delete hides the row from reads', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.deleteAccount(userA, 'acc-1');

      expect(await repository.accounts(userA), isEmpty);
    });

    test('a delete leaves a tombstone so it can be pushed', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.deleteAccount(userA, 'acc-1');

      final db = await LocalDatabase.instance.database;
      final rows = await db.query('accounts', where: 'id = ?',
          whereArgs: ['acc-1']);
      expect(rows, hasLength(1),
          reason: 'the row must survive so the delete can reach the server');
      expect(rows.single['deleted_at'], isNotNull);
    });

    test('several accounts commit together', () async {
      await repository.saveAccounts(userA, [
        account('acc-1', balance: 75),
        account('acc-2', balance: 125),
      ]);

      final stored = await repository.accounts(userA);
      expect(stored.map((a) => a.balance).toList()..sort(), [75, 125]);
    });
  });

  group('per-user isolation', () {
    test("one user's rows are invisible to another", () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.saveAccount(userB, account('acc-2'));

      expect((await repository.accounts(userA)).single.id, 'acc-1');
      expect((await repository.accounts(userB)).single.id, 'acc-2');
    });

    test('the same entity id under two users stays separate', () async {
      await repository.saveAccount(userA, account('shared', balance: 10));
      await repository.saveAccount(userB, account('shared', balance: 999));

      expect((await repository.accounts(userA)).single.balance, 10);
      expect((await repository.accounts(userB)).single.balance, 999);
    });

    test('wiping one user leaves the other intact', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.saveAccount(userB, account('acc-2'));

      await LocalDatabase.instance.wipeUser(userA);

      expect(await repository.accounts(userA), isEmpty);
      expect(await repository.accounts(userB), hasLength(1));
    });
  });

  group('sync queue', () {
    test('a write enqueues exactly one operation', () async {
      await repository.saveAccount(userA, account('acc-1'));

      final pending = await queue.claimBatch(userId: userA);
      expect(pending, hasLength(1));
      expect(pending.single.entityType, EntityType.accounts);
      expect(pending.single.entityId, 'acc-1');
      expect(pending.single.operation, SyncOperation.upsert);
    });

    test('repeated edits collapse onto one pending operation', () async {
      await repository.saveAccount(userA, account('acc-1', balance: 1));
      await repository.saveAccount(userA, account('acc-1', balance: 2));
      await repository.saveAccount(userA, account('acc-1', balance: 3));

      final pending = await queue.claimBatch(userId: userA);
      expect(pending, hasLength(1),
          reason: 'only the final state needs to reach the server');
      expect(pending.single.payload!['balance'], 3);
    });

    test('a delete enqueues a delete operation', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.deleteAccount(userA, 'acc-1');

      final pending = await queue.claimBatch(userId: userA);
      expect(pending, hasLength(1));
      expect(pending.single.operation, SyncOperation.delete);
    });

    test('deleting a row that does not exist enqueues nothing', () async {
      await repository.deleteAccount(userA, 'never-existed');
      expect(await queue.claimBatch(userId: userA), isEmpty);
    });

    test('operations keep their creation order', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.saveCategory(
        userA,
        Category(
          id: 'cat-1',
          name: 'Food',
          group: 'variable',
          icon: '🍔',
          color: '#fff',
        ),
      );
      await repository.saveTransaction(userA, transaction('tx-1'));

      final pending = await queue.claimBatch(userId: userA);
      expect(
        pending.map((t) => t.entityId).toList(),
        ['acc-1', 'cat-1', 'tx-1'],
        reason: 'a transaction must not reach the server before its account',
      );
    });

    test("one user's queue is separate from another's", () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.saveAccount(userB, account('acc-2'));

      expect(await queue.claimBatch(userId: userA), hasLength(1));
      expect(await queue.claimBatch(userId: userB), hasLength(1));
      expect(await queue.pendingCount(userA), 1);
    });
  });

  group('retry and backoff', () {
    test('a failure schedules the next attempt in the future', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;

      await queue.fail(task.id, error: 'server exploded');

      // Not yet due, so a drain right now finds nothing.
      expect(await queue.claimBatch(userId: userA), isEmpty);

      // Due once the backoff has elapsed.
      final later = DateTime.now().add(const Duration(seconds: 10));
      final ready = await queue.claimBatch(userId: userA, now: later);
      expect(ready, hasLength(1));
      expect(ready.single.retryCount, 1);
      expect(ready.single.lastError, 'server exploded');
    });

    test('backoff lengthens with each failure', () async {
      expect(SyncQueue.delayFor(1), lessThan(SyncQueue.delayFor(2)));
      expect(SyncQueue.delayFor(2), lessThan(SyncQueue.delayFor(3)));
    });

    test('backoff is capped rather than unbounded', () async {
      expect(SyncQueue.delayFor(99), SyncQueue.backoff.last);
    });

    test('a permanent failure parks the task immediately', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;

      await queue.fail(task.id, error: 'row-level security', permanent: true);

      final far = DateTime.now().add(const Duration(days: 1));
      expect(await queue.claimBatch(userId: userA, now: far), isEmpty,
          reason: 'retrying a rejection would repeat forever');
      expect(await queue.failedTasks(userA), hasLength(1));
    });

    test('a task gives up after the retry budget', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;

      for (var i = 0; i < SyncQueue.maxRetries; i++) {
        await queue.fail(task.id, error: 'attempt $i');
      }

      expect(await queue.failedTasks(userA), hasLength(1));
      final far = DateTime.now().add(const Duration(days: 1));
      expect(await queue.claimBatch(userId: userA, now: far), isEmpty);
    });

    test('a fresh edit revives a task that had given up', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;
      for (var i = 0; i < SyncQueue.maxRetries; i++) {
        await queue.fail(task.id, error: 'nope');
      }
      expect(await queue.failedTasks(userA), hasLength(1));

      await repository.saveAccount(userA, account('acc-1', balance: 500));

      expect(await queue.failedTasks(userA), isEmpty);
      final revived = await queue.claimBatch(userId: userA);
      expect(revived, hasLength(1));
      expect(revived.single.retryCount, 0);
      expect(revived.single.payload!['balance'], 500);
    });

    test('a user-initiated retry re-queues failed work', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;
      await queue.fail(task.id, error: 'nope', permanent: true);

      await queue.retryFailed(userA);

      expect(await queue.failedTasks(userA), isEmpty);
      expect(await queue.claimBatch(userId: userA), hasLength(1));
    });
  });

  group('restart recovery', () {
    test('work queued before a crash is still queued after it', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.saveTransaction(userA, transaction('tx-1'));

      // A new queue object against the same database is what a relaunch sees.
      final afterRestart = SyncQueue();
      expect(await afterRestart.pendingCount(userA), 2);
    });

    test('a task stranded mid-flight is retried, not lost', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;
      await queue.markInFlight(task.id);

      // Mid-flight tasks are invisible to a drain...
      expect(await queue.claimBatch(userId: userA), isEmpty);

      // ...until startup recovery puts them back.
      final recovered = await queue.recoverStuckTasks();
      expect(recovered, 1);
      expect(await queue.claimBatch(userId: userA), hasLength(1));
    });
  });

  group('conflict resolution', () {
    test('a server row overwrites a clean local row', () async {
      await repository.saveAccount(userA, account('acc-1', balance: 100));
      await repository.markSynced(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final applied = await repository.applyRemote(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'Renamed', 'type': 'bank', 'balance': 999.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(applied, isTrue);
      expect((await repository.accounts(userA)).single.balance, 999);
    });

    test('a server row never overwrites unsynced local work', () async {
      await repository.saveAccount(userA, account('acc-1', balance: 100));

      final applied = await repository.applyRemote(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'Server', 'type': 'bank', 'balance': 999.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(applied, isFalse,
          reason: 'discarding the local edit would lose the user\'s work');
      expect((await repository.accounts(userA)).single.balance, 100);
    });

    test('an older server row does not roll a newer local row back', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repository.saveAccount(userA, account('acc-1', balance: 100));
      await repository.markSynced(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: now,
      );

      final applied = await repository.applyRemote(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'Stale', 'type': 'bank', 'balance': 1.0},
        remoteUpdatedAt: now - const Duration(hours: 1).inMilliseconds,
      );

      expect(applied, isFalse);
      expect((await repository.accounts(userA)).single.balance, 100);
    });

    test('a server row arriving for an unknown id is inserted', () async {
      final applied = await repository.applyRemote(
        userId: userA,
        table: EntityType.accounts,
        id: 'from-other-device',
        row: {'name': 'Elsewhere', 'type': 'bank', 'balance': 42.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(applied, isTrue);
      expect((await repository.accounts(userA)).single.name, 'Elsewhere');
    });

    test('a pull does not enqueue a push', () async {
      await repository.applyRemote(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'Server', 'type': 'bank', 'balance': 5.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(await queue.pendingCount(userA), 0,
          reason: 'echoing server rows back would loop forever');
    });
  });

  group('sync bookkeeping', () {
    test('pending work is reported for the sign-out warning', () async {
      expect(await repository.hasUnsyncedChanges(userA), isFalse);
      await repository.saveAccount(userA, account('acc-1'));
      expect(await repository.hasUnsyncedChanges(userA), isTrue);
    });

    test('the pull cursor round-trips', () async {
      expect(await repository.lastPulledAt(userA, EntityType.accounts),
          isNull);

      final at = DateTime.fromMillisecondsSinceEpoch(1758240000000);
      await repository.setLastPulledAt(userA, EntityType.accounts, at);

      expect(await repository.lastPulledAt(userA, EntityType.accounts), at);
    });

    test('a completed push clears the dirty flag', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;

      await repository.markSynced(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: task.updatedAt.millisecondsSinceEpoch,
        version: 7,
      );

      final db = await LocalDatabase.instance.database;
      final row = (await db.query('accounts', where: 'id = ?',
              whereArgs: ['acc-1']))
          .single;
      expect(row['dirty'], 0);
      expect(row['version'], 7);
    });

    test('an edit made mid-push is not marked as synced', () async {
      await repository.saveAccount(userA, account('acc-1'));
      final task = (await queue.claimBatch(userId: userA)).single;

      // The user edits again while the request is in flight.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.saveAccount(userA, account('acc-1', balance: 777));

      await repository.markSynced(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: task.updatedAt.millisecondsSinceEpoch,
      );

      final db = await LocalDatabase.instance.database;
      final row = (await db.query('accounts', where: 'id = ?',
              whereArgs: ['acc-1']))
          .single;
      expect(row['dirty'], 1,
          reason: 'the newer edit still needs to reach the server');
    });

    test('a confirmed delete removes the tombstone', () async {
      await repository.saveAccount(userA, account('acc-1'));
      await repository.deleteAccount(userA, 'acc-1');
      await repository.markSynced(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await repository.purgeTombstone(
        userId: userA,
        table: EntityType.accounts,
        id: 'acc-1',
      );

      final db = await LocalDatabase.instance.database;
      expect(
        await db.query('accounts', where: 'id = ?', whereArgs: ['acc-1']),
        isEmpty,
      );
    });
  });

  group('round-trip fidelity', () {
    test('a transaction keeps every field', () async {
      final original = Transaction(
        id: 'tx-1',
        type: 'expense',
        amount: 42.75,
        fees: 1.25,
        date: '2026-09-19',
        note: 'Lunch',
        description: 'Team lunch',
        categoryId: 'cat-1',
        accountId: 'acc-1',
        toAccountId: null,
        isRecurring: true,
        imagePath: 'receipts/user/abc.jpg',
        expenseSubType: 'subscription',
      );

      await repository.saveTransaction(userA, original);
      final stored = (await repository.transactions(userA)).single;

      expect(stored.toJson(), original.toJson());
    });

    test('an account keeps every field', () async {
      final original = Account(
        id: 'acc-1',
        name: 'Main',
        type: 'bank',
        balance: 1234.56,
        bankName: 'Bank',
        color: '#B8860B',
        includeInNetWorth: false,
        imagePath: 'logos/user/x.png',
        addedAt: '2026-01-01',
        salaryAmount: 5000,
        salaryFrequency: 'biweekly',
        salaryDay: 5,
        salaryAnchorDate: '2026-01-02',
        lastSalaryDate: '2026-09-01',
        debtPaymentAmount: 250,
        debtPaymentDay: 15,
        debtPaymentSourceId: 'acc-2',
      );

      await repository.saveAccount(userA, original);
      final stored = (await repository.accounts(userA)).single;

      expect(stored.toJson(), original.toJson());
    });

    test('transactions read back newest first', () async {
      await repository.saveTransaction(
        userA,
        Transaction(
            id: 'old',
            type: 'expense',
            amount: 1,
            date: '2026-01-01',
            accountId: 'acc-1'),
      );
      await repository.saveTransaction(
        userA,
        Transaction(
            id: 'new',
            type: 'expense',
            amount: 1,
            date: '2026-09-19',
            accountId: 'acc-1'),
      );

      final stored = await repository.transactions(userA);
      expect(stored.map((t) => t.id).toList(), ['new', 'old']);
    });
  });
}
