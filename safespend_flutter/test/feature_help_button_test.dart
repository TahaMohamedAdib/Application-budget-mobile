import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/widgets/feature_help_button.dart';

void main() {
  testWidgets('screen help button opens and closes a localized guide',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: FeatureHelpButton(
              title: S.of(context).tourHomeTitle,
              description: S.of(context).tourHomeBody,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('feature-help-button')));
    await tester.pumpAndSettle();

    expect(find.text(S.forLocale('fr').tourHomeTitle), findsOneWidget);
    expect(find.text(S.forLocale('fr').tourHomeBody), findsOneWidget);
    expect(find.text(S.forLocale('fr').gotIt), findsOneWidget);

    await tester.tap(find.text(S.forLocale('fr').gotIt));
    await tester.pumpAndSettle();
    expect(find.text(S.forLocale('fr').tourHomeTitle), findsNothing);
  });
}
