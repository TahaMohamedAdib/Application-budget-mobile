import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/data/local_database.dart';
import 'package:safespend_flutter/data/local_repository.dart';
import 'package:safespend_flutter/data/sync_queue.dart';
import 'package:safespend_flutter/models/category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('fresh SQLite schema has the budget inclusion column exactly once',
      () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: LocalDatabase.schemaVersion,
        onCreate: (db, version) => LocalDatabase.debugMigrate(db, 0, version),
      ),
    );
    addTearDown(db.close);

    final columns = await db.rawQuery('PRAGMA table_info(categories)');
    final inclusion = columns
        .where((column) => column['name'] == 'include_in_monthly_budget');

    expect(inclusion, hasLength(1));
    expect(inclusion.single['dflt_value'], '1');
  });

  test('v1 SQLite upgrade preserves categories and defaults inclusion to true',
      () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await LocalDatabase.debugMigrate(db, 0, 1);
    await db.insert('categories', {
      'id': 'groceries',
      'user_id': 'existing-user',
      'name': 'Groceries',
      'group': 'variable',
      'icon': 'shopping_cart',
      'color': '#007F73',
      'budget_limit': 750.0,
      'updated_at': 1,
    });

    await LocalDatabase.debugMigrate(db, 1, LocalDatabase.schemaVersion);

    final row = (await db.query('categories')).single;
    expect(row['id'], 'groceries');
    expect(row['budget_limit'], 750.0);
    expect(row['include_in_monthly_budget'], 1);
  });

  test('excluded categories persist without a monthly spending limit',
      () async {
    LocalDatabase.debugOpenOverride = () => databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: LocalDatabase.schemaVersion,
            onCreate: (db, version) =>
                LocalDatabase.debugMigrate(db, 0, version),
          ),
        );
    addTearDown(() async {
      await LocalDatabase.instance.close();
      LocalDatabase.debugOpenOverride = null;
    });

    final repository = LocalRepository(queue: SyncQueue());
    final category = Category(
      id: 'travel',
      name: 'Travel',
      group: 'variable',
      icon: 'flight',
      color: '#06b6d4',
      budgetLimit: 600,
    ).copyWith(includeInMonthlyBudget: false);

    await repository.saveCategory('user-a', category);
    final restored = (await repository.categories('user-a')).single;

    expect(restored.includeInMonthlyBudget, isFalse);
    expect(restored.budgetLimit, 0);
    expect(restored.toJson()['includeInMonthlyBudget'], isFalse);
  });
}
