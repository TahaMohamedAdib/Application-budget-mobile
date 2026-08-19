import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/app_localizations.dart';
import '../../models/account.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../utils/currency_helper.dart';
import '../../widgets/onboarding_ui.dart';

/// The first-run questionnaire: currency, first account, balance, and pay.
///
/// Five short steps rather than three crowded ones. The ordering is load
/// bearing:
///
/// 1. **Currency first.** Every later step shows amounts, and showing them
///    against the wrong symbol while the user types is the sort of detail that
///    costs trust on the very first screen.
/// 2. **Account, then balance.** Two questions about the same account, split so
///    neither screen asks for more than it needs to.
/// 3. **Pay last, and skippable.** It is the most personal question, so it is
///    asked once the user has already invested a few taps — and never blocks
///    finishing.
/// 4. **A summary.** The user sees exactly what is about to be created before
///    anything is written.
///
/// What the answers drive:
///
/// * `Settings.currency` and `Settings.monthlyIncome` — the latter feeds
///   safe-to-spend, and was previously never written at all, leaving every new
///   user's budget stuck at zero.
/// * `Account.salaryAmount` / `salaryFrequency` / `salaryDay` /
///   `salaryAnchorDate` — the pay cycle the auto-credit engine walks.
class SetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const SetupScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

