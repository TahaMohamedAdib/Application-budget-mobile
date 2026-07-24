import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/services/sync_conflict.dart';

void main() {
  const resolver = SyncConflictResolver();

  SyncResolution decide(String? local, String? remote) => resolver.resolve(
        localUpdatedAt: local,
        remoteUpdatedAt: remote,
        entity: 'account',
        id: 'a1',
      );

  group('SyncConflictResolver', () {
    test('local newer than remote → apply local', () {
      expect(
        decide('2026-07-24T12:00:00Z', '2026-07-24T11:00:00Z'),
        SyncResolution.applyLocal,
      );
    });

    test('remote newer than local → keep remote', () {
      expect(
        decide('2026-07-24T11:00:00Z', '2026-07-24T12:00:00Z'),
        SyncResolution.keepRemote,
      );
    });

    test('equal timestamps → local wins (tie)', () {
      expect(
        decide('2026-07-24T12:00:00Z', '2026-07-24T12:00:00Z'),
        SyncResolution.applyLocal,
      );
    });

    test('no remote row → apply local', () {
      expect(decide('2026-07-24T12:00:00Z', null), SyncResolution.applyLocal);
    });

    test('missing local timestamp but remote present → apply local (fail-open)',
        () {
      expect(decide(null, '2026-07-24T12:00:00Z'), SyncResolution.applyLocal);
    });

    test('both missing → apply local', () {
      expect(decide(null, null), SyncResolution.applyLocal);
    });

    test('unparseable remote timestamp is treated as unknown → apply local', () {
      expect(decide('2026-07-24T12:00:00Z', 'not-a-date'),
          SyncResolution.applyLocal);
    });

    test('timezone offsets are normalized before comparison', () {
      // 12:00+02:00 == 10:00Z, which is BEFORE 11:00Z remote → keep remote.
      expect(
        decide('2026-07-24T12:00:00+02:00', '2026-07-24T11:00:00Z'),
        SyncResolution.keepRemote,
      );
    });
  });
}
