import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account deletion uses an authenticated server-side path', () {
    final client = File('lib/services/auth_service.dart').readAsStringSync();
    final function =
        File('supabase/functions/delete-account/index.ts').readAsStringSync();

    expect(
        client, contains("invoke('delete-account', method: HttpMethod.post)"));
    expect(client, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    expect(function, contains("if (!authHeader.startsWith('Bearer '))"));
    expect(function, contains('asUser.auth.getUser()'));
    expect(function, contains('admin.auth.admin.deleteUser(userId)'));
  });

  test('deletion clears local rows using the identity captured before sign-out',
      () {
    final screen = File('lib/screens/account_screen.dart').readAsStringSync();
    final provider = File('lib/providers/app_provider.dart').readAsStringSync();

    expect(screen, contains('final deletedUserId = auth.userId;'));
    expect(
        screen, contains('await provider.clearData(userId: deletedUserId);'));
    expect(provider, contains('final signingOutUserId = userId ?? _userId;'));
    expect(
        provider, contains('clearPendingRetryQueue(userId: signingOutUserId)'));
    expect(
        provider, contains('await LocalDatabase.instance.wipeUser(userId);'));
  });

  test('the deletion function clears all known per-user Storage buckets', () {
    final function =
        File('supabase/functions/delete-account/index.ts').readAsStringSync();

    expect(function, contains("['receipts', 'avatars', 'logos']"));
    expect(function, contains('admin.storage.listBuckets()'));
    expect(function, contains('existingBuckets.has(name)'));
    expect(function, contains('admin.storage.from(bucket).remove'));
  });
}
