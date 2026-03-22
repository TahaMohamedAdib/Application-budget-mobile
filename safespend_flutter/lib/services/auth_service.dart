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
      _localMode = true;
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      final session = _client!.auth.currentSession;
      _session = session;
      _user = session?.user;
    } catch (e) {
      // Can't reach Supabase — fall back to local mode
      _localMode = true;
    } finally {
      _loading = false;
      notifyListeners();
    }

    try {
      _client!.auth.onAuthStateChange.listen((data) {
        _session = data.session;
        _user = data.session?.user;
        _localMode = false;
        _loading = false;
        notifyListeners();
      });
    } catch (_) {}
  }

  // Email + Password sign up
  Future<({bool success, String? error})> signUp(String email, String password) async {
    if (_client == null) return (success: false, error: 'No connection to server. App is running in local mode.');
    try {
      final response = await _client!.auth.signUp(email: email, password: password);
      if (response.user != null) {
        _user = response.user;
        _session = response.session;
        _localMode = false;
        notifyListeners();
        return (success: true, error: null);
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

  // Sign out
  Future<void> signOut() async {
    if (_client != null) {
      try {
        await _client!.auth.signOut();
      } catch (_) {}
    }
    _user = null;
    _session = null;
    _localMode = false;
    notifyListeners();
  }
}
