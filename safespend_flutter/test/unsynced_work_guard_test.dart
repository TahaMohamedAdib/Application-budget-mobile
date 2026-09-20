import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safespend_flutter/data/local_database.dart';
import 'package:safespend_flutter/data/sync_engine.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/widgets/unsynced_work_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// The warning shown before an action that would destroy unsent work.
///
/// Signing out wipes the local database, and the sync queue lives in it. If
/// this dialog fails to appear, the user loses work with no indication it ever
/// existed — the outcome the brief calls out by name.
void main() {
  final s = S.forLocale('en');

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalDatabase.debugOpenOverride = () => databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: LocalDatabase.schemaVersion,
            onCreate: (db, version) =>
                LocalDatabase.debugMigrate(db, 0, version),
          ),
        );
    await LocalDatabase.instance.close();
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
    LocalDatabase.debugOpenOverride = null;
  });

  /// Pumps a button that runs the guard and records what it returned.
  Future<List<bool>> runGuard(
    WidgetTester tester,
    AppProvider provider,
  ) async {
    final results = <bool>[];

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  results.add(
                    await UnsyncedWorkGuard.confirm(context, provider),
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('no dialog when there is nothing unsynced', (tester) async {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    final results = await runGuard(tester, provider);

    expect(find.text(s.unsyncedWarningTitle), findsNothing,
        reason: 'a warning on every sign-out would be tapped through blindly');
    expect(results, [true], reason: 'the caller should proceed');
  });

  testWidgets('warns when the engine reports queued work', (tester) async {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    // Stand in for an engine holding unsent operations.
    provider.debugSetSyncStatus(const SyncStatusSnapshot(pendingCount: 4));

    await runGuard(tester, provider);

    expect(find.text(s.unsyncedWarningTitle), findsOneWidget);
    expect(find.textContaining('4'), findsOneWidget,
        reason: 'the user should know how much work is at stake');
  });

  testWidgets('failed work counts as unsynced too', (tester) async {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    provider.debugSetSyncStatus(const SyncStatusSnapshot(failedCount: 2));

    await runGuard(tester, provider);

    expect(find.text(s.unsyncedWarningTitle), findsOneWidget,
        reason: 'work that failed to upload is still only on this device');
  });

  testWidgets('cancelling reports do-not-proceed', (tester) async {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    provider.debugSetSyncStatus(const SyncStatusSnapshot(pendingCount: 1));

    final results = <bool>[];
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  results.add(
                    await UnsyncedWorkGuard.confirm(context, provider),
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(s.cancel));
    await tester.pumpAndSettle();

    expect(results, [false],
        reason: 'backing out must abort the destructive action');
  });

  testWidgets('confirming reports proceed', (tester) async {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    provider.debugSetSyncStatus(const SyncStatusSnapshot(pendingCount: 1));

    final results = <bool>[];
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  results.add(
                    await UnsyncedWorkGuard.confirm(context, provider),
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(s.unsyncedWarningContinue));
    await tester.pumpAndSettle();

    expect(results, [true],
        reason: 'the user was warned and chose to go ahead');
  });
}
