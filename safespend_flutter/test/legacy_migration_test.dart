import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/data/legacy_migration.dart';
import 'package:safespend_flutter/data/local_database.dart';
import 'package:safespend_flutter/data/local_repository.dart';
import 'package:safespend_flutter/data/sync_queue.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// The upgrade path for installs that already hold data in the old
/// SharedPreferences blobs.
///
/// This is the change's highest-risk step: getting it wrong loses a real
/// user's financial history, so the cases below lean on loss and on what
/// happens when the import is interrupted.
void main() {
  late LocalRepository repository;
  late LegacyMigration migration;

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
    repository = LocalRepository(queue: SyncQueue());
    migration = LegacyMigration(repository: repository);
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
    LocalDatabase.debugOpenOverride = null;
  });

  /// Seeds the old-format blobs the way a pre-upgrade install would have them.
  void seedLegacyBlobs({
    List<Account> accounts = const [],
    List<Transaction> transactions = const [],
    Map<String, dynamic>? settings,
  }) {
    SharedPreferences.setMockInitialValues({
      if (accounts.isNotEmpty)
        'accounts': jsonEncode(accounts.map((a) => a.toJson()).toList()),
      if (transactions.isNotEmpty)
        'transactions':
            jsonEncode(transactions.map((t) => t.toJson()).toList()),
      if (settings != null) 'settings': jsonEncode(settings),
    });
  }

  Account account(String id, {double balance = 100}) => Account(
        id: id,
        name: 'Account $id',
        type: 'bank',
        balance: balance,
      );

  Transaction transaction(String id) => Transaction(
        id: id,
        type: 'expense',
        amount: 30,
        date: '2026-09-19',
        accountId: 'acc-1',
      );

  test('existing data moves into the database', () async {
    seedLegacyBlobs(
      accounts: [account('acc-1', balance: 500), account('acc-2')],
      transactions: [transaction('tx-1'), transaction('tx-2')],
    );

    final result = await migration.migrateIfNeeded(userId);

    expect(result.migrated, isTrue);
    expect(result.accounts, 2);
    expect(result.transactions, 2);
    expect(await repository.accounts(userId), hasLength(2));
    expect(await repository.transactions(userId), hasLength(2));
  });

  test('migrated values are exact, not approximate', () async {
    final original = account('acc-1', balance: 1234.56);
    seedLegacyBlobs(accounts: [original]);

    await migration.migrateIfNeeded(userId);

    final stored = (await repository.accounts(userId)).single;
    expect(stored.toJson(), original.toJson());
  });

  test('the old blobs are left in place', () async {
    seedLegacyBlobs(accounts: [account('acc-1')]);

    await migration.migrateIfNeeded(userId);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('accounts'), isNotNull,
        reason: 'the fallback must survive until a later release retires it');
  });

  test('running twice does not duplicate anything', () async {
    seedLegacyBlobs(accounts: [account('acc-1')]);

    final first = await migration.migrateIfNeeded(userId);
    final second = await migration.migrateIfNeeded(userId);

    expect(first.migrated, isTrue);
    expect(second.migrated, isFalse);
    expect(await repository.accounts(userId), hasLength(1));
  });

  test('a fresh install migrates nothing and is marked done', () async {
    SharedPreferences.setMockInitialValues({});

    final result = await migration.migrateIfNeeded(userId);

    expect(result.migrated, isFalse);
    expect(await migration.hasMigrated(userId), isTrue,
        reason: 're-scanning empty blobs on every launch is wasted work');
  });

  test('migrated rows are not queued for re-upload', () async {
    seedLegacyBlobs(
      accounts: [account('acc-1'), account('acc-2')],
      transactions: [transaction('tx-1')],
    );

    await migration.migrateIfNeeded(userId);

    expect(await repository.hasUnsyncedChanges(userId), isFalse,
        reason: 'the server already has this data; re-uploading a full '
            'history on first launch would be a self-inflicted stampede');
  });

  test('one corrupt blob does not cost the others', () async {
    SharedPreferences.setMockInitialValues({
      'accounts': jsonEncode([account('acc-1').toJson()]),
      'transactions': '{ this is not valid json',
    });

    final result = await migration.migrateIfNeeded(userId);

    expect(result.accounts, 1);
    expect(result.transactions, 0);
    expect(await repository.accounts(userId), hasLength(1));
  });

  test('one malformed record does not cost its whole list', () async {
    SharedPreferences.setMockInitialValues({
      'accounts': jsonEncode([
        account('acc-1').toJson(),
        {'id': 'broken'}, // missing the required name and type
        account('acc-3').toJson(),
      ]),
    });

    final result = await migration.migrateIfNeeded(userId);

    expect(result.accounts, 2);
    final ids = (await repository.accounts(userId)).map((a) => a.id).toSet();
    expect(ids, {'acc-1', 'acc-3'});
  });

  test('an unmigrated user is retried on the next launch', () async {
    seedLegacyBlobs(accounts: [account('acc-1')]);

    expect(await migration.hasMigrated(userId), isFalse);
    await migration.migrateIfNeeded(userId);
    expect(await migration.hasMigrated(userId), isTrue);
  });

  test('two users on one device migrate independently', () async {
    seedLegacyBlobs(accounts: [account('acc-1')]);

    await migration.migrateIfNeeded('user-a');

    expect(await migration.hasMigrated('user-a'), isTrue);
    expect(await migration.hasMigrated('user-b'), isFalse,
        reason: 'the flag is per-user, so a second account still imports');
  });

  test('settings come across', () async {
    seedLegacyBlobs(
      accounts: [account('acc-1')],
      settings: {'currency': 'MAD', 'monthlyIncome': 12000.0},
    );

    final result = await migration.migrateIfNeeded(userId);

    expect(result.settings, isTrue);
    final stored = await repository.settings(userId);
    expect(stored?['currency'], 'MAD');
  });
}
