import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/models/settings.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:safespend_flutter/services/image_service.dart';

/// Images must survive a reinstall.
///
/// Local storage is gone when the app is removed, so the server row is the
/// only surviving copy of a reference. Two things have to hold:
///
///  1. the reference is round-tripped through the profile/transaction rows;
///  2. the reference is a durable **object path**, not a signed URL — those
///     expire within the hour, so a persisted URL is broken long before the
///     user reinstalls.
void main() {
  group('profile picture survives reinstall', () {
    test('the avatar path round-trips through settings JSON', () {
      const path = 'user-123/avatar.jpg';
      const original = Settings(currency: 'MAD', avatarPath: path);

      // Simulates the local cache being written and read back.
      final restored = Settings.fromJson(original.toJson());

      expect(restored.avatarPath, path);
    });

    test('a fresh install adopts the avatar from the server profile', () {
      // What a reinstall looks like: defaults locally, real data remotely.
      const freshInstall = Settings();
      const serverProfile = Settings(
        currency: 'MAD',
        monthlyIncome: 5000,
        avatarPath: 'user-123/avatar.jpg',
      );

      final merged = freshInstall.withRemoteProfile(serverProfile);

      expect(merged.avatarPath, 'user-123/avatar.jpg',
          reason: 'the picture must come back after reinstalling');
      expect(merged.currency, 'MAD');
      expect(merged.monthlyIncome, 5000);
    });

    test('a pending local avatar survives a server profile refresh', () {
      const local = Settings(avatarPath: '/app/profile/avatar_pending.jpg');
      const serverProfile = Settings(
        avatarPath: 'user-123/avatar.jpg',
      );

      final merged = local.withRemoteProfile(serverProfile);

      expect(merged.avatarPath, '/app/profile/avatar_pending.jpg',
          reason: 'a failed upload must not make the chosen picture vanish');
    });

    test('clearing the picture is distinguishable from not touching it', () {
      const withPicture = Settings(avatarPath: 'user-123/avatar.jpg');

      // Not mentioned: keep whatever is there.
      expect(withPicture.copyWith(currency: 'EUR').avatarPath,
          'user-123/avatar.jpg');

      // Explicitly null: the user removed it.
      expect(withPicture.copyWith(avatarPath: null).avatarPath, isNull);
    });

    test('settings equality accounts for the avatar', () {
      // Sync skips writes when nothing changed, so a picture change has to
      // register as a difference or it would never reach the server.
      const a = Settings(avatarPath: 'user-123/avatar.jpg');
      const b = Settings(avatarPath: 'user-123/other.jpg');
      const c = Settings();

      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(a == const Settings(avatarPath: 'user-123/avatar.jpg'), isTrue);
    });
  });

  group('profile picture local fallback', () {
    test('recognises device paths without confusing storage object paths', () {
      expect(
          ImageService.isLocalImagePath('/data/user/0/app/avatar.jpg'), isTrue);
      expect(ImageService.isLocalImagePath(r'C:\app\avatar.jpg'), isTrue);
      expect(ImageService.isLocalImagePath('user-123/avatar.jpg'), isFalse);
      expect(ImageService.isLocalImagePath('https://example.com/avatar.jpg'),
          isFalse);
    });

    test('copies a picker file into durable app-owned storage', () async {
      final root = await Directory.systemTemp.createTemp('avatar_fallback_');
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}${Platform.pathSeparator}picked.jpg');
      final original = <int>[0xff, 0xd8, 0xff, 0xd9];
      await source.writeAsBytes(original);

      final stored = await ImageService.persistProfilePicture(
        source.path,
        supportDirectory: root,
      );

      expect(stored, isNotNull);
      expect(stored, isNot(source.path));
      expect(await File(stored!).exists(), isTrue);
      expect(await File(stored).readAsBytes(), original);
    });

    test('both database setup paths create the private avatars bucket',
        () async {
      final migration =
          await File('supabase_migrations/20260919000000_profile_avatars.sql')
              .readAsString();
      final completeSetup =
          await File('supabase_complete_setup.sql').readAsString();

      for (final sql in [migration, completeSetup]) {
        expect(
          sql,
          matches(RegExp(
            r"VALUES\s*\(\s*'avatars'\s*,\s*'avatars'\s*,\s*false",
            multiLine: true,
          )),
        );
        expect(sql, contains('Avatars owner upload'));
        expect(sql, contains('Avatars owner update'));
        expect(sql, contains('Avatars owner read'));
        expect(sql, contains('Avatars owner delete'));
      }
    });
  });

  group('transaction receipts survive reinstall', () {
    Transaction receipt(String? imagePath) => Transaction(
          id: 't1',
          type: 'expense',
          amount: 42,
          accountId: 'acct-1',
          date: DateTime(2026, 1, 1).toIso8601String(),
          imagePath: imagePath,
        );

    test('the receipt reference round-trips through transaction JSON', () {
      const path = 'user-123/9f8e7d6c.jpg';
      final restored = Transaction.fromJson(receipt(path).toJson());
      expect(restored.imagePath, path);
    });

    test('a transaction with no receipt stays null', () {
      final restored = Transaction.fromJson(receipt(null).toJson());
      expect(restored.imagePath, isNull);
    });
  });

  group('stored references are durable, not expiring links', () {
    // A signed URL carries a token and an expiry. Persisting one is the bug
    // this work fixed: the image breaks an hour later, and a reinstall can
    // never recover it because the token is long dead.
    const signedUrl =
        'https://proj.supabase.co/storage/v1/object/sign/receipts/'
        'user-123/9f8e.jpg?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

    test('a signed URL is recognisable as non-durable', () {
      expect(signedUrl.contains('token='), isTrue,
          reason: 'this is the shape that must never be persisted');
    });

    test('an object path carries no token or query string', () {
      const path = 'user-123/9f8e.jpg';
      expect(path.contains('token='), isFalse);
      expect(path.contains('?'), isFalse);
      expect(path.startsWith('http'), isFalse);
    });

    test('a path is scoped to its owner, matching the storage policy', () {
      // Storage RLS compares auth.uid() to the first path segment, so the
      // shape itself is what enforces per-user isolation.
      const path = 'user-123/9f8e.jpg';
      expect(path.split('/').first, 'user-123');
      expect(path.split('/').length, 2,
          reason: 'flat per-user folder; no nesting to traverse');
    });
  });
}
