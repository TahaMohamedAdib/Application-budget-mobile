import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'utils/currency_helper.dart';
import 'widgets/app_picker_field.dart';
import 'package:uuid/uuid.dart';
import 'providers/app_provider.dart';
import 'services/supabase_config.dart';
import 'services/supabase_sync_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_icons.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'models/transaction.dart';
import 'models/recurring_rule.dart';
import 'screens/today_screen.dart' show HomeScreen, HomeScreenState;
import 'screens/budgets_screen.dart';
import 'screens/wealth_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'widgets/add_transaction_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Catch any init errors so runApp always executes
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    if (kDebugMode) debugPrint('[main] Supabase init failed: $e');
  }

  try {
    await SupabaseSyncService.initializeOfflineSync();
  } catch (e) {
    if (kDebugMode) debugPrint('[main] Offline sync init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildHome(
      BuildContext context, AuthService auth, AppProvider provider) {
    if (kDebugMode)
      debugPrint(
          '[_buildHome] auth.loading=${auth.loading} localDataLoaded=${provider.localDataLoaded} isAuth=${auth.isAuthenticated} supaLoaded=${provider.supabaseDataLoaded} setupComplete=${provider.setupComplete} accounts=${provider.accounts.length}');
    // Still loading local data or auth state
    if (auth.loading || !provider.localDataLoaded) {
      return const _SplashScreen();
    }

    // Not authenticated → show login
    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }

    // Authenticated but Supabase data not loaded yet → trigger load + show splash
    if (!provider.supabaseDataLoaded) {
      final uid = auth.userId;
      if (uid != null) {
        // Schedule after the current frame to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadFromSupabase(uid);
        });
      }
      return const _SplashScreen();
    }

    // Has data → skip onboarding if accounts exist
    if (provider.setupComplete || provider.accounts.isNotEmpty) {
      return const MainScreen();
    }

    return OnboardingFlow(onComplete: () => provider.markSetupComplete());
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild MaterialApp when theme mode changes
    return Selector<AppProvider, ({String themeMode, String locale})>(
      selector: (_, p) =>
          (themeMode: p.settings.themeMode, locale: p.settings.locale),
      builder: (context, settings, child) {
        final themeMode = settings.themeMode;
        final locale = S.normalizeLocaleCode(settings.locale);
        ThemeMode resolvedThemeMode;
        switch (themeMode) {
          case 'light':
            resolvedThemeMode = ThemeMode.light;
            break;
          case 'dark':
            resolvedThemeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            resolvedThemeMode = ThemeMode.system;
            break;
        }
        return MaterialApp(
          title: 'SafeSpend',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: resolvedThemeMode,
          locale: Locale(locale),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Home screen routing consumes only the fields it needs
          home: Consumer2<AppProvider, AuthService>(
            builder: (context, provider, auth, _) {
              return _buildHome(context, auth, provider);
            },
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                size: 64, color: AppTheme.brandPrimary),
            const SizedBox(height: 16),
            Text('SafeSpend',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandPrimary)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.brandPrimary),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final PageController _pageController;
  bool _isMenuOpen = false;
  late final AnimationController _menuAnimController;
  late final Animation<double> _menuAnimation;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  Timer? _subscriptionTimer;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      const CoachScreen(),
      const BudgetsScreen(),
      const WealthScreen(),
    ];
    _pageController = PageController();
    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(
        parent: _menuAnimController, curve: Curves.easeOutCubic);

    // Check every minute for subscriptions that have become due
    _subscriptionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.processSubscriptions();
      provider.processDaretPayouts();
    });
  }

  @override
  void dispose() {
    _subscriptionTimer?.cancel();
    _pageController.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (index == 0 && _selectedIndex == 0) {
      _homeKey.currentState?.resetToAll();
    }
    _closeMenu();
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      setState(() => _isMenuOpen = true);
      _menuAnimController.forward();
    }
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
      _menuAnimController.reverse();
    }
  }

  void _openTransactionModal(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(initialType: type),
    );
  }

  void _openAddBillModal() {
    _closeMenu();
    final provider = Provider.of<AppProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickAddBillModal(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          // Scaffold — body is just the page view; nav bar is the pill
          Scaffold(
            extendBody: true,
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _screens,
            ),
            bottomNavigationBar: _buildPillNavBar(isDark),
          ),

          // Scrim — above Scaffold (including nav bar)
          AnimatedBuilder(
            animation: _menuAnimation,
            builder: (_, __) {
              if (_menuAnimation.value == 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * _menuAnimation.value),
                  ),
                ),
              );
            },
          ),

          // Quick actions panel — above nav bar + bump
          if (_selectedIndex != 1)
            AnimatedBuilder(
              animation: _menuAnimation,
              builder: (_, __) {
                if (_menuAnimation.value == 0) return const SizedBox.shrink();
                return Positioned(
                  bottom: bottomPadding + 100,
                  left: 16,
                  right: 16,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - _menuAnimation.value)),
                    child: Opacity(
                      opacity: _menuAnimation.value,
                      child: _buildQuickActionsPanel(isDark),
                    ),
                  ),
                );
              },
            ),

          // Bump circle — same color as pill, merges seamlessly with nav bar
          if (_selectedIndex != 1)
            Positioned(
              bottom: bottomPadding + 28,
              left: 0,
              right: 0,
              child: Center(
                child: ClipOval(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: 68,
                    height: 68,
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightBackground,
                  ),
                ),
              ),
            ),

          // FAB — 25% above pill top edge, crisp anti-aliased circle
          if (_selectedIndex != 1)
            Positioned(
              bottom: bottomPadding + 34,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: AnimatedBuilder(
                    animation: _menuAnimation,
                    builder: (_, __) => DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppTheme.success,
                          child: Center(
                            child: AnimatedRotation(
                              turns: _isMenuOpen ? 0.125 : 0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel(bool isDark) {
    final bg = isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground;
    final actions = [
      ('Expense', Icons.arrow_upward_rounded, AppTheme.error, 'expense'),
      ('Income', Icons.arrow_downward_rounded, AppTheme.success, 'income'),
      (
        'Withdraw',
        Icons.account_balance_wallet_rounded,
        AppTheme.warning,
        'withdrawal'
      ),
      ('Transfer', Icons.swap_horiz_rounded, AppTheme.info, 'transfer'),
    ];

    return Center(
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.14),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(actions.length, (i) {
            final (label, icon, color, type) = actions[i];
            final isLast = i == actions.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _closeMenu();
                      _openTransactionModal(type);
                    },
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(20) : Radius.zero,
                      bottom: isLast ? const Radius.circular(20) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color.withOpacity(isDark ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      indent: 62,
                      endIndent: 16,
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.06)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPillNavBar(bool isDark) {
    final pillBg = isDark ? AppTheme.darkSurface : AppTheme.lightBackground;
    final activeColor = AppTheme.success;
    final inactiveColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPillNavItem(0, AppIcons.home, activeColor, inactiveColor),
                _buildPillNavItem(
                    1, AppIcons.aiCoach, activeColor, inactiveColor),
                // Center bump/FAB placeholder
                const SizedBox(width: 72),
                _buildPillNavItem(
                    2, AppIcons.budgets, activeColor, inactiveColor),
                _buildPillNavItem(
                    3, AppIcons.wealth, activeColor, inactiveColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillNavItem(
      int index, String icon, Color activeColor, Color inactiveColor) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: _PressScaleDetector(
        onTap: () => _onTabTapped(index),
        child: Center(
          child: Iconify(
            icon,
            size: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}

// Quick Add Bill Modal — standalone modal for adding a recurring bill from the speed dial
class _QuickAddBillModal extends StatefulWidget {
  final AppProvider provider;
  const _QuickAddBillModal({required this.provider});

  @override
  State<_QuickAddBillModal> createState() => _QuickAddBillModalState();
}

class _QuickAddBillModalState extends State<_QuickAddBillModal> {
  late final S s;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedFrequency = 'monthly';
  DateTime _nextDate = DateTime.now();
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    s = S.of(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = widget.provider;
    if (_selectedAccountId == null) {
      _selectedAccountId = provider.accounts.isNotEmpty
          ? provider.accounts.first.id
          : AppProvider.cashOnHandId;
    }
    final cf = CurrencyHelper.formatter(provider.settings.currency);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(s.addBill,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.billName,
                  hintText: 'e.g., Rent, Netflix, Electric',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.receipt_long_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.billAmount,
                  hintText: '0.00',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),
              // Account picker with Cash on Hand
              AppPickerField<String>(
                label: s.payFrom,
                value: _selectedAccountId ?? AppProvider.cashOnHandId,
                prefixIcon: AppIcons.wallet,
                items: [
                  AppPickerItem(
                    value: AppProvider.cashOnHandId,
                    label: 'Cash on Hand',
                    subtitle: cf.format(provider.totalCash),
                    leadingIcon: AppIcons.money,
                    iconColor: AppTheme.warning,
                  ),
                  ...provider.accounts.map((a) => AppPickerItem(
                        value: a.id,
                        label: a.name,
                        subtitle: cf.format(a.balance),
                        leadingIcon: _accountIcon(a.type),
                        iconColor: AppTheme.brandPrimary,
                      )),
                ],
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: 24),
              Text(s.frequency,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  {'key': 'daily', 'label': s.daily},
                  {'key': 'weekly', 'label': s.weekly},
                  {'key': 'monthly', 'label': s.monthly},
                  {'key': 'yearly', 'label': s.yearly},
                ].map((f) {
                  final isSelected = _selectedFrequency == f['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFrequency = f['key']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.brandPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected
                                  ? AppTheme.brandPrimary
                                  : Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: Text(
                            f['label']!,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: _nextDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) setState(() => _nextDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.borderedCard(context),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nextDueDate,
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(DateFormat('MMM d, yyyy').format(_nextDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ]),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 20,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveBill,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  child: Text(s.addBill,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _accountIcon(String type) {
    switch (type) {
      case 'bank':
        return AppIcons.bank;
      case 'savings':
        return AppIcons.savings;
      case 'investment':
        return AppIcons.trendUp;
      case 'debt':
        return AppIcons.creditCard;
      default:
        return AppIcons.wallet;
    }
  }

  void _saveBill() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.pleaseEnterName)));
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.pleaseEnterAmount)));
      return;
    }
    final accountId = _selectedAccountId ?? AppProvider.cashOnHandId;
    final transaction = Transaction(
      id: const Uuid().v4(),
      type: 'expense',
      amount: amount,
      date: _nextDate.toIso8601String(),
      note: _nameController.text,
      accountId: accountId,
    );
    final bill = RecurringRule(
      id: const Uuid().v4(),
      templateTransaction: transaction,
      frequency: _selectedFrequency,
      nextDate: _nextDate.toIso8601String(),
      isActive: true,
    );
    widget.provider.addRecurringRule(bill);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(s.billAdded.replaceAll('{name}', _nameController.text)),
          backgroundColor: AppTheme.brandPrimary),
    );
  }
}

// ─── Press Scale Feedback ────────────────────────────────────────────────────
// Wraps any widget with Emil-style scale(0.97) press feedback.
// Uses AnimatedScale for hardware-accelerated, interruptible animation.
class _PressScaleDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScaleDetector({required this.child, required this.onTap});

  @override
  State<_PressScaleDetector> createState() => _PressScaleDetectorState();
}

class _PressScaleDetectorState extends State<_PressScaleDetector> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
