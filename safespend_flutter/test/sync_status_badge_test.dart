import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/data/sync_engine.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/widgets/sync_status_badge.dart';

/// What the sync indicator tells the user.
///
/// The brief's rule is that the app must not fake an offline mode, and the
/// indicator is where faking it would show: a badge that reads "Synced" while
/// edits sit in the queue is precisely the lie these cases exist to catch.
void main() {
  final s = S.forLocale('en');

  SyncStatusSnapshot snap({
    SyncPhase phase = SyncPhase.idle,
    int pending = 0,
    int failed = 0,
  }) =>
      SyncStatusSnapshot(
        phase: phase,
        pendingCount: pending,
        failedCount: failed,
      );

  group('what the badge claims', () {
    test('says synced only when nothing is outstanding', () {
      final view = SyncPresentation.of(s, snap());

      expect(view.label, s.syncedToCloud);
      expect(view.color, AppTheme.success);
      expect(view.spins, isFalse);
    });

    test('never claims synced while work is queued', () {
      final view = SyncPresentation.of(s, snap(pending: 3));

      expect(view.label, isNot(s.syncedToCloud));
      expect(view.label, s.syncPending);
      expect(view.detail, contains('3'));
    });

    test('reports offline as offline, not as an error', () {
      final view = SyncPresentation.of(s, snap(phase: SyncPhase.offline));

      expect(view.label, s.syncOffline);
      expect(view.color, AppTheme.warning,
          reason: 'being offline is normal, not a failure');
      expect(view.detail, s.syncOfflineDetail);
    });

    test('offline with queued work names the count', () {
      final view = SyncPresentation.of(
        s,
        snap(phase: SyncPhase.offline, pending: 7),
      );

      expect(view.label, s.syncOffline);
      expect(view.detail, contains('7'));
    });

    test('a failure outranks everything else', () {
      final view = SyncPresentation.of(
        s,
        snap(phase: SyncPhase.syncing, pending: 5, failed: 2),
      );

      expect(view.label, s.syncFailed,
          reason: 'the state needing action is the one to surface');
      expect(view.color, AppTheme.error);
      expect(view.detail, contains('2'));
    });

    test('only the syncing state animates', () {
      expect(SyncPresentation.of(s, snap(phase: SyncPhase.syncing)).spins,
          isTrue);
      expect(SyncPresentation.of(s, snap()).spins, isFalse);
      expect(SyncPresentation.of(s, snap(pending: 4)).spins, isFalse);
      expect(SyncPresentation.of(s, snap(phase: SyncPhase.offline)).spins,
          isFalse);
    });

    test('an error phase with a drained queue still reads as synced', () {
      // The engine recovered; there is nothing left to warn about.
      final view = SyncPresentation.of(s, snap(phase: SyncPhase.error));

      expect(view.label, s.syncedToCloud);
    });
  });

  group('every locale can render it', () {
    // The settings suite guards raw-key fallthrough on screens; this covers
    // the sync strings specifically, including the interpolated ones.
    const locales = [
      'en', 'fr', 'ar', 'es', 'de', 'pt', 'it', 'tr',
      'nl', 'ru', 'zh', 'ja', 'ko', 'hi', 'id', 'pl',
    ];

    final rawKey = RegExp(r'^[a-z]+[A-Z][A-Za-z]*$');

    for (final locale in locales) {
      test('$locale has every sync string', () {
        final l = S.forLocale(locale);

        final states = [
          snap(),
          snap(pending: 2),
          snap(phase: SyncPhase.syncing, pending: 1),
          snap(phase: SyncPhase.offline),
          snap(phase: SyncPhase.offline, pending: 2),
          snap(failed: 1),
        ];

        for (final state in states) {
          final view = SyncPresentation.of(l, state);
          expect(rawKey.hasMatch(view.label), isFalse,
              reason: 'untranslated label "${view.label}" in $locale');
          if (view.detail != null) {
            expect(rawKey.hasMatch(view.detail!), isFalse,
                reason: 'untranslated detail "${view.detail}" in $locale');
            expect(view.detail, isNot(contains('{count}')),
                reason: 'unsubstituted placeholder in $locale');
          }
        }

        expect(rawKey.hasMatch(l.unsyncedWarningTitle), isFalse);
        expect(rawKey.hasMatch(l.unsyncedWarningContinue), isFalse);
        final warning = l.tr('unsyncedWarningMessage', {'count': 3});
        expect(warning, contains('3'));
        expect(rawKey.hasMatch(warning), isFalse);
      });
    }
  });

  group('the widget itself', () {
    Widget host(ValueNotifier<SyncStatusSnapshot> status) => MaterialApp(
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: ValueListenableBuilder<SyncStatusSnapshot>(
              valueListenable: status,
              builder: (context, value, _) {
                final view = SyncPresentation.of(S.of(context), value);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(view.icon, color: view.color),
                    Text(view.label),
                    if (view.detail != null) Text(view.detail!),
                  ],
                );
              },
            ),
          ),
        );

    testWidgets('updates when the engine reports new state', (tester) async {
      final status = ValueNotifier(snap());
      addTearDown(status.dispose);

      await tester.pumpWidget(host(status));
      expect(find.text(s.syncedToCloud), findsOneWidget);

      status.value = snap(phase: SyncPhase.offline, pending: 2);
      await tester.pump();

      expect(find.text(s.syncedToCloud), findsNothing);
      expect(find.text(s.syncOffline), findsOneWidget);
    });
  });
}
