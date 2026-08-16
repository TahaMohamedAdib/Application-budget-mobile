import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
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

Color _alpha(Color color, double value) => color.withValues(alpha: value);

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
            Icon(IOSIcons.account_balance_wallet_rounded,
                size: 64, color: AppTheme.adaptiveIcon(context)),
            const SizedBox(height: 16),
            Text('SafeSpend',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.goldPrimary)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.goldPrimary),
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

  /// Gap between the screen bottom and the floating nav pill. iOS parks its
  /// own tab bar *inside* the home-indicator inset rather than above it, so we
  /// do the same instead of clearing the full safe area.
  double get _navBarBottomInset {
    final inset = MediaQuery.of(context).padding.bottom;
    if (inset == 0) return 12;
    // The iOS home indicator and Android gesture bar are thin lines the pill
    // can sit over. Android 3-button navigation is a real strip of tappable
    // buttons, so clear it rather than hiding the pill behind them.
    if (defaultTargetPlatform == TargetPlatform.android && inset > 32) {
      return inset;
    }
    return 24;
  }

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

    // Load user data from Supabase on mount (only if not already loaded this session)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (auth.isAuthenticated &&
          auth.userId != null &&
          !appProvider.supabaseDataLoaded) {
        appProvider.loadFromSupabase(auth.userId!);
      }
    });

    // Check every minute for subscriptions that have become due
    _subscriptionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      Provider.of<AppProvider>(context, listen: false).processSubscriptions();
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
    final navInset = _navBarBottomInset;

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
          // Shown on every tab, matching iOS.
            AnimatedBuilder(
              animation: _menuAnimation,
              builder: (_, __) {
                if (_menuAnimation.value == 0) return const SizedBox.shrink();
                return Positioned(
                  // 22 above the pill's top edge (pill is 66 tall).
                  bottom: navInset + 88,
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
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel(bool isDark) {
    final actions = [
      (
        'Expense',
        IOSIcons.arrow_upward_rounded,
        AppTheme.expenseIcon,
        'expense'
      ),
      (
        'Income',
        IOSIcons.arrow_downward_rounded,
        AppTheme.incomeIcon,
        'income'
      ),
      (
        'Withdraw',
        IOSIcons.account_balance_wallet_rounded,
        AppTheme.withdrawalIcon,
        'withdrawal'
      ),
      (
        'Transfer',
        IOSIcons.swap_horiz_rounded,
        AppTheme.transferIcon,
        'transfer'
      ),
    ];

    return _buildIOSGlassQuickActionsPanel(isDark, actions);
  }

  Widget _buildIOSGlassQuickActionsPanel(
    bool isDark,
    List<(String, IconData, Color, String)> actions,
  ) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _alpha(Colors.black, isDark ? 0.50 : 0.16),
              blurRadius: 34,
              spreadRadius: -8,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              width: 254,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? _alpha(const Color(0xFF242427), 0.72)
                    : _alpha(Colors.white, 0.58),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? _alpha(Colors.white, 0.12)
                      : _alpha(Colors.white, 0.74),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          _alpha(Colors.white, 0.10),
                          _alpha(Colors.white, 0.04),
                          _alpha(Colors.black, 0.14),
                        ]
                      : [
                          _alpha(Colors.white, 0.82),
                          _alpha(Colors.white, 0.42),
                          _alpha(Colors.white, 0.24),
                        ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(actions.length, (i) {
                  final (label, icon, color, type) = actions[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == actions.length - 1 ? 0 : 6,
                    ),
                    child: _IOSQuickActionRow(
                      label: label,
                      icon: icon,
                      color: color,
                      isDark: isDark,
                      onTap: () {
                        _closeMenu();
                        _openTransactionModal(type);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillNavBar(bool isDark) {
    // The glass bar is the app's nav bar on every platform — Android included.
    return _buildIOSGlassNavBar(isDark);
  }

  Widget _buildIOSGlassNavBar(bool isDark) {
    final activeColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final inactiveColor =
        isDark ? _alpha(Colors.white, 0.66) : const Color(0xFF777B81);
    final borderColor =
        isDark ? _alpha(Colors.white, 0.14) : const Color(0xFFD9DCE0);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 14, _navBarBottomInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: _alpha(Colors.black, isDark ? 0.46 : 0.10),
                  blurRadius: 28,
                  spreadRadius: -7,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : null,
                    gradient: isDark
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF3F4F5),
                              Color(0xFFE9EBED),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: borderColor),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / 5;
                      final indicatorWidth =
                          (itemWidth - 8).clamp(58.0, 78.0).toDouble();
                      const indicatorHeight = 52.0;
                      final selectedCell = switch (_selectedIndex) {
                        0 => 0,
                        1 => 1,
                        2 => 3,
                        _ => 4,
                      };
                      final itemLeft = switch (selectedCell) {
                        0 => 0.0,
                        1 => itemWidth,
                        2 => itemWidth * 2,
                        3 => itemWidth * 3,
                        _ => itemWidth * 4,
                      };

                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            top: 7,
                            left: itemLeft + ((itemWidth - indicatorWidth) / 2),
                            width: indicatorWidth,
                            height: indicatorHeight,
                            child: _IOSGlassSelection(isDark: isDark),
                          ),
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildIOSGlassNavItem(0, AppIcons.home,
                                    activeColor, inactiveColor),
                                _buildIOSGlassNavItem(1, AppIcons.aiCoach,
                                    activeColor, inactiveColor),
                                _buildIOSGlassAddItem(isDark),
                                _buildIOSGlassNavItem(2, AppIcons.budgets,
                                    activeColor, inactiveColor),
                                _buildIOSGlassNavItem(3, AppIcons.wealth,
                                    activeColor, inactiveColor),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSGlassNavItem(
      int index, String icon, Color activeColor, Color inactiveColor) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: _PressScaleDetector(
        onTap: () => _onTabTapped(index),
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.05 : 1,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Iconify(
              icon,
              size: 23,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSGlassAddItem(bool isDark) {
    return Expanded(
      child: _PressScaleDetector(
        onTap: _toggleMenu,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _alpha(AppTheme.success, isDark ? 0.32 : 0.26),
                  blurRadius: 16,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF168A74)),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: _isMenuOpen ? 0.125 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: const Iconify(
                        AppIcons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IOSGlassSelection extends StatelessWidget {
  final bool isDark;
  const _IOSGlassSelection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? _alpha(Colors.white, 0.17)
                  : _alpha(Colors.white, 0.92),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      _alpha(Colors.white, 0.25),
                      _alpha(Colors.white, 0.16),
                      _alpha(Colors.white, 0.11),
                    ]
                  : [
                      _alpha(Colors.white, 0.94),
                      _alpha(Colors.white, 0.68),
                      _alpha(Colors.white, 0.48),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: _alpha(Colors.black, isDark ? 0.30 : 0.24),
                blurRadius: 14,
                spreadRadius: -5,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: _alpha(Colors.white, isDark ? 0.08 : 0.13),
                blurRadius: 7,
                spreadRadius: -4,
                offset: const Offset(-1, -2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IOSQuickActionRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _IOSQuickActionRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_IOSQuickActionRow> createState() => _IOSQuickActionRowState();
}

class _IOSQuickActionRowState extends State<_IOSQuickActionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1C1C1E);
    final rowBg = widget.isDark
        ? _alpha(Colors.white, _pressed ? 0.12 : 0.055)
        : _alpha(Colors.white, _pressed ? 0.72 : 0.44);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark
                  ? _alpha(Colors.white, 0.06)
                  : _alpha(Colors.white, 0.48),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveIconSurface(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
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
                  prefixIcon: Icon(IOSIcons.receipt_long_rounded,
                      color: AppTheme.adaptiveIcon(context)),
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
                  prefixIcon: Icon(IOSIcons.attach_money_rounded,
                      color: AppTheme.adaptiveIcon(context)),
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
                    iconColor: AppTheme.cashOnHandIcon,
                  ),
                  ...provider.accounts.map((a) => AppPickerItem(
                        value: a.id,
                        label: a.name,
                        subtitle: cf.format(a.balance),
                        leadingIcon: _accountIcon(a.type),
                        iconColor: AppTheme.adaptiveIcon(context),
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
                              ? AppTheme.goldPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected
                                  ? AppTheme.goldPrimary
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
                      Icon(IOSIcons.calendar_today_rounded,
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
                      Icon(IOSIcons.chevron_right_rounded,
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
                      backgroundColor: AppTheme.goldPrimary,
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
          backgroundColor: AppTheme.goldPrimary),
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
