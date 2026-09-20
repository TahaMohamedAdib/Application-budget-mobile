import 'package:safespend_flutter/services/auth_service.dart';
import 'dart:convert';
import 'transaction_sheet_test.dart' as snapshots;
import 'package:safespend_flutter/widgets/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/category.dart';
import 'package:safespend_flutter/models/daret.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/holding.dart';
import 'package:safespend_flutter/models/recurring_rule.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/account_screen.dart';
import 'package:safespend_flutter/screens/accounts_screen.dart';
import 'package:safespend_flutter/screens/all_subscriptions_screen.dart';
import 'package:safespend_flutter/screens/budgets_screen.dart';
import 'package:safespend_flutter/screens/daret_screen.dart';
import 'package:safespend_flutter/screens/debt_screen.dart';
import 'package:safespend_flutter/screens/goals_screen.dart';
import 'package:safespend_flutter/screens/personal_debts_screen.dart';
import 'package:safespend_flutter/screens/plan_screen.dart';
import 'package:safespend_flutter/screens/portfolio_screen.dart';
import 'package:safespend_flutter/screens/settings/appearance_screen.dart';
import 'package:safespend_flutter/screens/settings/currency_format_screen.dart';
import 'package:safespend_flutter/screens/settings/currency_picker_screen.dart';
import 'package:safespend_flutter/screens/settings/income_screen.dart';
import 'package:safespend_flutter/screens/settings/language_screen.dart';
import 'package:safespend_flutter/screens/settings/notifications_screen.dart';
import 'package:safespend_flutter/screens/settings/security_screen.dart';
import 'package:safespend_flutter/screens/settings/data_storage_screen.dart';
import 'package:safespend_flutter/screens/settings/pin_entry_screen.dart';
import 'package:safespend_flutter/screens/settings_screen.dart';
import 'package:safespend_flutter/theme/app_icons.dart';
import 'package:safespend_flutter/widgets/wealth_ui.dart';
import 'core_feature_logic_test.dart' as fixture;
import 'app_form_sheet_test.dart' as shared;

class TestAuth extends AuthService {
  @override
  bool get localMode => false;
  @override
  String? get displayName => 'Test user';
}

class FormCase {
  const FormCase(this.name, this.screen, {this.action = 'launch'});
  final String name;
  final Widget Function(AppProvider) screen;
  final String action;
}

final holding = Holding(
    id: 'holding', symbol: 'TEST', shares: 10, costBasis: 10, currentPrice: 12);
final cases = <FormCase>[
  FormCase('account add', (p) => AddAccountModal(onSave: p.addAccount)),
  FormCase(
      'account edit',
      (p) =>
          AddAccountModal(account: p.accounts.first, onSave: p.updateAccount)),
  FormCase('holding add', (p) => AddHoldingModal(onSave: p.addHolding)),
  FormCase('holding edit',
      (p) => AddHoldingModal(holding: holding, onSave: p.updateHolding)),
  FormCase(
      'holding sale',
      (p) => SellHoldingModal(
          holding: holding,
          accounts: p.accounts,
          cashBalance: 0,
          currencySymbol: 'MAD',
          onSell: (
              {required sharesToSell,
              required sellPrice,
              required accountId,
              required transactionId}) {})),
  FormCase('bill add', (p) => AddBillModal(onSave: p.addRecurringRule)),
  FormCase(
      'bill edit',
      (p) => AddBillModal(
          bill: p.recurringRules.first, onSave: p.updateRecurringRule)),
  FormCase('category add', (_) => const BudgetsScreen(), action: 'categoryAdd'),
  FormCase('category edit', (_) => const BudgetsScreen(),
      action: 'categoryEdit'),
  FormCase('goal add', (_) => const GoalsScreen(), action: 'add'),
  FormCase('goal edit', (_) => const GoalsScreen(), action: 'edit'),
  FormCase('goal contribution', (_) => const GoalsScreen(),
      action: 'contribute'),
  FormCase('debt add', (_) => const DebtScreen(), action: 'add'),
  FormCase('debt edit', (_) => const DebtScreen(), action: 'edit'),
  FormCase('debt payment', (_) => const DebtScreen(), action: 'pay'),
  FormCase('personal debt add', (_) => const PersonalDebtsScreen(),
      action: 'add'),
  FormCase('personal debt edit', (_) => const PersonalDebtsScreen(),
      action: 'edit'),
  FormCase('personal debt return', (_) => const PersonalDebtsScreen(),
      action: 'received'),
  FormCase('circle add', (_) => const DaretScreen(), action: 'add'),
  FormCase('circle edit', (_) => const DaretScreen(), action: 'circleEdit'),
  FormCase('subscription edit', (_) => const AllSubscriptionsScreen(),
      action: 'subscription'),
  FormCase('profile name', (_) => const AccountScreen(), action: 'edit'),
  FormCase('profile password', (_) => const AccountScreen(), action: 'change'),
  FormCase('appearance', (_) => const AppearanceScreen()),
  FormCase('currency format', (_) => const CurrencyFormatScreen()),
  FormCase('currency selection', (_) => const CurrencyPickerScreen()),
  FormCase('income', (_) => const IncomeScreen()),
  FormCase('language', (_) => const LanguageScreen()),
  FormCase('notifications', (_) => const NotificationsScreen()),
  FormCase('security', (_) => const SecurityScreen()),
  FormCase('data preferences', (_) => const DataStorageScreen()),
  FormCase('PIN setup', (_) => const PinEntryScreen(mode: PinMode.create)),
];

