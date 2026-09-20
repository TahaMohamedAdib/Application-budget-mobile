import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/data/local_database.dart';
import 'package:safespend_flutter/data/local_repository.dart';
import 'package:safespend_flutter/data/sync_queue.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// End-to-end behaviour of the offline path, exercised through the repository
/// the provider now writes to.
///
/// These cover the scenarios a user actually hits — go offline, make changes,
/// come back — rather than the unit behaviour of any one class.
void main() {
  late LocalRepository repository;
  late SyncQueue queue;

  const userId = 'user-a';

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    LocalDatabase.debugOpenOverride = () => databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: LocalDatabase.schemaVersion,
            onCreate: (db, version) =>
                LocalDatabase.debugMigrate(db, 0, version),
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

  Account account(String id, {double balance = 1000}) => Account(
        id: id,
        name: 'Account $id',
        type: 'bank',
        balance: balance,
      );

  Transaction expense(String id, double amount) => Transaction(
        id: id,
        type: 'expense',
        amount: amount,
        date: '2026-09-19',
        accountId: 'acc-1',
      );

  group('a full offline session', () {
    test('create, edit and delete all work with no network', () async {
      await repository.saveAccount(userId, account('acc-1'));
      await repository.saveTransaction(userId, expense('tx-1', 50));
      await repository.saveTransaction(userId, expense('tx-2', 30));

      // Edit one, remove the other.
      await repository.saveTransaction(userId, expense('tx-1', 75));
      await repository.deleteTransaction(userId, 'tx-2');

      final stored = await repository.transactions(userId);
      expect(stored, hasLength(1));
      expect(stored.single.id, 'tx-1');
      expect(stored.single.amount, 75);
    });

    test('everything done offline is queued for the server', () async {
      await repository.saveAccount(userId, account('acc-1'));
      await repository.saveTransaction(userId, expense('tx-1', 50));
      await repository.saveGoal(
        userId,
        Goal(id: 'goal-1', name: 'Holiday', targetAmount: 5000),
      );

      expect(await queue.pendingCount(userId), 3);
      expect(await repository.hasUnsyncedChanges(userId), isTrue);
    });

    test('a session survives a restart intact', () async {
      await repository.saveAccount(userId, account('acc-1'));
      await repository.saveTransaction(userId, expense('tx-1', 50));

      // A fresh repository over the same database is what a relaunch sees.
      final afterRestart = LocalRepository(queue: SyncQueue());

      expect(await afterRestart.accounts(userId), hasLength(1));
      expect(await afterRestart.transactions(userId), hasLength(1));
      expect(await afterRestart.hasUnsyncedChanges(userId), isTrue,
          reason: 'work queued before the restart must still be pending');
    });

    test('coming back online leaves the local data unchanged', () async {
      await repository.saveAccount(userId, account('acc-1', balance: 1234));
      final task = (await queue.claimBatch(userId: userId)).single;

      // The engine pushes and the server acknowledges.
      await queue.complete(task.id);
      await repository.markSynced(
        userId: userId,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: task.updatedAt.millisecondsSinceEpoch,
        version: 1,
      );

      expect((await repository.accounts(userId)).single.balance, 1234);
      expect(await repository.hasUnsyncedChanges(userId), isFalse);
    });
  });

  group('offline work is never silently lost', () {
    test('a server pull cannot overwrite an unsynced edit', () async {
      await repository.saveAccount(userId, account('acc-1', balance: 500));
      await repository.markSynced(
        userId: userId,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // The user edits offline.
      await repository.saveAccount(userId, account('acc-1', balance: 900));

      // Meanwhile the server still believes the old value.
      await repository.applyRemote(
        userId: userId,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'Account acc-1', 'type': 'bank', 'balance': 500.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect((await repository.accounts(userId)).single.balance, 900,
          reason: "the user's own edit must win");
    });

    test('an offline delete is not resurrected by a pull', () async {
      await repository.saveAccount(userId, account('acc-1'));
      await repository.deleteAccount(userId, 'acc-1');

      // The server has not heard about the delete yet and sends the row back.
      await repository.applyRemote(
        userId: userId,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'Account acc-1', 'type': 'bank', 'balance': 1000.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(await repository.accounts(userId), isEmpty,
          reason: 'a deleted row reappearing is the classic offline bug');
    });

    test('edits on two devices both survive, newest applied last', () async {
      // This device syncs a value.
      await repository.saveAccount(userId, account('acc-1', balance: 100));
      final task = (await queue.claimBatch(userId: userId)).single;
      await queue.complete(task.id);
      await repository.markSynced(
        userId: userId,
        table: EntityType.accounts,
        id: 'acc-1',
        pushedUpdatedAt: task.updatedAt.millisecondsSinceEpoch,
      );

      // The other device's newer change arrives.
      await repository.applyRemote(
        userId: userId,
        table: EntityType.accounts,
        id: 'acc-1',
        row: {'name': 'From phone', 'type': 'bank', 'balance': 250.0},
        remoteUpdatedAt: DateTime.now().millisecondsSinceEpoch + 1000,
      );

      final stored = (await repository.accounts(userId)).single;
      expect(stored.balance, 250);
      expect(stored.name, 'From phone');
    });
  });

  group('two accounts on one device', () {
    test('signing out removes the first user data', () async {
      await repository.saveAccount('user-a', account('acc-1'));
      await repository.saveTransaction('user-a', expense('tx-1', 10));

      await LocalDatabase.instance.wipeUser('user-a');

      expect(await repository.accounts('user-a'), isEmpty);
      expect(await repository.transactions('user-a'), isEmpty);
      expect(await queue.pendingCount('user-a'), 0,
          reason: 'queued work for a signed-out user must not be retried');
    });

    test('the second user never sees the first data', () async {
      await repository.saveAccount('user-a', account('acc-1', balance: 5000));
      await LocalDatabase.instance.wipeUser('user-a');

      await repository.saveAccount('user-b', account('acc-9', balance: 20));

      final visible = await repository.accounts('user-b');
      expect(visible, hasLength(1));
      expect(visible.single.id, 'acc-9');
    });
  });

  group('queue behaviour under failure', () {
    test('a failing operation does not block the ones behind it', () async {
      await repository.saveAccount(userId, account('acc-1'));
      await repository.saveAccount(userId, account('acc-2'));

      final batch = await queue.claimBatch(userId: userId);
      expect(batch, hasLength(2));

      // The first is rejected outright; the second succeeds.
      await queue.fail(batch.first.id, error: 'rejected', permanent: true);
      await queue.complete(batch.last.id);

      expect(await queue.failedTasks(userId), hasLength(1));
      final far = DateTime.now().add(const Duration(days: 1));
      expect(await queue.claimBatch(userId: userId, now: far), isEmpty);
    });

    test('failed work is surfaced rather than dropped', () async {
      await repository.saveAccount(userId, account('acc-1'));
      final task = (await queue.claimBatch(userId: userId)).single;
      await queue.fail(task.id, error: 'server said no', permanent: true);

      final failed = await queue.failedTasks(userId);
      expect(failed, hasLength(1));
      expect(failed.single.lastError, 'server said no');
      expect(failed.single.entityId, 'acc-1');
    });

    test('the local row survives a permanently failed push', () async {
      await repository.saveAccount(userId, account('acc-1', balance: 42));
      final task = (await queue.claimBatch(userId: userId)).single;
      await queue.fail(task.id, error: 'nope', permanent: true);

      expect((await repository.accounts(userId)).single.balance, 42,
          reason: 'a sync failure must not cost the user their data');
    });
  });
}
