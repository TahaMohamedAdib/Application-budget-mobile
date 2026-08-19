import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/widgets/settings_ui.dart';

/// The confirmation alert guards sign-out and "erase all data", so the two
/// things that must never regress are which button returns which answer, and
/// that a stray tap on the backdrop cannot read as consent.

Widget _host(Widget child, Brightness brightness) => MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      locale: const Locale('en'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

void main() {
  /// Opens the alert and returns a holder the test can read after tapping,
  /// so the boolean the caller actually receives is what gets asserted.
  Future<List<bool?>> openAlert(
    WidgetTester tester, {
    bool destructive = true,
  }) async {
    final answer = <bool?>[];
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  answer.add(await showSettingsConfirm(
                    context,
                    title: 'Log Out?',
                    message: 'You will need to sign in again.',
                    confirmLabel: 'Log Out',
                    cancelLabel: 'Cancel',
                    destructive: destructive,
                  ));
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        Brightness.dark,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('shows the title, message and both actions', (tester) async {
    await openAlert(tester);
    expect(find.text('Log Out?'), findsOneWidget);
    expect(find.text('You will need to sign in again.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('confirming returns true', (tester) async {
    final answer = await openAlert(tester);
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(answer, [true]);
    expect(find.text('Log Out?'), findsNothing);
  });

  testWidgets('cancelling returns false', (tester) async {
    final answer = await openAlert(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answer, [false]);
    expect(find.text('Log Out?'), findsNothing);
  });

  testWidgets('dismissing by tapping the backdrop is not consent',
      (tester) async {
    final answer = await openAlert(tester);
    // A stray tap outside must never read as "yes, log me out".
    await tester.tapAt(const Offset(20, 40));
    await tester.pumpAndSettle();
    expect(answer, [false]);
  });

  testWidgets('the destructive action is red, the cancel action is not',
      (tester) async {
    await openAlert(tester);

    final confirm = tester.widget<Text>(find.text('Log Out'));
    final cancel = tester.widget<Text>(find.text('Cancel'));

    expect(confirm.style?.color, AppTheme.error);
    expect(cancel.style?.color, isNot(AppTheme.error));
    // The destructive choice also carries the heavier weight, as on iOS.
    expect(confirm.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('a non-destructive confirm uses the accent, not red',
      (tester) async {
    await openAlert(tester, destructive: false);
    final confirm = tester.widget<Text>(find.text('Log Out'));
    expect(confirm.style?.color, AppTheme.goldPrimary);
  });

  testWidgets('builds in light mode too', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSettingsConfirm(
                  context,
                  title: 'Erase everything?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Erase',
                  cancelLabel: 'Keep',
                  destructive: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        Brightness.light,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Erase everything?'), findsOneWidget);
  });
}