Future<AppProvider> seed(WidgetTester tester, String locale) async {
  final p = (await tester.runAsync(fixture.emptyProvider))!;
  addTearDown(p.dispose);
  p.setLocale(locale);
  p.addAccount(
      Account(id: 'bank', name: 'Test Bank', type: 'bank', balance: 1000));
  p.addCategory(Category(
      id: 'category',
      name: 'Test category',
      icon: 'shopping_cart',
      group: 'variable',
      color: '#007F73',
      budgetLimit: 200));
  p.addGoal(Goal(id: 'goal', name: 'Test goal', targetAmount: 500));
  p.addGoal(
      Goal(id: 'debt', name: 'Test debt', type: 'debt', targetAmount: 500));
  p.addGoal(Goal(
      id: 'personal',
      name: 'Test personal',
      type: 'personal_debt',
      targetAmount: 500));
  p.addHolding(holding);
  p.addDaret(Daret(
      id: 'circle',
      name: 'Test circle',
      contributionPerShare: 20,
      totalShares: 5,
      payoutMonths: [2],
      startDate: '2099-01-01',
      paymentSourceId: 'bank',
      destinationAccountId: 'bank'));
  p.addRecurringRule(RecurringRule(
      id: 'rule',
      templateTransaction: Transaction(
          id: 'template',
          type: 'expense',
          amount: 10,
          date: '2099-01-01',
          accountId: 'bank',
          note: 'Test subscription',
          expenseSubType: 'subscription'),
      frequency: 'monthly',
      nextDate: '2099-01-01',
      isActive: true));
  return p;
}

String snapshot(AppProvider p) => jsonEncode([
      p.accounts.map((e) => e.toJson()).toList(),
      p.categories.map((e) => e.toJson()).toList(),
      p.goals.map((e) => e.toJson()).toList(),
      p.holdings.map((e) => e.toJson()).toList(),
      p.darets.map((e) => e.toJson()).toList(),
      p.recurringRules.map((e) => e.toJson()).toList(),
      p.transactions.map((e) => e.toJson()).toList()
    ]);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 15 && finder.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.tap(finder.hitTestable().first);
  await tester.pumpAndSettle();
}

