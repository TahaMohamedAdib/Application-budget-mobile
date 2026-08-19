import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/providers/app_provider.dart';

/// Sign-out routing.
///
/// `main._buildHome` shows the splash while `!provider.localDataLoaded`, then
/// the auth screen once the user is no longer authenticated. `clearData()`
/// used to reset that flag, and nothing re-runs `loadData()` afterwards — so
/// signing out parked the app on the splash spinner permanently, with no way
/// back short of force-quitting.
///
/// These assert the provider state the splash gate reads, so the lockout
/// cannot come back unnoticed.

void main() {
  // AppProvider reaches platform channels (SharedPreferences, connectivity)
  // as soon as it is constructed.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppProvider> loadedProvider() async {
    final provider = AppProvider();
    // The constructor kicks off loadData(); give it a turn to finish.
    for (var i = 0; i < 20 && !provider.localDataLoaded; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.localDataLoaded, isTrue,
        reason: 'setup precondition: local data should load');
    return provider;
  }

  test('clearData leaves the splash gate open', () async {
    final provider = await loadedProvider();

    provider.clearData();

    // The splash is shown while this is false. After a sign-out the app must
    // fall through to the auth screen instead.
    expect(
      provider.localDataLoaded,
      isTrue,
      reason: 'sign-out would strand the app on the splash screen',
    );
  });

  test('clearData still empties the data it is meant to', () async {
    final provider = await loadedProvider();

    provider.clearData();

    expect(provider.accounts, isEmpty);
    expect(provider.transactions, isEmpty);
    expect(provider.goals, isEmpty);
    expect(provider.holdings, isEmpty);
    expect(provider.setupComplete, isFalse);
    // The next user must fetch their own rows rather than inherit these.
    expect(provider.supabaseDataLoaded, isFalse);
  });

  test('clearData notifies listeners so the router re-evaluates', () async {
    final provider = await loadedProvider();

    var notified = 0;
    provider.addListener(() => notified++);

    provider.clearData();

    expect(notified, greaterThan(0));
  });
}
