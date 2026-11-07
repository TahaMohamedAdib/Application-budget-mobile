import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release Gradle configuration cannot fall back to the debug key', () {
    final source = File('android/app/build.gradle.kts').readAsStringSync();
    expect(source, isNot(contains('signingConfigs.getByName("debug")')));
    expect(source, contains('Release signing is required.'));
    expect(source, contains('signingConfigs.create("release")'));
  });

  test('account deletion records retryable server-side state', () {
    final function =
        File('supabase/functions/delete-account/index.ts').readAsStringSync();
    final migration = File(
      'supabase_migrations/20261107010000_account_deletion_jobs.sql',
    ).readAsStringSync();

    expect(function, contains("markDeletion(admin, userId, 'requested')"));
    expect(
        function, contains("markDeletion(admin, userId, 'storage_deleted')"));
    expect(function, contains("markDeletion(admin, userId, 'failed'"));
    expect(migration,
        contains('CREATE TABLE IF NOT EXISTS public.account_deletion_jobs'));
    expect(migration, contains('ENABLE ROW LEVEL SECURITY'));
  });
}