/// Steps, in order. Named so the page logic reads as intent rather than index
/// arithmetic.
enum _Step { currency, account, balance, income, summary }

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  _Step _step = _Step.currency;

  // Currency
  String _currency = 'USD';
  final _currencySearchController = TextEditingController();
  String _currencyQuery = '';

  // Account
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  String? _logoPath;
  String? _nameError;

  // Balance
  final _balanceController = TextEditingController();
  String? _balanceError;

  // Income
  final _wageController = TextEditingController();
  String _payFrequency = 'monthly';

  /// Day of month (1–31) when monthly; ISO weekday (1–7) otherwise.
  int _payDay = 1;
  bool _incomeSkipped = false;
  String? _wageError;

  bool _isSaving = false;

  static const _commonCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'MAD',
    'AED',
    'CAD',
    'AUD',
    'CHF',
    'JPY',
    'INR',
  ];

  @override
  void initState() {
    super.initState();
    // Seed from whatever the app already knows, so returning to onboarding
    // after a partial run does not reset the user's choice.
    final settings = context.read<AppProvider>().settings;
    _currency = settings.currency;
    _currencySearchController.addListener(
      () => setState(() => _currencyQuery = _currencySearchController.text),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currencySearchController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goTo(_Step step) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      step.index,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (!_validateCurrentStep()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.selectionClick();
    if (_step == _Step.summary) {
      _finish();
    } else {
      _goTo(_Step.values[_step.index + 1]);
    }
  }

  void _back() {
    if (_step == _Step.currency) {
      widget.onBack();
    } else {
      _goTo(_Step.values[_step.index - 1]);
    }
  }

  /// Validates only the step being left, and reports inline rather than in a
  /// snackbar so the message sits next to the field it is about.
  bool _validateCurrentStep() {
    final s = S.of(context);
    switch (_step) {
      case _Step.account:
        final empty = _accountNameController.text.trim().isEmpty;
        setState(() => _nameError = empty ? s.obErrorNameRequired : null);
        return !empty;
      case _Step.balance:
        final text = _balanceController.text.trim();
        if (text.isEmpty) {
          setState(() => _balanceError = s.obErrorBalanceRequired);
          return false;
        }
        final value = _parseAmount(text);
        if (value == null) {
          setState(() => _balanceError = s.obErrorNotANumber);
          return false;
        }
        if (value < 0) {
          setState(() => _balanceError = s.obErrorNegativeBalance);
          return false;
        }
        setState(() => _balanceError = null);
        return true;
      case _Step.income:
        if (_incomeSkipped || _wageController.text.trim().isEmpty) return true;
        final value = _parseAmount(_wageController.text);
        if (value == null) {
          setState(() => _wageError = s.obErrorNotANumber);
          return false;
        }
        if (value <= 0) {
          setState(() => _wageError = s.obErrorWagePositive);
          return false;
        }
        setState(() => _wageError = null);
        return true;
      case _Step.currency:
      case _Step.summary:
        return true;
    }
  }

  /// Tolerates both decimal conventions. `1.234,56` and `1,234.56` are the same
  /// number to a user, and which one they type depends on their keyboard, not
  /// on the app's locale setting.
  static double? _parseAmount(String raw) {
    var text = raw.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      // Whichever separator comes last is the decimal point.
      text = lastComma > lastDot
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (lastComma >= 0) {
      // A lone comma is a decimal point unless it groups thousands (1,234).
      final decimals = text.length - lastComma - 1;
      text = decimals == 3 && text.indexOf(',') != lastComma
          ? text.replaceAll(',', '')
          : text.replaceAll(',', '.');
    }
    return double.tryParse(text);
  }

  // ── Derived values ─────────────────────────────────────────────────────────

  double? get _wage =>
      _incomeSkipped ? null : _parseAmount(_wageController.text);

  /// The account exactly as it will be saved. Built in one place so the summary
  /// and the write can never drift apart.
  Account _buildAccount() {
    final wage = _wage;
    final hasWage = wage != null && wage > 0;
    final now = DateTime.now();

    return Account(
      id: const Uuid().v4(),
      name: _accountNameController.text.trim(),
      type: 'bank',
      balance: _parseAmount(_balanceController.text) ?? 0,
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      imagePath: _logoPath,
      addedAt: now.toIso8601String(),
      salaryAmount: hasWage ? wage : null,
      salaryFrequency: hasWage ? _payFrequency : null,
      salaryDay: hasWage ? _payDay : null,
      // Anchor a fortnightly cycle to today so it stays on the same fortnight
      // on every device. Irrelevant for the other frequencies.
      salaryAnchorDate: hasWage && _payFrequency == 'biweekly'
          ? now.toIso8601String().substring(0, 10)
          : null,
      includeInNetWorth: true,
    );
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = context.read<AppProvider>();
    final account = _buildAccount();

    provider.updateSettings(
      provider.settings.copyWith(
        currency: _currency,
        // Previously left at zero, which pinned safe-to-spend to zero for every
        // new user. The account holds one pay packet; settings holds the
        // per-month figure the budget maths expects.
        monthlyIncome: account.monthlySalaryEquivalent,
      ),
    );
    provider.addAccount(account);

    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null && mounted) setState(() => _logoPath = file.path);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OnboardingScaffold(
      onBack: _back,
      step: _step.index,
      stepCount: _Step.values.length,
      scrollable: false,
      trailing: _step == _Step.income
          ? OnboardingTextButton(
              label: s.obSetupSkip,
              onTap: () {
                setState(() {
                  _incomeSkipped = true;
                  _wageController.clear();
                  _wageError = null;
                });
                _goTo(_Step.summary);
              },
            )
          : null,
      footer: OnboardingButton(
        label: _step == _Step.summary ? s.obFinish : s.next,
        icon: _step == _Step.summary ? null : IOSIcons.arrow_forward_rounded,
        busy: _isSaving,
        onTap: _next,
      ),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _step = _Step.values[i]),
        children: [
          _stepBody(_buildCurrencyStep(s)),
          _stepBody(_buildAccountStep(s)),
          _stepBody(_buildBalanceStep(s)),
          _stepBody(_buildIncomeStep(s)),
          _stepBody(_buildSummaryStep(s)),
        ],
      ),
    );
  }

  /// Each step scrolls independently so a keyboard can never trap a field.
  Widget _stepBody(Widget child) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 14, bottom: 28),
        child: child,
      );

  // ── Step 1: currency ───────────────────────────────────────────────────────

  Widget _buildCurrencyStep(S s) {
    final query = _currencyQuery.trim().toLowerCase();
    final all = CurrencyHelper.currencies.entries.toList();

    final matches = query.isEmpty
        ? null
        : all
            .where((e) =>
                e.key.toLowerCase().contains(query) ||
                (e.value['name'] ?? '').toLowerCase().contains(query))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingHero(
          icon: IOSIcons.money_rounded,
          title: s.obCurrencyTitle,
          subtitle: s.obCurrencySubtitle,
        ),
        const SizedBox(height: 22),
        OnboardingSearchField(
          controller: _currencySearchController,
          hint: s.obCurrencySearch,
        ),
        const SizedBox(height: 18),
        if (matches == null) ...[
          _sectionLabel(s.obCurrencyCommon),
          ..._commonCurrencies
              .where(CurrencyHelper.currencies.containsKey)
              .map(_currencyRow),
        ] else if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              s.obCurrencyNoResults,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          )
        else
          ...matches.take(40).map((e) => _currencyRow(e.key)),
      ],
    );
  }

  Widget _currencyRow(String code) {
    return OnboardingChoice(
      title: CurrencyHelper.getName(code),
      subtitle: code,
      selected: _currency == code,
      onTap: () => setState(() => _currency = code),
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: onboardingShape(14),
          color: AppTheme.adaptiveIconSurface(context),
        ),
        child: Text(
          CurrencyHelper.getSymbol(code),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.adaptiveIcon(context),
          ),
        ),
      ),
    );
  }

  // ── Step 2: account ────────────────────────────────────────────────────────

  Widget _buildAccountStep(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingHero(
          icon: IOSIcons.account_balance_rounded,
          title: s.obAccountTitle,
          subtitle: s.obAccountSubtitle,
        ),
        const SizedBox(height: 26),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: ShapeDecoration(
                    shape: onboardingShape(
                      26,
                      side: _logoPath == null
                          ? AppTheme.adaptiveIcon(context, alpha: 0.22)
                          : Colors.transparent,
                    ),
                    color: AppTheme.adaptiveIconSurface(context),
                    image: _logoPath == null
                        ? null
                        : DecorationImage(
                            image: FileImage(File(_logoPath!)),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: _logoPath != null
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IOSIcons.add_a_photo_rounded,
                              size: 24,
                              color: AppTheme.adaptiveIcon(context),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.obLogoAdd,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.obLogoHint,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        OnboardingField(
          controller: _accountNameController,
          label: s.obAccountNameLabel,
          hint: s.obAccountNameHint,
          icon: IOSIcons.credit_card_rounded,
          error: _nameError,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 18),
        OnboardingField(
          controller: _bankNameController,
          label: s.obBankLabel,
          hint: s.obBankHint,
          icon: IOSIcons.account_balance_rounded,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }

  // ── Step 3: balance ────────────────────────────────────────────────────────

  Widget _buildBalanceStep(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingHero(
          icon: IOSIcons.account_balance_wallet_rounded,
          title: s.obBalanceTitle,
          subtitle: s.obBalanceSubtitle,
        ),
        const SizedBox(height: 26),
        OnboardingField(
          controller: _balanceController,
          label: s.obBalanceLabel,
          hint: '0',
          prefix: CurrencyHelper.getSymbol(_currency),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,\s]')),
          ],
          textCapitalization: TextCapitalization.none,
          error: _balanceError,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_balanceError != null) setState(() => _balanceError = null);
            setState(() {});
          },
          onSubmitted: (_) => _next(),
        ),
        const SizedBox(height: 14),
        // Echoing the parsed figure back is the cheapest way to catch a
        // mistyped separator before it becomes the opening balance.
        _amountEcho(_parseAmount(_balanceController.text)),
      ],
    );
  }

  Widget _amountEcho(double? value) {
    if (value == null) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          IOSIcons.check_circle_rounded,
          size: 15,
          color: AppTheme.adaptiveIcon(context, alpha: 0.7),
        ),
        const SizedBox(width: 7),
        Text(
          CurrencyHelper.formatter(_currency).format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  // ── Step 4: income ─────────────────────────────────────────────────────────

  Widget _buildIncomeStep(S s) {
    final wage = _parseAmount(_wageController.text);
    final hasWage = wage != null && wage > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingHero(
          icon: IOSIcons.payments_rounded,
          title: s.obIncomeTitle,
          subtitle: s.obIncomeSubtitle,
        ),
        const SizedBox(height: 26),
        OnboardingField(
          controller: _wageController,
          label: s.obWageLabel,
          hint: s.obWageHint,
          prefix: CurrencyHelper.getSymbol(_currency),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,\s]')),
          ],
          textCapitalization: TextCapitalization.none,
          error: _wageError,
          onChanged: (_) => setState(() {
            _wageError = null;
            _incomeSkipped = false;
          }),
        ),
        const SizedBox(height: 22),
        _sectionLabel(s.obFrequencyLabel),
        OnboardingSegmented<String>(
          value: _payFrequency,
          segments: {
            'weekly': s.obPayWeekly,
            'biweekly': s.obPayBiweekly,
            'monthly': s.obPayMonthly,
          },
          onChanged: (value) => setState(() {
            _payFrequency = value;
            // The two schemes number different things — a day of month cannot
            // carry over to a weekday — so reset to a sane default.
            _payDay = value == 'monthly' ? 1 : DateTime.friday;
          }),
        ),
        const SizedBox(height: 22),
        _sectionLabel(s.obPayDayLabel),
        _payDayPicker(s),
        if (hasWage) ...[
          const SizedBox(height: 20),
          _incomeSummary(s, wage),
        ],
      ],
    );
  }

  Widget _payDayPicker(S s) {
    final monthly = _payFrequency == 'monthly';
    final label = monthly
        ? (_payDay == 31 ? s.obPayDayLastDay : s.obPayDayOfMonth(_payDay))
        : s.obPayEveryWeekday(_weekdayName(_payDay));

    return OnboardingGlass(
      radius: 20,
      onTap: () => _showPayDaySheet(s),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          Icon(
            IOSIcons.calendar_today_rounded,
            size: 19,
            color: AppTheme.adaptiveIcon(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ),
          Icon(
            IOSIcons.chevron_right_rounded,
            size: 18,
            color: AppTheme.adaptiveIcon(context, alpha: 0.6),
          ),
        ],
      ),
    );
  }

  /// Weekday name in the user's own language, taken from the active locale
  /// rather than a hardcoded English list.
  String _weekdayName(int isoWeekday) {
    // 2024-01-01 was a Monday, so adding (weekday - 1) days lands on the
    // right day whatever the value.
    final date = DateTime(2024, 1, isoWeekday.clamp(1, 7));
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.EEEE(locale).format(date);
  }

  void _showPayDaySheet(S s) {
    final monthly = _payFrequency == 'monthly';
    final options = monthly
        ? List.generate(31, (i) => i + 1)
        : List.generate(7, (i) => i + 1);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.62,
            ),
            child: OnboardingGlass(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: AppTheme.adaptiveIcon(context, alpha: 0.25),
                    ),
                  ),
                  Text(
                    s.obPayDayLabel,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: options.length,
                      itemBuilder: (_, i) {
                        final value = options[i];
                        return OnboardingChoice(
                          title: monthly
                              ? (value == 31
                                  ? s.obPayDayLastDay
                                  : s.obPayDayOfMonth(value))
                              : _weekdayName(value),
                          selected: _payDay == value,
                          onTap: () {
                            setState(() => _payDay = value);
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Restates the wage as a monthly figure and names the next pay date.
  ///
  /// A weekly earner rarely knows their monthly income offhand, and it is the
  /// number every budget in the app is built on — so it is shown before they
  /// commit to it rather than buried in Settings afterwards.
  Widget _incomeSummary(S s, double wage) {
    final preview = Account(
      id: 'preview',
      name: '',
      type: 'bank',
      balance: 0,
      salaryAmount: wage,
      salaryFrequency: _payFrequency,
      salaryDay: _payDay,
      salaryAnchorDate: DateTime.now().toIso8601String().substring(0, 10),
    );

    final now = DateTime.now();
    final upcoming = preview.payDatesBetween(
      now,
      DateTime(now.year, now.month + 2, now.day),
    );
    final locale = Localizations.localeOf(context).languageCode;

    return OnboardingGlass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IOSIcons.trending_up_rounded,
                size: 18,
                color: AppTheme.adaptiveIcon(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.obMonthlyEquivalent(
                    CurrencyHelper.formatter(_currency)
                        .format(preview.monthlySalaryEquivalent),
                  ),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                s.obNextPayday(
                  DateFormat.MMMMEEEEd(locale).format(upcoming.first),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 5: summary ────────────────────────────────────────────────────────

  Widget _buildSummaryStep(S s) {
    final account = _buildAccount();
    final formatter = CurrencyHelper.formatter(_currency);
    final income = account.monthlySalaryEquivalent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingHero(
          icon: IOSIcons.check_circle_rounded,
          title: s.obSummaryTitle,
          subtitle: s.obSummarySubtitle,
        ),
        const SizedBox(height: 26),
        _summaryRow(
          s.obSummaryAccount,
          [account.name, account.bankName].whereType<String>().join(' · '),
          IOSIcons.account_balance_rounded,
          _Step.account,
          s,
        ),
        _summaryRow(
          s.obSummaryBalance,
          formatter.format(account.balance),
          IOSIcons.account_balance_wallet_rounded,
          _Step.balance,
          s,
        ),
        _summaryRow(
          s.obSummaryIncome,
          income > 0 ? formatter.format(income) : s.obSummaryIncomeNone,
          IOSIcons.payments_rounded,
          _Step.income,
          s,
        ),
        if (income <= 0) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              s.obIncomeSkipNote,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    IconData icon,
    _Step target,
    S s,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnboardingGlass(
        radius: 20,
        onTap: () => _goTo(target),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: ShapeDecoration(
                shape: onboardingShape(14),
                color: AppTheme.adaptiveIconSurface(context),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.adaptiveIcon(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value.isEmpty ? '—' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              s.obSummaryEdit,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.goldPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );
}
