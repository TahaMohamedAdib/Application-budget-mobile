import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'secure_storage_service.dart';

/// PIN-based app lock.
///
/// The PIN is never stored. A random 16-byte salt is generated per PIN and
/// only `SHA-256(salt + pin)` is kept, both in the platform keychain — so a
/// dump of the keychain still doesn't reveal the PIN, and two users who pick
/// the same PIN get different digests.
///
/// This is deliberately a local gate on an already-authenticated session, not
/// an authentication factor: it does not protect the Supabase token, it just
/// stops someone holding an unlocked phone from reading the user's finances.
class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  static const _hashKey = 'app_lock_pin_hash';
  static const _saltKey = 'app_lock_pin_salt';

  final _storage = SecureStorageService.instance;

  /// Minimum digits accepted when setting a PIN.
  static const pinLength = 4;

  static String _digest(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt$pin')).toString();

  static String _newSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<bool> get hasPin async =>
      (await _storage.read(_hashKey))?.isNotEmpty ?? false;

  Future<void> setPin(String pin) async {
    final salt = _newSalt();
    await _storage.write(_saltKey, salt);
    await _storage.write(_hashKey, _digest(salt, pin));
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(_saltKey);
    final stored = await _storage.read(_hashKey);
    if (salt == null || stored == null) return false;
    return _digest(salt, pin) == stored;
  }

  Future<void> clearPin() async {
    await _storage.delete(_hashKey);
    await _storage.delete(_saltKey);
  }
}
