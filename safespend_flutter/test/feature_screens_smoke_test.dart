import 'core_feature_logic_test.dart' as fixture;
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/goal.dart';
import 'package:safespend_flutter/models/holding.dart';
import 'package:safespend_flutter/models/daret.dart';
import 'package:safespend_flutter/models/recurring_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/screens/account_screen.dart';
import 'package:safespend_flutter/screens/accounts_screen.dart';
import 'package:safespend_flutter/screens/all_subscriptions_screen.dart';
import 'package:safespend_flutter/screens/auth_screen.dart';
import 'package:safespend_flutter/screens/budgets_screen.dart';
import 'package:safespend_flutter/screens/cash_on_hand_screen.dart';
import 'package:safespend_flutter/screens/coach_screen.dart';
import 'package:safespend_flutter/screens/daret_screen.dart';
import 'package:safespend_flutter/screens/debt_screen.dart';
import 'package:safespend_flutter/screens/goals_screen.dart';
import 'package:safespend_flutter/screens/personal_debts_screen.dart';
import 'package:safespend_flutter/screens/plan_screen.dart';
import 'package:safespend_flutter/screens/portfolio_screen.dart';
import 'package:safespend_flutter/screens/spending_screen.dart';
import 'package:safespend_flutter/screens/today_screen.dart';
import 'package:safespend_flutter/screens/transactions_screen.dart';
import 'package:safespend_flutter/screens/wealth_screen.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/theme/app_theme.dart';

final _featureScreens = <String, Widget Function()>{
  'today': () => const HomeScreen(),
  'coach': () => const CoachScreen(),
  'budgets': () => const BudgetsScreen(),
  'wealth': () => const WealthScreen(),
  'accounts': () => const AccountsScreen(),
  'cash_on_hand': () => const CashOnHandScreen(),
  'portfolio': () => const PortfolioScreen(),
  'debts': () => const DebtScreen(),
  'personal_debts': () => const PersonalDebtsScreen(),
  'goals': () => const GoalsScreen(),
  'daret': () => const DaretScreen(),
  'subscriptions': () => const AllSubscriptionsScreen(),
  'spending': () => const SpendingScreen(),
  'transactions': () => const TransactionsScreen(),
  'legacy_plan': () => const PlanScreen(),
  'auth': () => const AuthScreen(),
  'account_profile': () => const AccountScreen(),
};

Widget host(Widget child, Brightness brightness,
        {String locale = 'en', AppProvider? provider}) =>
    MultiProvider(
      providers: [
        if (provider == null)
          ChangeNotifierProvider(create: (_) => AppProvider())
        else
          ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider(create: (_) => AuthService()),
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
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in S.supportedLocales) {
    for (final brightness in Brightness.values) {
      for (final entry in _featureScreens.entries) {
        testWidgets(
            '${entry.key} builds in ${locale.languageCode} ${brightness.name} mode',
            (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final originalErrorHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            debugPrint(details.toString());
            originalErrorHandler?.call(details);
          };

          await tester.pumpWidget(
              host(entry.value(), brightness, locale: locale.languageCode));
          await tester.pump(const Duration(milliseconds: 500));

          expect(tester.takeException(), isNull);

          // Dispose stateful screens before leaving the test so delayed plugin
          // fallbacks cannot report setState-after-dispose in the next case.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
  }
  for (final locale in S.supportedLocales) {
    for (final entry in _featureScreens.entries
        .where((e) => !['auth', 'account_profile', 'coach'].contains(e.key))) {
      testWidgets('${entry.key} with populated data in ${locale.languageCode}',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final originalErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          originalErrorHandler?.call(details);
        };
        final provider = (await tester.runAsync(fixture.emptyProvider))!;
        addTearDown(provider.dispose);
        provider.setLocale(locale.languageCode);
        provider.addAccount(Account(
            id: 'bank', name: 'Test Bank', type: 'bank', balance: 1000));
        provider.addAccount(Account(
            id: 'savings',
            name: 'Test Savings',
            type: 'savings',
            balance: 200));
        provider
            .addGoal(Goal(id: 'goal', name: 'Test Goal', targetAmount: 200));
        provider.addGoal(Goal(
            id: 'debt',
            name: 'Test Loan',
            type: 'debt',
            targetAmount: 500,
            currentAmount: 100));
        provider.addGoal(Goal(
            id: 'personal',
            name: 'Test Lending',
            type: 'personal_debt',
            targetAmount: 300,
            currentAmount: 50));
        provider.contributeToGoalFromSource('goal', 50, 'bank');
        final expense = fixture
            .transaction(
                id: 'expense', type: 'expense', amount: 40, accountId: 'bank')
            .copyWith(categoryId: 'groceries');
        provider.addTransaction(expense);
        provider.addTransaction(fixture.transaction(
            id: 'cash', type: 'withdrawal', amount: 100, accountId: 'bank'));
        provider.addRecurringRule(RecurringRule(
            id: 'bill',
            templateTransaction: expense,
            frequency: 'monthly',
            nextDate:
                DateTime.now().add(const Duration(days: 5)).toIso8601String()));
        provider.addHolding(Holding(
            id: 'holding',
            symbol: 'TEST',
            shares: 2,
            costBasis: 30,
            currentPrice: 35));
        provider.addDaret(Daret(
            id: 'daret',
            name: 'Test Circle',
            contributionPerShare: 20,
            totalShares: 5,
            payoutMonths: [3],
            startDate: DateTime.now().toIso8601String(),
            paymentSourceId: 'bank',
            destinationAccountId: 'bank'));
        await tester.pumpWidget(host(entry.value(), Brightness.light,
            locale: locale.languageCode, provider: provider));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        // Exercise the lower content as well as the first viewport.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -550));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}
