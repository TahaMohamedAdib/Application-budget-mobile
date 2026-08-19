import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/account.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../utils/money_format.dart';
import '../../widgets/settings_ui.dart';

/// Edit the pay schedule set during onboarding.
///
/// Until now the wage could only be entered once, on the first run, and never
/// corrected — a raise, a new job or a simple typo left safe-to-spend wrong
/// with nowhere to fix it.
///
/// Everything is saved through [AppProvider.setAccountSalary] so the schedule
/// on the account and `settings.monthlyIncome` can never disagree.
class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _amountController = TextEditingController();

  String? _accountId;
  String _frequency = 'monthly';
  int _payDay = 1;
  bool _loaded = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Seeds the form from whichever account already carries a salary, falling
  /// back to the first account so a user who skipped the question during
  /// onboarding still lands somewhere sensible.
  void _seed(AppProvider provider) {
    if (_loaded || provider.accounts.isEmpty) return;
    _loaded = true;

    final withSalary = provider.accounts.where((a) => a.hasSalarySchedule);
    final account =
        withSalary.isNotEmpty ? withSalary.first : provider.accounts.first;

    _accountId = account.id;
    _frequency = account.effectiveSalaryFrequency;
    _payDay =
        account.salaryDay ?? (_frequency == 'monthly' ? 1 : DateTime.friday);
    final amount = account.salaryAmount;
    if (amount != null && amount > 0) {
      _amountController.text = amount == amount.roundToDouble()
          ? amount.toStringAsFixed(0)
          : '$amount';
    }
  }

  double? get _amount {
    final text = _amountController.text.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  void _save(AppProvider provider, {required bool silent}) {
    final id = _accountId;
    if (id == null) return;
    provider.setAccountSalary(
      id,
      amount: _amount,
      frequency: _frequency,
      day: _payDay,
    );
    if (!silent && mounted) {
      showSettingsToast(context, S.of(context).incomeSaved);
    }
  }

  Future<void> _remove(AppProvider provider) async {
    final s = S.of(context);
    final confirmed = await showSettingsConfirm(
      context,
      title: s.incomeRemoveConfirm,
      message: s.incomeRemoveMessage,
      confirmLabel: s.incomeRemove,
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final id = _accountId;
    if (id == null) return;
    provider.setAccountSalary(id, amount: null);
    _amountController.clear();
    setState(() {});
    if (mounted) showSettingsToast(context, s.incomeRemoved);
  }

  String _weekdayName(int isoWeekday) {
    final date = DateTime(2024, 1, isoWeekday.clamp(1, 7));
    return DateFormat.EEEE(Localizations.localeOf(context).languageCode)
        .format(date);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<AppProvider>();
    _seed(provider);

    if (provider.accounts.isEmpty) {
      return SettingsScaffold(
        title: s.incomeSettings,
        subtitle: s.incomeSettingsSubtitle,
        children: [
          SettingsGroup(
            footer: s.incomeAccountHint,
            children: [
              SettingsRow(
                icon: IOSIcons.account_balance_rounded,
                label: s.incomeNoSalary,
                detail: s.incomeNoSalaryDetail,
                showChevron: false,
              ),
            ],
          ),
        ],
      );
    }

    final account = provider.accounts.firstWhere(
      (a) => a.id == _accountId,
      orElse: () => provider.accounts.first,
    );

    // Preview built from the pending form values, not the saved account, so
    // the monthly figure tracks what the user is typing.
    final amount = _amount ?? 0;
    final preview = Account(
      id: 'preview',
      name: '',
      type: 'bank',
      balance: 0,
      salaryAmount: amount,
      salaryFrequency: _frequency,
      salaryDay: _payDay,
      salaryAnchorDate: account.salaryAnchorDate,
    );
    final money = MoneyFormat.visible(provider.settings);

    return SettingsScaffold(
      title: s.incomeSettings,
      subtitle: s.incomeSettingsSubtitle,
      children: [
        if (amount > 0)
          _MonthlyTotal(
              label: s.incomeTotalMonthly,
              value: money.format(preview.monthlySalaryEquivalent)),
        SettingsGroup(
          header: s.obWageLabel,
          children: [
            _AmountRow(
              controller: _amountController,
              symbol: money.symbol,
              onChanged: (_) => setState(() {}),
              onEditingComplete: () => _save(provider, silent: true),
            ),
          ],
        ),
        if (provider.accounts.length > 1)
          SettingsGroup(
            header: s.incomePaidInto,
            footer: s.incomeAccountHint,
            children: [
              for (final a in provider.accounts)
                SettingsChoiceRow(
                  label: a.name,
                  detail: a.bankName,
                  selected: a.id == account.id,
                  onTap: () => setState(() => _accountId = a.id),
                ),
            ],
          ),
        SettingsGroup(
          header: s.obFrequencyLabel,
          children: [
            SettingsSegmented<String>(
              value: _frequency,
              onChanged: (value) => setState(() {
                _frequency = value;
                // Day-of-month and weekday number different things, so a
                // carried-over value would silently mean the wrong date.
                _payDay = value == 'monthly' ? 1 : DateTime.friday;
                _save(provider, silent: true);
              }),
              segments: {
                'weekly': (icon: null, label: s.obPayWeekly),
                'biweekly': (icon: null, label: s.obPayBiweekly),
                'monthly': (icon: null, label: s.obPayMonthly),
              },
            ),
          ],
        ),
        SettingsGroup(
          header: s.obPayDayLabel,
          children: [
            SettingsRow(
              icon: IOSIcons.calendar_today_rounded,
              label: s.obPayDayLabel,
              value: _frequency == 'monthly'
                  ? (_payDay == 31
                      ? s.obPayDayLastDay
                      : s.obPayDayOfMonth(_payDay))
                  : _weekdayName(_payDay),
              onTap: () => _pickPayDay(provider, s),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            SettingsActionRow(
              icon: IOSIcons.delete_outline_rounded,
              label: s.incomeRemove,
              destructive: true,
              onTap:
                  account.hasSalarySchedule ? () => _remove(provider) : () {},
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPayDay(AppProvider provider, S s) async {
    final monthly = _frequency == 'monthly';
    final options = monthly
        ? List.generate(31, (i) => i + 1)
        : List.generate(7, (i) => i + 1);

    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: GlassPanel(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
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
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final value = options[i];
                      return SettingsChoiceRow(
                        label: monthly
                            ? (value == 31
                                ? s.obPayDayLastDay
                                : s.obPayDayOfMonth(value))
                            : _weekdayName(value),
                        selected: _payDay == value,
                        onTap: () => Navigator.pop(sheetContext, value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (chosen == null || !mounted) return;
    setState(() => _payDay = chosen);
    _save(provider, silent: true);
  }
}

/// Headline restatement of the wage as a per-month figure.
class _MonthlyTotal extends StatelessWidget {
  const _MonthlyTotal({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassPanel(
        radius: 22,
        elevated: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline amount field styled as a settings row.
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.controller,
    required this.symbol,
    required this.onChanged,
    required this.onEditingComplete,
  });

  final TextEditingController controller;
  final String symbol;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              textAlign: TextAlign.right,
              cursorColor: AppTheme.goldPrimary,
              onChanged: onChanged,
              onEditingComplete: onEditingComplete,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
                onEditingComplete();
              },
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
              decoration: const InputDecoration(
                // The app theme fills and outlines every field; both would
                // paint a box inside the settings row.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                hintText: '0',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
