import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_helper.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const SetupScreen(
      {super.key, required this.onComplete, required this.onBack});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 — Account
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  String? _logoPath;

  // Step 2 — Balance & Currency
  final _balanceController = TextEditingController();
  String _currency = 'USD';

  // Step 3 — Salary
  final _salaryController = TextEditingController();
  String _payFrequency = 'monthly';
  int _payDay = 1;

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _accountNameController.text.trim().isEmpty) {
      _showError('Please enter an account name.');
      return;
    }
    if (_currentPage == 1 && _balanceController.text.trim().isEmpty) {
      _showError('Please enter your current balance.');
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _logoPath = file.path);
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Update currency in settings
    provider.updateSettings(provider.settings.copyWith(currency: _currency));

    // Create first account
    final balance =
        double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0;
    final salary = double.tryParse(_salaryController.text.replaceAll(',', ''));
    final account = Account(
      id: const Uuid().v4(),
      name: _accountNameController.text.trim(),
      type: 'bank',
      balance: balance,
      bankName: _bankNameController.text.trim().isNotEmpty
          ? _bankNameController.text.trim()
          : null,
      imagePath: _logoPath,
      salaryAmount: (salary != null && salary > 0) ? salary : null,
      salaryDay: (salary != null && salary > 0) ? _payDay : null,
      includeInNetWorth: true,
    );
    provider.addAccount(account);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back button + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _currentPage == 0
                        ? widget.onBack
                        : () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                      ),
                      child: const Icon(IOSIcons.arrow_back_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: List.generate(3, (i) {
                        final active = i <= _currentPage;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.goldPrimary
                                  : (isDark
                                      ? AppTheme.darkSurfaceElevated
                                      : AppTheme.lightBorder),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPage + 1}/3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextTertiary
                          : AppTheme.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildAccountPage(isDark),
                  _buildBalancePage(isDark),
                  _buildSalaryPage(isDark),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: GestureDetector(
                onTap: _currentPage < 2 ? _nextPage : _finish,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.goldGlow,
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _currentPage < 2 ? s.next : s.getStarted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Account ───────────────────────────────────────────────────────

  Widget _buildAccountPage(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            isDark,
            icon: IOSIcons.account_balance_rounded,
            title: 'Set Up Your Account',
            subtitle: "Let's add your main bank account to get started.",
          ),
          const SizedBox(height: 32),

          // Logo upload
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                  image: _logoPath != null
                      ? DecorationImage(
                          image: FileImage(File(_logoPath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: _logoPath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IOSIcons.add_a_photo_rounded,
                              size: 26, color: AppTheme.adaptiveIcon(context)),
                          const SizedBox(height: 6),
                          Text(
                            'Bank Logo',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.goldPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Optional — tap to upload',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextTertiary
                      : AppTheme.lightTextTertiary),
            ),
          ),
          const SizedBox(height: 24),

          _buildField(
            controller: _accountNameController,
            label: 'Account Name *',
            hint: 'e.g., Main Checking, HSBC Account',
            icon: IOSIcons.credit_card_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _bankNameController,
            label: 'Bank Name',
            hint: 'e.g., Chase, Barclays, CIH Bank',
            icon: IOSIcons.account_balance_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Balance & Currency ────────────────────────────────────────────

  Widget _buildBalancePage(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            isDark,
            icon: IOSIcons.account_balance_wallet_rounded,
            title: 'Balance & Currency',
            subtitle:
                'Enter your current balance and choose your preferred currency.',
          ),
          const SizedBox(height: 32),

          _buildField(
            controller: _balanceController,
            label: 'Current Balance *',
            hint: '0.00',
            icon: IOSIcons.attach_money_rounded,
            isDark: isDark,
            isNumeric: true,
          ),
          const SizedBox(height: 16),

          // Currency selector
          GestureDetector(
            onTap: () => _showCurrencyPicker(isDark),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.09)
                        : AppTheme.lightBorder),
                boxShadow: isDark ? [] : AppTheme.cardShadowLight,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        CurrencyHelper.getSymbol(_currency),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default Currency',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextTertiary
                                  : AppTheme.lightTextTertiary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_currency — ${CurrencyHelper.getName(_currency)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(IOSIcons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkTextTertiary
                          : AppTheme.lightTextTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Salary ────────────────────────────────────────────────────────

  Widget _buildSalaryPage(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            isDark,
            icon: IOSIcons.payments_rounded,
            title: 'Your Salary',
            subtitle:
                "Tell us how you get paid so we can auto-track your income.",
          ),
          const SizedBox(height: 32),
          _buildField(
            controller: _salaryController,
            label: 'Wage / Salary (${CurrencyHelper.getSymbol(_currency)})',
            hint: '0.00',
            icon: IOSIcons.attach_money_rounded,
            isDark: isDark,
            isNumeric: true,
          ),
          const SizedBox(height: 24),
          Text(
            'How do you get paid?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFrequencyChip('weekly', 'Weekly', isDark),
              const SizedBox(width: 10),
              _buildFrequencyChip('biweekly', 'Bi-weekly', isDark),
              const SizedBox(width: 10),
              _buildFrequencyChip('monthly', 'Monthly', isDark),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _payFrequency == 'monthly'
                ? 'Pay Day (day of month)'
                : 'Pay Day (day of week)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _payFrequency == 'monthly'
              ? _buildMonthDayPicker(isDark)
              : _buildWeekDayPicker(isDark),
          const SizedBox(height: 16),
          Text(
            'You can skip this and configure it later in Settings.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextTertiary
                  : AppTheme.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(String value, String label, bool isDark) {
    final isSelected = _payFrequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _payFrequency = value;
          _payDay = value == 'monthly' ? 1 : 0;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? AppTheme.goldPrimary
                    : (isDark
                        ? Colors.white.withOpacity(0.09)
                        : AppTheme.lightBorder)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthDayPicker(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.09) : AppTheme.lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _payDay,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          items: List.generate(31, (i) => i + 1).map((day) {
            final suffix = day == 1
                ? 'st'
                : day == 2
                    ? 'nd'
                    : day == 3
                        ? 'rd'
                        : 'th';
            return DropdownMenuItem(
              value: day,
              child: Text(
                '$day$suffix of each month',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _payDay = v ?? 1),
        ),
      ),
    );
  }

  Widget _buildWeekDayPicker(bool isDark) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.09) : AppTheme.lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _payDay.clamp(0, 6),
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          items: List.generate(
              7,
              (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      'Every ${days[i]}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  )),
          onChanged: (v) => setState(() => _payDay = v ?? 0),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildStepHeader(bool isDark,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.adaptiveIconSurface(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 28, color: AppTheme.adaptiveIcon(context)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
          : null,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.adaptiveIcon(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.09)
                  : AppTheme.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      ),
    );
  }

  void _showCurrencyPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(
        currentCurrency: _currency,
        onSelect: (code) {
          setState(() => _currency = code);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Currency Picker Bottom Sheet ──────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onSelect;
  const _CurrencyPickerSheet(
      {required this.currentCurrency, required this.onSelect});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _sections = {
    'Popular': ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY'],
    'Americas': [
      'BRL',
      'MXN',
      'ARS',
      'CLP',
      'COP',
      'PEN',
      'UYU',
      'DOP',
      'JMD',
      'TTD',
      'NZD'
    ],
    'Europe': [
      'SEK',
      'NOK',
      'DKK',
      'PLN',
      'CZK',
      'HUF',
      'RON',
      'BGN',
      'HRK',
      'ISK',
      'RUB',
      'UAH',
      'TRY',
      'GEL'
    ],
    'Asia & Pacific': [
      'INR',
      'PKR',
      'BDT',
      'LKR',
      'NPR',
      'KRW',
      'HKD',
      'SGD',
      'TWD',
      'THB',
      'VND',
      'MYR',
      'IDR',
      'PHP',
      'MMK',
      'KHR'
    ],
    'Middle East': [
      'AED',
      'SAR',
      'QAR',
      'KWD',
      'BHD',
      'OMR',
      'JOD',
      'ILS',
      'EGP',
      'LBP',
      'IQD',
      'IRR'
    ],
    'Africa': [
      'ZAR',
      'NGN',
      'KES',
      'GHS',
      'TZS',
      'UGX',
      'ETB',
      'MAD',
      'TND',
      'DZD',
      'XOF',
      'XAF',
      'RWF'
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                Center(
                    child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(s.selectCurrency,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(IOSIcons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: s.searchCurrency,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(IOSIcons.search_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 38, minHeight: 38),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(IOSIcons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            })
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurfaceElevated
                        : AppTheme.lightBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              children: _buildSections(isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(bool isDark) {
    final widgets = <Widget>[];
    final s = S.of(context);
    for (final entry in _sections.entries) {
      final codes = entry.value.where((code) {
        if (_query.isEmpty) return true;
        final name = CurrencyHelper.getName(code).toLowerCase();
        final symbol = CurrencyHelper.getSymbol(code).toLowerCase();
        return code.toLowerCase().contains(_query) ||
            name.contains(_query) ||
            symbol.contains(_query);
      }).toList();
      if (codes.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(entry.key,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ));

      widgets.add(Container(
        decoration: AppTheme.premiumCard(context),
        child: Column(
          children: codes.asMap().entries.map((e) {
            final code = e.value;
            final isLast = e.key == codes.length - 1;
            final isSelected = code == widget.currentCurrency;
            final symbol = CurrencyHelper.getSymbol(code);
            final name = CurrencyHelper.getName(code);
            return Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSelect(code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.goldPrimary.withOpacity(0.12)
                                : (isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(symbol,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.goldPrimary
                                        : (isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.lightTextPrimary))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(code,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.goldPrimary
                                          : (isDark
                                              ? AppTheme.darkTextPrimary
                                              : AppTheme.lightTextPrimary))),
                              Text(name,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppTheme.darkTextTertiary
                                          : AppTheme.lightTextTertiary)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(IOSIcons.check_circle_rounded,
                              size: 20, color: AppTheme.adaptiveIcon(context)),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      indent: 66,
                      color: isDark
                          ? Colors.white.withOpacity(0.09)
                          : AppTheme.lightBorder),
              ],
            );
          }).toList(),
        ),
      ));
    }
    if (widgets.isEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
            child: Text(s.noCurrenciesFound,
                style: Theme.of(context).textTheme.bodySmall)),
      ));
    }
    return widgets;
  }
}
