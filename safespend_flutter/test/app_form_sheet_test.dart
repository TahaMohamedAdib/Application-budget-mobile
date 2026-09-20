import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/widgets/app_form_sheet.dart';

const formSurface = ValueKey('app-form-sheet-surface');
const formFields = ValueKey('app-form-sheet-fields');
const formClose = ValueKey('app-form-sheet-close');

Future<void> loadFormFonts() async {
  await (FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')))
      .load();
  await (FontLoader('packages/cupertino_icons/CupertinoIcons')
        ..addFont(rootBundle
            .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
      .load();
}

Widget formHost(Widget screen,
    {String locale = 'en',
    Brightness brightness = Brightness.dark,
    double textScale = 1,
    AppProvider? provider,
    AuthService? auth,
    bool reduceMotion = false}) {
  return MultiProvider(
    providers: [
      if (provider != null) ChangeNotifierProvider.value(value: provider),
      if (auth != null)
        ChangeNotifierProvider<AuthService>.value(value: auth)
      else
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      locale: Locale(locale),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion),
          child: child!),
      home: screen,
    ),
  );
}

Widget formLauncher(WidgetBuilder builder) => Scaffold(
    body: Builder(
        builder: (context) => TextButton(
              onPressed: () =>
                  showAppFormSheet<void>(context: context, builder: builder),
              child: const Text('Open editor'),
            )));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFormFonts);

  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(844, 390)
  ]) {
    for (final locale in ['en', 'fr', 'ar']) {
      testWidgets(
          'editor stays usable at $size in $locale with large text and keyboard',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        var saves = 0;
        await tester.pumpWidget(formHost(
            formLauncher((ctx) => AppFormSheet(
                  header: Text(S.of(ctx).edit,
                      style: Theme.of(ctx).textTheme.titleLarge),
                  body: Column(children: [
                    TextField(controller: controller),
                    const SizedBox(height: 700),
                    const Text('Final field')
                  ]),
                  actions: ElevatedButton(
                      onPressed: () => saves++, child: Text(S.of(ctx).save)),
                )),
            locale: locale,
            textScale: 1.6));
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        final bounds = tester.getRect(find.byKey(formSurface));
        expect(bounds.height, lessThanOrEqualTo(size.height * .74 + 1));
        expect(bounds.left, greaterThanOrEqualTo(10));
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.tap(find.byType(TextField));
        await tester.pump();
        tester.view.viewInsets =
            FakeViewPadding(bottom: size.height > 500 ? 280 : 120);
        await tester.pumpAndSettle();
        final closePosition = tester.getCenter(find.byKey(formClose));
        final button =
            find.widgetWithText(ElevatedButton, S.forLocale(locale).save);
        await tester.scrollUntilVisible(button, 180,
            scrollable: find
                .descendant(
                    of: find.byKey(formFields),
                    matching: find.byType(Scrollable))
                .first);
        expect(tester.getCenter(find.byKey(formClose)), closePosition);
        await tester.tap(button);
        await tester.pump();
        expect(saves, 1);
        await tester.tap(find.byKey(formClose));
        await tester.pumpAndSettle();
        expect(find.byKey(formSurface), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final dismissal in ['close', 'outside', 'back', 'swipe']) {
    testWidgets('$dismissal cancels an editor without submitting',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var saves = 0;
      await tester.pumpWidget(formHost(
          formLauncher((ctx) => AppFormSheet(
                header: Text(S.of(ctx).edit),
                body: const TextField(),
                actions: ElevatedButton(
                    onPressed: () => saves++, child: Text(S.of(ctx).save)),
              )),
          reduceMotion: true));
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsaved');
      switch (dismissal) {
        case 'close':
          await tester.tap(find.byKey(formClose));
        case 'outside':
          await tester.tapAt(const Offset(20, 80));
        case 'back':
          await tester.binding.handlePopRoute();
        case 'swipe':
          await tester.drag(
              find.byType(AppFormSheetHandle), const Offset(0, 640));
      }
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(find.byKey(formSurface), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
