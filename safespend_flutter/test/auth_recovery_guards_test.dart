import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/screens/auth_screen.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/services/supabase_config.dart';

class _RecoveryAuth extends AuthService {
  final request = Completer<({bool success, String? error})>();
  final emails = <String>[];

  @override
  Future<({bool success, String? error})> requestPasswordRecovery(
    String email,
  ) {
    emails.add(email);
    return request.future;
  }
}

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

  testWidgets('recovery dialog dismisses cleanly and reports email delivery', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(450, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _RecoveryAuth();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: auth,
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final s = S.of(tester.element(find.byType(AuthScreen)));
    await tester.tap(find.text(s.forgotPassword));
    await tester.pumpAndSettle();
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(dialogField, ' recovery@example.com ');
    await tester.tap(find.text(s.tr('sendRecoveryEmail')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(auth.emails, ['recovery@example.com']);
    expect(tester.takeException(), isNull);

    auth.request.complete((success: true, error: null));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(s.tr('recoveryEmailSent')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
