import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'utils/currency_helper.dart';
import 'package:uuid/uuid.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'models/transaction.dart';
import 'models/recurring_rule.dart';
import 'screens/today_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/wealth_screen.dart';
import 'screens/coach_screen.dart';
import 'widgets/add_transaction_modal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'SafeSpend',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainScreen(),
        );
      },
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const BudgetsScreen(),
    const WealthScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
    if (_isMenuOpen) {
      _menuAnimController.forward();
    } else {
      _menuAnimController.reverse();
    }
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
      _menuAnimController.reverse();
    }
  }

  void _openTransactionModal(String type) {
    _closeMenu();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _screens,
            ),

            // Scrim overlay when menu is open
            if (_isMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: AnimatedBuilder(
                    animation: _menuAnimation,
                    builder: (context, child) => Container(
                      color: Colors.black.withOpacity(0.4 * _menuAnimation.value),
                    ),
                  ),
                ),
              ),

            // Floating AI Coach Button (bottom-left)
            Positioned(
              left: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: () {
                  _closeMenu();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachScreen()));
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.gold400, AppTheme.gold600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.goldGlow,
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                ),
              ),
            ),

            // Speed Dial Menu Items (above + button)
            Positioned(
              right: 20,
              bottom: 84,
              child: AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, child) => Opacity(
                  opacity: _menuAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _menuAnimation.value)),
                    child: IgnorePointer(
                      ignoring: !_isMenuOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSpeedDialItem('Add Expense', Icons.receipt_long_rounded, const Color(0xFFEF4444), () => _openAddBillModal()),
                          const SizedBox(height: 10),
                          _buildSpeedDialItem('Add Income', Icons.arrow_downward_rounded, AppTheme.success, () => _openTransactionModal('income')),
                          const SizedBox(height: 10),
                          _buildSpeedDialItem('Withdrawal', Icons.account_balance_wallet_rounded, AppTheme.warning, () => _openTransactionModal('withdrawal')),
                          const SizedBox(height: 10),
                          _buildSpeedDialItem('Transfer', Icons.swap_horiz_rounded, AppTheme.info, () => _openTransactionModal('transfer')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating + Button (bottom-right) — toggles speed dial
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: _toggleMenu,
                child: AnimatedBuilder(
                  animation: _menuAnimation,
                  builder: (context, child) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.gold500,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.goldGlow,
                    ),
                    child: Transform.rotate(
                      angle: _menuAnimation.value * 0.785, // 45 degrees
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.pie_chart_rounded, 'Budgets'),
                  _buildNavItem(2, Icons.trending_up_rounded, 'Wealth'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.goldPrimary.withOpacity(isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppTheme.goldPrimary
                  : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDialItem(String label, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.lightTextPrimary)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
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
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedFrequency = 'monthly';
  DateTime _nextDate = DateTime.now();
  String? _selectedAccountId;

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
      _selectedAccountId = provider.accounts.isNotEmpty ? provider.accounts.first.id : AppProvider.cashOnHandId;
    }
    final cf = CurrencyHelper.formatter(provider.settings.currency);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Add Bill', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Bill Name',
                  hintText: 'e.g., Rent, Netflix, Electric',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.receipt_long_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),
              // Account picker with Cash on Hand
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Pay From',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                ),
                items: [
                  DropdownMenuItem(
                    value: AppProvider.cashOnHandId,
                    child: Row(children: [
                      const Icon(Icons.payments_rounded, size: 18, color: AppTheme.warning),
                      const SizedBox(width: 8),
                      const Text('Cash on Hand'),
                      const Spacer(),
                      Text(cf.format(provider.totalCash), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ]),
                  ),
                  ...provider.accounts.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(children: [
                      Icon(_accountIcon(a.type), size: 18, color: AppTheme.goldPrimary),
                      const SizedBox(width: 8),
                      Text(a.name),
                      const Spacer(),
                      Text(cf.format(a.balance), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ]),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: 24),
              Text('Frequency', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: ['daily', 'weekly', 'monthly', 'yearly'].map((f) {
                  final isSelected = _selectedFrequency == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFrequency = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppTheme.goldPrimary : Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color),
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
                  final date = await showDatePicker(context: context, initialDate: _nextDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) setState(() => _nextDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.borderedCard(context),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Next Due Date', style: Theme.of(context).textTheme.bodySmall),
                        Text(DateFormat('MMM d, yyyy').format(_nextDate), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saveBill,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: const Text('Add Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'bank': return Icons.account_balance_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'investment': return Icons.trending_up_rounded;
      case 'debt': return Icons.credit_card_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  void _saveBill() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a bill name')));
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
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
      SnackBar(content: Text('Bill "${_nameController.text}" added'), backgroundColor: AppTheme.goldPrimary),
    );
  }
}