Future<void> openCase(WidgetTester tester, FormCase c, AppProvider p,
    String locale, Brightness brightness) async {
  final report = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint(details.toString());
    report?.call(details);
  };
  final s = S.forLocale(locale);
  final screen = c.action == 'launch'
      ? shared.formLauncher((_) => c.screen(p))
      : c.screen(p);
  final auth = TestAuth();
  addTearDown(auth.dispose);
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('preview'),
      child: shared.formHost(screen,
          provider: p, locale: locale, brightness: brightness, auth: auth)));
  await tester.pumpAndSettle();
  switch (c.action) {
    case 'launch':
      await tapVisible(tester, find.text('Open editor'));
    case 'add':
      final header =
          tester.widget<WealthPageHeader>(find.byType(WealthPageHeader));
      await tapVisible(tester, find.byTooltip(header.addTooltip));
    case 'categoryAdd':
      await tapVisible(tester, find.text(s.addCategory));
    case 'categoryEdit':
      await tapVisible(
          tester,
          find.byWidgetPredicate(
              (w) => w is AppIcon && w.icon == AppIcons.edit));
    case 'edit':
      await tapVisible(tester, find.text(s.edit));
    case 'contribute':
      await tapVisible(tester, find.text(s.tr('addSavings')));
    case 'pay':
      await tapVisible(tester, find.text(s.pay));
    case 'received':
      await tapVisible(tester, find.text(s.received).last);
    case 'change':
      await tapVisible(tester, find.text(s.change));
    case 'subscription':
      await tapVisible(tester, find.text('Test subscription'));
    case 'circleEdit':
      await tapVisible(tester, find.text('Test circle'));
      await tapVisible(tester, find.text(s.edit));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(shared.loadFormFonts);
  setUp(() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      original?.call(details);
    };
  });
  for (final locale in ['en', 'fr', 'ar', 'de']) {
    for (final brightness in Brightness.values) {
      for (final c in cases) {
        testWidgets('${c.name} opens and cancels in $locale ${brightness.name}',
            (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final p = await seed(tester, locale);
          final before = snapshot(p);
          await openCase(tester, c, p, locale, brightness);
          expect(find.byKey(shared.formSurface), findsOneWidget);
          expect(tester.getRect(find.byKey(shared.formSurface)).height,
              closeTo(844 * .74, 1));
          expect(tester.testTextInput.isVisible, isFalse);
          if (locale == 'fr' &&
              [
                'category add',
                'account edit',
                'circle add',
                'profile password',
                'income',
                'PIN setup'
              ].contains(c.name))
            await snapshots.preview(
                tester, 'forms-${c.name}-${brightness.name}');
          final position = tester.getCenter(find.byKey(shared.formClose));
          await tester.drag(
              find.byKey(shared.formFields), const Offset(0, -800));
          await tester.pumpAndSettle();
          expect(tester.getCenter(find.byKey(shared.formClose)), position);
          await tester.tap(find.byKey(shared.formClose).last);
          await tester.pumpAndSettle();
          expect(find.byKey(shared.formSurface), findsNothing);
          expect(snapshot(p), before);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
  }
  testWidgets(
      'category draft cancels, reopening starts fresh, and save adds exactly once',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final p = await seed(tester, 'en');
    final count = p.categories.length;
    final c = cases.firstWhere((c) => c.name == 'category add');
    await openCase(tester, c, p, 'en', Brightness.dark);
    await tester.enterText(find.byType(TextField).first, 'Unsaved category');
    await tester.tap(find.byKey(shared.formClose).last);
    await tester.pumpAndSettle();
    expect(p.categories.length, count);
    await tapVisible(tester, find.text(S.forLocale('en').addCategory));
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty);
    await tester.enterText(find.byType(TextField).first, 'New category');
    await tester.enterText(find.byType(TextField).at(1), '120');
    await tapVisible(
        tester,
        find.descendant(
            of: find.byKey(shared.formSurface),
            matching: find.byType(ElevatedButton)));
    expect(p.categories.length, count + 1);
    expect(p.categories.last.budgetLimit, 120);
    expect(find.byKey(shared.formSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'debt payment validates, commits once, and updates the saved balance',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final p = await seed(tester, 'en');
    final c = cases.firstWhere((c) => c.name == 'debt payment');
    await openCase(tester, c, p, 'en', Brightness.dark);
    final save = find.descendant(
        of: find.byKey(shared.formSurface),
        matching: find.byType(ElevatedButton));
    await tapVisible(tester, save);
    expect(p.goals.singleWhere((g) => g.id == 'debt').currentAmount, 0);
    await tester.enterText(find.byType(TextField).first, '25');
    await tapVisible(tester, save);
    expect(p.goals.singleWhere((g) => g.id == 'debt').currentAmount, 25);
    expect(find.byKey(shared.formSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'settings navigation and nested currency picker use editor sheets',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final p = await seed(tester, 'en');
    final s = S.forLocale('en');
    await tester
        .pumpWidget(shared.formHost(const SettingsScreen(), provider: p));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(s.currencyAndFormat));
    expect(find.byKey(shared.formSurface), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(SettingsRow, s.currency));
    expect(find.byType(CurrencyPickerScreen), findsOneWidget);
    await tester.tap(find.byKey(shared.formClose).last);
    await tester.pumpAndSettle();
    expect(find.byType(CurrencyFormatScreen), findsOneWidget);
    await tester.tap(find.byKey(shared.formClose).last);
    await tester.pumpAndSettle();
    expect(find.byKey(shared.formSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
