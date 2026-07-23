import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/services/ai_access_policy.dart';

void main() {
  group('hasAiAccess', () {
    test('requires a real session even when access is open to all', () {
      expect(
        hasAiAccess(
          hasSession: false,
          openToAll: true,
          email: 'user@example.com',
          allowedEmails: const [],
        ),
        isFalse,
      );
    });

    test('allows any signed-in user when access is open to all', () {
      expect(
        hasAiAccess(
          hasSession: true,
          openToAll: true,
          email: null,
          allowedEmails: const [],
        ),
        isTrue,
      );
    });

    test('matches allowlisted email addresses case-insensitively', () {
      expect(
        hasAiAccess(
          hasSession: true,
          openToAll: false,
          email: ' User@Example.com ',
          allowedEmails: const ['user@example.com'],
        ),
        isTrue,
      );
    });

    test('rejects a signed-in user outside the allowlist', () {
      expect(
        hasAiAccess(
          hasSession: true,
          openToAll: false,
          email: 'other@example.com',
          allowedEmails: const ['user@example.com'],
        ),
        isFalse,
      );
    });
  });
}
