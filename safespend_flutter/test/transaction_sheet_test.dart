import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/today_screen.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/widgets/add_transaction_modal.dart';
import 'package:safespend_flutter/widgets/app_form_sheet.dart';

const surface = ValueKey('transaction-sheet-surface');
const close = ValueKey('transaction-sheet-close');
const fields = ValueKey('transaction-sheet-fields');

Future<AppProvider> openSheet(
  WidgetTester tester, {
  String type = 'income',
  String locale = 'en',
  Brightness brightness = Brightness.dark,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final provider = AppProvider();
  for (var i = 0; i < 100 && !provider.localDataLoaded; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  provider.addAccount(
      Account(id: 'bank', name: 'Bank', type: 'bank', balance: 500));
  provider.addAccount(
      Account(id: 'saving', name: 'Savings', type: 'savings', balance: 100));
  addTearDown(provider.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          locale: Locale(locale),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion,
            ),
            child: child!,
          ),
          home: Builder(
              builder: (context) => Stack(
                    children: [
                      if (size.width >= 390 &&
                          size.height >= 700 &&
                          textScale == 1)
                        const HomeScreen()
                      else
                        const Scaffold(),
                      Positioned(
                        top: 50,
                        right: 10,
                        child: TextButton(
                          onPressed: () =>
                              showTransactionSheet(context, initialType: type),
                          child: const Text('Open form'),
                        ),
                      ),
                    ],
                  )),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SAVE_SHEET_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/sheet-previews').create(recursive: true);
    await File('build/sheet-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await loader.load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final locale in ['en', 'fr', 'ar']) {
    for (final brightness in Brightness.values) {
      for (final type in ['expense', 'income', 'withdrawal', 'transfer']) {
        testWidgets(
            '$type opens compactly and keeps close reachable in $locale ${brightness.name}',
            (tester) async {
          final p = await openSheet(tester,
              type: type, locale: locale, brightness: brightness);
          expect(
              tester
                  .widget<EditableText>(find.byType(EditableText).first)
                  .focusNode
                  .hasFocus,
              isFalse);
          final bounds = tester.getRect(find.byKey(surface));
          expect(bounds.height, closeTo(844 * .74, 1));
          expect(bounds.top, greaterThan(190));
          expect(bounds.left, greaterThanOrEqualTo(10));
          final closePosition = tester.getCenter(find.byKey(close));
          await tester.enterText(find.byType(TextField).first, '25');
          await tester.drag(find.byKey(fields), const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.getCenter(find.byKey(close)), closePosition);
          if (locale == 'fr' &&
              type == 'expense' &&
              brightness == Brightness.light) {
            await preview(tester, 'expense-light-fr-scrolled');
          }
          expect(find.byKey(close).hitTestable(), findsOneWidget);
          await tester.tap(find.byKey(close));
          await tester.pumpAndSettle();
          expect(find.byType(AddTransactionModal), findsNothing);
          expect(p.transactions, isEmpty);
          expect(p.accounts.first.balance, 500);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final dismissal in ['outside', 'swipe', 'back']) {
    testWidgets('$dismissal dismisses without saving a draft', (tester) async {
      final p = await openSheet(tester);
      await tester.enterText(find.byType(TextField).first, '25');
      if (dismissal == 'outside') {
        await tester.tapAt(const Offset(195, 100));
      } else if (dismissal == 'swipe') {
        await tester.fling(
            find.byType(AppFormSheetHandle), const Offset(0, 600), 1500);
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(AddTransactionModal), findsNothing);
      expect(p.transactions, isEmpty);
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          isEmpty);
    });
  }

  testWidgets(
      'keyboard leaves close and submit usable; valid income saves once',
      (tester) async {
    final p = await openSheet(tester);
    await preview(tester, 'income-dark');
    await tester.enterText(find.byType(TextField).first, '25');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).bottom, lessThanOrEqualTo(544));
    expect(find.byKey(close).hitTestable(), findsOneWidget);
    expect(find.byType(ElevatedButton).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await preview(tester, 'income-keyboard');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionModal), findsNothing);
    expect(p.transactions.single.amount, 25);
    expect(p.accounts.first.balance, 525);
  });

  for (final size in [const Size(320, 640), const Size(844, 390)]) {
    testWidgets(
        'small viewport $size scrolls through fields with keyboard and large text',
        (tester) async {
      await openSheet(tester,
          type: 'expense',
          size: size,
          textScale: 1.5,
          locale: 'fr',
          brightness: Brightness.light);
      await tester.enterText(find.byType(TextField).first, '25');
      tester.view.viewInsets = const FakeViewPadding(bottom: 160);
      await tester.pumpAndSettle();
      expect(find.byKey(close).hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(close));
      await tester.pumpAndSettle();
      expect(find.byType(AddTransactionModal), findsNothing);
    });
  }

  testWidgets('reduced motion opens directly; light RTL presentation fits',
      (tester) async {
    await openSheet(tester,
        type: 'expense',
        locale: 'ar',
        brightness: Brightness.light,
        reduceMotion: true);
    final context = tester.element(find.byType(AddTransactionModal));
    expect(ModalRoute.of(context)!.transitionDuration, Duration.zero);
    expect(find.byKey(close).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await preview(tester, 'expense-light-ar');
  });
}
