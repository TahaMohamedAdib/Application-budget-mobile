import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthService with ChangeNotifier {
  User? _user;
  Session? _session;
  bool _loading = true;
  bool _localMode = false;

  User? get user => _user;
  Session? get session => _session;
  bool get loading => _loading;
  bool get localMode => _localMode;
  bool get isAuthenticated => _user != null || _localMode;
  String? get userId => _localMode ? 'local_user' : _user?.id;

  SupabaseClient? get _client => SupabaseConfig.client;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    // If Supabase is not available, run in local-only mode
    if (!SupabaseConfig.isAvailable || _client == null) {
      if (kDebugMode) debugPrint('[AuthService] Supabase not available — local mode');
      _localMode = true;
      _loading = false;
      notifyListeners();
      return;
    }

    // Eagerly recover the persisted session that Supabase.initialize()
    // already restored from secure storage.  This makes the user
    // authenticated *immediately* — no waiting for the stream.
    final restored = _client!.auth.currentSession;
    if (restored != null) {
      if (kDebugMode) debugPrint('[AuthService] restored session for ${restored.user.email}');
      _session = restored;
      _user = restored.user;
      _localMode = false;
    }
    _loading = false;
    notifyListeners();

    // Keep listening for future auth events (sign-in, sign-out, token
    // refresh) so the UI stays in sync.
    _client!.auth.onAuthStateChange.listen(
      (data) {
        if (kDebugMode) {
          debugPrint('[AuthService] event=${data.event} user=${data.session?.user.email}');
        }
        _session = data.session;
        _user = data.session?.user;
        if (_user != null) _localMode = false;
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) debugPrint('[AuthService] auth stream error: $error');
      },
    );
  }

  // Email + Password sign up
  Future<({bool success, String? error})> signUp(String email, String password) async {
    if (_client == null) return (success: false, error: 'No connection to server. App is running in local mode.');
    try {
      final response = await _client!.auth.signUp(email: email, password: password);
      if (response.session != null) {
        // Immediately signed in (email confirmation is disabled)
        _user = response.user;
        _session = response.session;
        _localMode = false;
        notifyListeners();
        return (success: true, error: null);
      } else if (response.user != null) {
        // User created but email confirmation is required — do NOT set
        // _user/_session so the app stays on the login screen.
        return (success: true, error: 'email_confirmation_required');
      }
      return (success: false, error: 'Sign up failed');
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Email + Password sign in
  Future<({bool success, String? error})> signIn(String email, String password) async {
    if (_client == null) return (success: false, error: 'No connection to server. App is running in local mode.');
    try {
      final response = await _client!.auth.signInWithPassword(email: email, password: password);
      _user = response.user;
      _session = response.session;
      _localMode = false;
      notifyListeners();
      return (success: true, error: null);
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Google OAuth
  Future<({bool success, String? error})> signInWithGoogle() async {
    if (_client == null) return (success: false, error: 'No connection to server.');
    try {
      await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.authCallbackUrl,
      );
      return (success: true, error: null);
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Apple OAuth
  Future<({bool success, String? error})> signInWithApple() async {
    if (_client == null) return (success: false, error: 'No connection to server.');
    try {
      await _client!.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: SupabaseConfig.authCallbackUrl,
      );
      return (success: true, error: null);
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Resend confirmation email
  Future<({bool success, String? error})> resendConfirmationEmail(String email) async {
    if (_client == null) return (success: false, error: 'No connection to server.');
    try {
      await _client!.auth.resend(type: OtpType.signup, email: email);
      return (success: true, error: null);
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Change password (requires current password verification)
  Future<({bool success, String? error})> changePassword(String currentPassword, String newPassword) async {
    if (_client == null) return (success: false, error: 'No connection to server.');
    if (_user?.email == null) return (success: false, error: 'No user logged in.');
    
    try {
      // First verify current password by re-authenticating
      final verifyResponse = await _client!.auth.signInWithPassword(
        email: _user!.email!,
        password: currentPassword,
      );
      if (verifyResponse.user == null) {
        return (success: false, error: 'Current password is incorrect.');
      }
      
      // Now update to new password
      await _client!.auth.updateUser(UserAttributes(password: newPassword));
      return (success: true, error: null);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') || e.message.toLowerCase().contains('password')) {
        return (success: false, error: 'Current password is incorrect.');
      }
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Update user display name
  Future<({bool success, String? error})> updateDisplayName(String displayName) async {
    if (_client == null) return (success: false, error: 'No connection to server.');
    try {
      await _client!.auth.updateUser(UserAttributes(data: {'display_name': displayName}));
      notifyListeners();
      return (success: true, error: null);
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Get display name
  String? get displayName => _user?.userMetadata?['display_name'] as String?;

  /// Signs the user out without making them wait on the network.
  ///
  /// GoTrue's `signOut()` drops the local session synchronously and *then*
  /// awaits a request that revokes the token server-side. Awaiting the whole
  /// call meant a slow or unreachable network froze the app on the settings
  /// screen with no indication anything was happening — sometimes for the
  /// full HTTP timeout.
  ///
  /// Local state is therefore cleared first and the revocation is left to
  /// finish in the background. Nothing is lost by not waiting: the session is
  /// already gone from this device either way, and the request retries
  /// nothing — it only tells the server to invalidate a token that will
  /// expire on its own regardless.
  Future<void> signOut() async {
    final client = _client;

    _user = null;
    _session = null;
    _localMode = false;
    notifyListeners();

    if (client == null) return;

    // Calling this without awaiting still clears GoTrue's in-memory session
    // and notifies its subscribers, because both happen before its first
    // await. Only the server round trip is left running.
    unawaited(
      client.auth
          .signOut()
          .timeout(const Duration(seconds: 10))
          .catchError((Object error) {
        if (kDebugMode) {
          debugPrint('[AuthService] background sign-out failed: $error');
        }
      }),
    );
  }
}
