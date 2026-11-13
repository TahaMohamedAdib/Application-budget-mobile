import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/services/supabase_config.dart';

void main() {
  late bool previousAvailability;

  setUp(() {
    previousAvailability = SupabaseConfig.isAvailable;
    SupabaseConfig.isAvailable = false;
  });

  tearDown(() {
    SupabaseConfig.isAvailable = previousAvailability;
  });

  test('local mode cannot create a password-recovery session', () async {
    final auth = AuthService();
    await Future<void>.delayed(Duration.zero);

    expect(auth.localMode, isTrue);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.isPasswordRecovery, isFalse);

    final request = await auth.requestPasswordRecovery('person@example.com');
    expect(request.success, isFalse);
    expect(request.error, 'unavailable');

    final reset = await auth.resetPassword('correct-horse-battery-staple');
    expect(reset.success, isFalse);
    expect(reset.error, 'invalid_recovery_session');
  });

  test('OAuth cannot claim success when Supabase is unavailable', () async {
    final auth = AuthService();
    await Future<void>.delayed(Duration.zero);

    final result = await auth.signInWithGoogle();

    expect(result.success, isFalse);
    expect(result.error, 'No connection to server.');
  });

  test('password recovery and OAuth share the registered native callback', () {
    expect(
      SupabaseConfig.authCallbackUrl,
      'io.supabase.timctayytkcvxvpukvlq://login-callback/',
    );
  });
}
