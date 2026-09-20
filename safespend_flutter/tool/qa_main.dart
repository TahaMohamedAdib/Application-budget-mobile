import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:safespend_flutter/l10n/app_localizations.dart';
import 'package:safespend_flutter/main.dart' show MainScreen;
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/transaction.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/services/auth_service.dart';
import 'package:safespend_flutter/theme/app_theme.dart';

/// Development-only entry point used to exercise the authenticated application
/// shell without creating or changing a real account.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final provider = AppProvider();
  while (!provider.localDataLoaded) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }

  if (provider.accounts.isEmpty) {
    provider.addAccount(Account(
      id: 'qa-checking',
      name: 'QA Checking',
      type: 'bank',
      balance: 4800,
      bankName: 'SafeSpend QA',
    ));
    provider.addAccount(Account(
      id: 'qa-savings',
      name: 'QA Savings',
      type: 'savings',
      balance: 2200,
      bankName: 'SafeSpend QA',
    ));
    provider.addTransaction(Transaction(
      id: 'qa-income',
      type: 'income',
      amount: 6500,
      date: DateTime.now().toIso8601String(),
      description: 'Salary',
      accountId: 'qa-checking',
    ));
    provider.addTransaction(Transaction(
      id: 'qa-expense',
      type: 'expense',
      amount: 320,
      date: DateTime.now().toIso8601String(),
      description: 'Groceries',
      categoryId: 'groceries',
      accountId: 'qa-checking',
    ));
  }

  for (final feature in const ['coach', 'budgets', 'wealth']) {
    await provider.markFeatureGuideSeen(feature);
  }

  const localeCode = String.fromEnvironment('QA_LOCALE', defaultValue: 'en');
  provider.setLocale(localeCode);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const _QaApp(localeCode: localeCode),
    ),
  );
}

class _QaApp extends StatelessWidget {
  const _QaApp({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) => MaterialApp(
        title: 'SafeSpend QA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        locale: Locale(
          S.normalizeLocaleCode(provider.settings.locale.isEmpty
              ? localeCode
              : provider.settings.locale),
        ),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainScreen(),
      ),
    );
  }
}
