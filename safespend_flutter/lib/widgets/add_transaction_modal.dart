import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/currency_helper.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../services/supabase_sync_service.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/transaction.dart';
import 'account_picker_field.dart';
import 'app_form_sheet.dart';
import 'app_picker_field.dart';
import '../models/recurring_rule.dart';
import '../l10n/app_localizations.dart';

Color _alpha(Color color, double value) => color.withValues(alpha: value);

class AddTransactionModal extends StatefulWidget {
  final String? initialType;
  final Transaction? initialTransaction;
  const AddTransactionModal(
      {super.key, this.initialType, this.initialTransaction});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late String _selectedType;
  bool get _isLocked => widget.initialType != null;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.initialType ?? widget.initialTransaction?.type ?? 'expense';
    if (widget.initialTransaction != null) {
      final t = widget.initialTransaction!;
      _amountController.text = t.amount.toString();
      if (t.fees > 0) _feesController.text = t.fees.toString();
      _noteController.text = t.note ?? '';
      _descriptionController.text = t.description ?? '';
      _selectedCategoryId = t.categoryId;
      _selectedAccountId = t.accountId;
      _selectedDate = DateTime.parse(t.date);
      _expenseSubType = t.expenseSubType;
    }
  }

  final _amountController = TextEditingController();
  final _feesController = TextEditingController();
  final _noteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _recipientController = TextEditingController();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _imagePath;
  DateTime _selectedDate = DateTime.now();
  bool _sendToPerson =
      false; // For transfers: send to a person vs between accounts
  String? _expenseSubType; // 'subscription' | null
  String _subscriptionFrequency = 'monthly';
  bool _isRecurringIncome = false;
  String _incomeFrequency = 'monthly';
  DateTime _incomeNextDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _amountController.dispose();
    _feesController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  String _title(BuildContext context) {
    final s = S.of(context);
    switch (_selectedType) {
      case 'income':
        return s.addIncome;
      case 'transfer':
        return s.transferMoney;
      case 'withdrawal':
        return s.withdraw;
      case 'expense':
        return s.addExpense;
      default:
        return s.addTransaction;
    }
  }

  String _sheetTitle(BuildContext context) {
    if (widget.initialTransaction != null) {
      return '${S.of(context).edit} ${_getTypeLabel(context)}';
    }
    return _title(context);
  }

  Color get _typeColor {
    switch (_selectedType) {
      case 'income':
        return AppTheme.incomeIcon;
      case 'transfer':
        return AppTheme.transferIcon;
      case 'withdrawal':
        return AppTheme.withdrawalIcon;
      case 'expense':
        return AppTheme.expenseIcon;
      default:
        return AppTheme.goldPrimary;
    }
  }

  IconData get _typeIcon {
    switch (_selectedType) {
      case 'income':
        return IOSIcons.arrow_downward_rounded;
      case 'transfer':
        return IOSIcons.swap_horiz_rounded;
      case 'withdrawal':
        return IOSIcons.account_balance_wallet_rounded;
      case 'expense':
        return IOSIcons.arrow_upward_rounded;
      default:
        return IOSIcons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (_selectedAccountId == null && provider.accounts.isNotEmpty) {
          _selectedAccountId = provider.accounts.first.id;
        }

        return AppFormSheet(
          builder: (context, scrollController) => SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppFormSheetHandle(),
                  const SizedBox(height: 16),
                  _buildCompactHeader(isDark),
                  if (!_isLocked && widget.initialTransaction == null) ...[
                    const SizedBox(height: 14),
                    _buildTypeSelector(context),
                  ],
                  const SizedBox(height: 18),
                  _buildAmountField(provider, isDark),
                  const SizedBox(height: 18),

                  // Bank fees (for expense, withdrawal, transfer)
                  if (_selectedType == 'expense' ||
                      _selectedType == 'withdrawal' ||
                      _selectedType == 'transfer') ...[
                    TextField(
                      controller: _feesController,
                      keyboardType: TextInputType.number,
                      decoration: _glassInputDecoration(
                        isDark: isDark,
                        label: 'Bank Fees',
                        hint: '0.00',
                        prefixText:
                            '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                        icon: IOSIcons.account_balance_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Category (for expenses only)
                  if (_selectedType == 'expense') ...[
                    AppPickerField<String>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      prefixIcon: AppIcons.categoryIcon,
                      items: provider.categories
                          .map((cat) => AppPickerItem(
                                value: cat.id,
                                label: cat.name,
                                leadingIcon: _categoryIconData(cat.icon),
                                iconColor: AppTheme.adaptiveIcon(context),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                    const SizedBox(height: 12),
                    // Expense sub-type selector
                    _buildSegmentedControl(
                      isDark: isDark,
                      children: [
                        _buildSegmentOption(
                          isDark: isDark,
                          isSelected: _expenseSubType == null,
                          label: 'One-time',
                          icon: IOSIcons.receipt_rounded,
                          onTap: () => setState(() => _expenseSubType = null),
                        ),
                        _buildSegmentOption(
                          isDark: isDark,
                          isSelected: _expenseSubType == 'subscription',
                          label: 'Subscription',
                          icon: IOSIcons.repeat_rounded,
                          onTap: () =>
                              setState(() => _expenseSubType = 'subscription'),
                        ),
                      ],
                    ),
                    if (_expenseSubType == 'subscription') ...[
                      const SizedBox(height: 10),
                      _buildFrequencySelector(
                        isDark: isDark,
                        selected: _subscriptionFrequency,
                        onChanged: (frequency) =>
                            setState(() => _subscriptionFrequency = frequency),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // From Account (includes Cash for expense/income/transfer, excludes for withdrawal since withdrawal always comes from a bank)
                  _buildAccountDropdown(
                    provider: provider,
                    value: _selectedAccountId,
                    label: _selectedType == 'transfer'
                        ? 'From'
                        : (_selectedType == 'withdrawal'
                            ? 'Withdraw From'
                            : 'Account'),
                    showCashOnHand: _selectedType != 'withdrawal',
                    onChanged: (value) => setState(() {
                      _selectedAccountId = value;
                      _selectedToAccountId = null; // reset To when From changes
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Transfer: toggle between "Own Account" and "Send to Person"
                  if (_selectedType == 'transfer') ...[
                    _buildSegmentedControl(
                      isDark: isDark,
                      children: [
                        _buildSegmentOption(
                          isDark: isDark,
                          isSelected: !_sendToPerson,
                          label: 'Own Account',
                          icon: IOSIcons.account_balance_rounded,
                          onTap: () => setState(() {
                            _sendToPerson = false;
                            _selectedToAccountId = null;
                          }),
                        ),
                        _buildSegmentOption(
                          isDark: isDark,
                          isSelected: _sendToPerson,
                          label: 'Send to Person',
                          icon: IOSIcons.person_rounded,
                          onTap: () => setState(() {
                            _sendToPerson = true;
                            _selectedToAccountId = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_sendToPerson)
                      _buildAccountDropdown(
                        provider: provider,
                        value: _selectedToAccountId,
                        label: 'To',
                        showCashOnHand: false,
                        excludeId: _selectedAccountId,
                        onChanged: (value) =>
                            setState(() => _selectedToAccountId = value),
                      )
                    else
                      TextField(
                        controller: _recipientController,
                        decoration: _glassInputDecoration(
                          isDark: isDark,
                          label: 'Recipient Name',
                          hint: 'Who are you sending to?',
                          icon: IOSIcons.person_rounded,
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Withdrawal info callout
                  if (_selectedType == 'withdrawal')
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: _controlDecoration(isDark,
                          tint: AppTheme.withdrawalIcon, radius: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _alpha(AppTheme.withdrawalIcon, 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(IOSIcons.info_outline_rounded,
                                size: 18, color: AppTheme.withdrawalIcon),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This amount will be deducted from your account and added to Cash.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedDate),
                        );
                        setState(() => _selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? _selectedDate.hour,
                              time?.minute ?? _selectedDate.minute,
                            ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _controlDecoration(isDark, elevated: true),
                      child: Row(
                        children: [
                          Icon(IOSIcons.calendar_today_rounded,
                              size: 18, color: AppTheme.adaptiveIcon(context)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date',
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                  DateFormat('MMM d, yyyy · h:mm a')
                                      .format(_selectedDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Spacer(),
                          Icon(IOSIcons.chevron_right_rounded,
                              size: 20, color: AppTheme.adaptiveIcon(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recurring income toggle (income type only)
                  if (_selectedType == 'income') ...[
                    _buildSegmentedControl(
                      isDark: isDark,
                      children: [
                        _buildSegmentOption(
                          isDark: isDark,
                          isSelected: !_isRecurringIncome,
                          label: 'One-time',
                          icon: IOSIcons.receipt_rounded,
                          onTap: () =>
                              setState(() => _isRecurringIncome = false),
                        ),
                        _buildSegmentOption(
                          isDark: isDark,
                          isSelected: _isRecurringIncome,
                          label: 'Recurring',
                          icon: IOSIcons.repeat_rounded,
                          onTap: () =>
                              setState(() => _isRecurringIncome = true),
                        ),
                      ],
                    ),
                    if (_isRecurringIncome) ...[
                      const SizedBox(height: 10),
                      _buildFrequencySelector(
                        isDark: isDark,
                        selected: _incomeFrequency,
                        onChanged: (frequency) => setState(() {
                          _incomeFrequency = frequency;
                          final now = DateTime.now();
                          _incomeNextDate = frequency == 'weekly'
                              ? now.add(const Duration(days: 7))
                              : frequency == 'yearly'
                                  ? DateTime(now.year + 1, now.month, now.day)
                                  : DateTime(now.year, now.month + 1, now.day);
                        }),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _incomeNextDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null)
                            setState(() => _incomeNextDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _controlDecoration(isDark),
                          child: Row(
                            children: [
                              Icon(IOSIcons.calendar_today_rounded,
                                  size: 16,
                                  color: AppTheme.adaptiveIcon(context)),
                              const SizedBox(width: 10),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Next Income Date',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    Text(
                                        DateFormat('MMM d, yyyy')
                                            .format(_incomeNextDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                  ]),
                              const Spacer(),
                              Icon(IOSIcons.chevron_right_rounded,
                                  size: 18,
                                  color: AppTheme.adaptiveIcon(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Title / Note
                  TextField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _glassInputDecoration(
                      isDark: isDark,
                      label: 'Title (Optional)',
                      hint: 'e.g., Netflix, Groceries...',
                      icon: IOSIcons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _glassInputDecoration(
                      isDark: isDark,
                      label: 'Description (Optional)',
                      hint: 'e.g., Monthly plan, Morning coffee...',
                      icon: IOSIcons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Receipt / Photo (optional)
                  if (_selectedType == 'expense' ||
                      _selectedType == 'income') ...[
                    GestureDetector(
                      onTap: () async {
                        if (_imagePath != null) {
                          setState(() => _imagePath = null);
                        } else {
                          final image = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (image != null) {
                            setState(() =>
                                _imagePath = image.path); // show locally first
                            // Try uploading to Supabase Storage in background
                            final uid =
                                SupabaseConfig.client?.auth.currentUser?.id;
                            if (uid != null) {
                              final url =
                                  await SupabaseSyncService.uploadReceipt(
                                      uid, image.path);
                              if (url != null && mounted)
                                setState(() => _imagePath = url);
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _controlDecoration(isDark, elevated: true),
                        child: _imagePath != null
                            ? Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _imagePath!.startsWith('http')
                                        ? Image.network(_imagePath!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover)
                                        : Image.file(File(_imagePath!),
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Text('Receipt attached',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600))),
                                  Icon(IOSIcons.close_rounded,
                                      size: 18,
                                      color: AppTheme.adaptiveIcon(context)),
                                ],
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.adaptiveIconSurface(context),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(IOSIcons.receipt_long_rounded,
                                        size: 20,
                                        color: AppTheme.adaptiveIcon(context)),
                                  ),
                                  const SizedBox(width: 14),
                                  Text('Attach receipt / photo',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color)),
                                  const Spacer(),
                                  Icon(IOSIcons.chevron_right_rounded,
                                      size: 20,
                                      color: AppTheme.adaptiveIcon(context)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(_typeColor, Colors.white, 0.08)!,
                            Color.lerp(_typeColor, Colors.black, 0.08)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _alpha(Colors.white, 0.20)),
                        boxShadow: [
                          BoxShadow(
                            color: _alpha(_typeColor, isDark ? 0.28 : 0.20),
                            blurRadius: 24,
                            spreadRadius: -8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _addTransaction(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: _selectedType == 'withdrawal'
                              ? const Color(0xFF171719)
                              : Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          widget.initialTransaction != null
                              ? S.of(context).saveChanges
                              : (_isLocked
                                  ? _title(context)
                                  : '${S.of(context).add} ${_getTypeLabel(context)}'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _alpha(_typeColor, isDark ? 0.22 : 0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _alpha(_typeColor, 0.18)),
          ),
          child: Icon(_typeIcon, size: 20, color: _typeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _sheetTitle(context),
              key: ValueKey(_selectedType),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _typeColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _controlDecoration(
    bool isDark, {
    Color? tint,
    double radius = 20,
    bool elevated = false,
  }) {
    final accent = tint ?? AppTheme.adaptiveIcon(context);
    return BoxDecoration(
      color: isDark
          ? _alpha(Colors.white, elevated ? 0.075 : 0.052)
          : _alpha(Colors.white, elevated ? 0.88 : 0.72),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: tint != null
            ? _alpha(accent, isDark ? 0.24 : 0.16)
            : isDark
                ? _alpha(Colors.white, 0.10)
                : _alpha(Colors.black, 0.065),
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: _alpha(Colors.black, isDark ? 0.18 : 0.07),
                blurRadius: 18,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  InputDecoration _glassInputDecoration({
    required bool isDark,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color:
            isDark ? _alpha(Colors.white, 0.10) : _alpha(Colors.black, 0.065),
      ),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon,
          size: 20, color: AppTheme.adaptiveIcon(context, alpha: 0.88)),
      filled: true,
      fillColor:
          isDark ? _alpha(Colors.white, 0.052) : _alpha(Colors.white, 0.72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _alpha(_typeColor, 0.76), width: 1.5),
      ),
      floatingLabelStyle:
          TextStyle(color: _typeColor, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeChip(
            'expense',
            S.of(context).expense,
            IOSIcons.arrow_upward_rounded,
            AppTheme.expenseIcon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeChip(
            'income',
            S.of(context).incomeLabel,
            IOSIcons.arrow_downward_rounded,
            AppTheme.incomeIcon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeChip(
            'transfer',
            S.of(context).transfer,
            IOSIcons.swap_horiz_rounded,
            AppTheme.transferIcon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeChip(
            'withdrawal',
            S.of(context).withdrawal,
            IOSIcons.account_balance_wallet_rounded,
            AppTheme.withdrawalIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(AppProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [_alpha(Colors.white, 0.095), _alpha(Colors.white, 0.040)]
              : [_alpha(Colors.white, 0.96), _alpha(Colors.white, 0.68)],
        ),
        border: Border.all(
          color:
              isDark ? _alpha(Colors.white, 0.13) : _alpha(Colors.white, 0.96),
        ),
        boxShadow: [
          BoxShadow(
            color: _alpha(Colors.black, isDark ? 0.24 : 0.08),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        cursorColor: _typeColor,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: isDark ? Colors.white : const Color(0xFF111113),
        ),
        decoration: InputDecoration(
          labelText: 'Amount',
          hintText: '0.00',
          prefixText:
              '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
          prefixStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _typeColor,
          ),
          floatingLabelStyle: TextStyle(
            color: _typeColor,
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildSegmentedControl({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: _controlDecoration(isDark, radius: 20),
      child: Row(children: children),
    );
  }

  Widget _buildSegmentOption({
    required bool isDark,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final foreground = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final secondary = AppTheme.adaptiveIcon(context, alpha: 0.78);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(vertical: icon == null ? 11 : 8),
          decoration: BoxDecoration(
            color: isSelected
                ? isDark
                    ? _alpha(Colors.white, 0.14)
                    : _alpha(Colors.white, 0.96)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? isDark
                      ? _alpha(Colors.white, 0.12)
                      : _alpha(Colors.black, 0.04)
                  : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _alpha(Colors.black, isDark ? 0.20 : 0.10),
                      blurRadius: 14,
                      spreadRadius: -7,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 17, color: isSelected ? foreground : secondary),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? foreground : secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySelector({
    required bool isDark,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return _buildSegmentedControl(
      isDark: isDark,
      children: ['weekly', 'monthly', 'yearly']
          .map((frequency) => _buildSegmentOption(
                isDark: isDark,
                isSelected: selected == frequency,
                label: frequency[0].toUpperCase() + frequency.substring(1),
                onTap: () => onChanged(frequency),
              ))
          .toList(),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _alpha(color, isDark ? 0.20 : 0.12)
              : isDark
                  ? _alpha(Colors.white, 0.045)
                  : _alpha(Colors.black, 0.025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _alpha(color, 0.72)
                : isDark
                    ? _alpha(Colors.white, 0.08)
                    : _alpha(Colors.black, 0.06),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : isDark
                      ? _alpha(Colors.white, 0.62)
                      : _alpha(Colors.black, 0.48),
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? color
                    : isDark
                        ? _alpha(Colors.white, 0.62)
                        : _alpha(Colors.black, 0.52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required AppProvider provider,
    required String? value,
    required String label,
    required bool showCashOnHand,
    required ValueChanged<String?> onChanged,
    String? excludeId,
  }) {
    if (value == null && showCashOnHand) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => onChanged(AppProvider.cashOnHandId));
    } else if (value == null && provider.accounts.isNotEmpty) {
      final eligibleAccounts = provider.accounts
          .where((account) => excludeId == null || account.id != excludeId)
          .toList();
      if (eligibleAccounts.isNotEmpty) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => onChanged(eligibleAccounts.first.id));
      }
    }

    return AccountPickerField(
      provider: provider,
      label: label,
      value: value,
      includeCashOnHand: showCashOnHand,
      excludeAccountId: excludeId,
      onChanged: onChanged,
    );
  }

  String _categoryIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return AppIcons.home;
      case 'flash':
        return AppIcons.lightning;
      case 'phone':
        return AppIcons.phone;
      case 'tv':
        return AppIcons.tv;
      case 'shield':
        return AppIcons.shield;
      case 'credit_card':
        return AppIcons.creditCard;
      case 'shopping_cart':
        return AppIcons.cart;
      case 'car':
        return AppIcons.car;
      case 'restaurant':
        return AppIcons.food;
      case 'shopping_bag':
        return AppIcons.shoppingBag;
      case 'favorite':
        return AppIcons.heart;
      case 'sports_esports':
        return AppIcons.gaming;
      case 'face':
        return AppIcons.personal;
      case 'school':
        return AppIcons.education;
      case 'flight':
        return AppIcons.travel;
      case 'card_giftcard':
        return AppIcons.gift;
      case 'pets':
        return AppIcons.pets;
      case 'autorenew':
        return AppIcons.autoRenew;
      case 'fitness_center':
        return AppIcons.gym;
      case 'local_cafe':
        return AppIcons.coffee;
      case 'child_care':
        return AppIcons.baby;
      case 'build':
        return AppIcons.tools;
      default:
        return AppIcons.categoryIcon;
    }
  }

  void _addTransaction(AppProvider provider) {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final fees = double.tryParse(_feesController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (amount > 999999999) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount exceeds maximum limit')));
      return;
    }
    if (fees < 0 || fees > 999999) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid fees')));
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')));
      return;
    }

    if (_selectedType == 'expense' && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a budget category')));
      return;
    }

    // For transfers: require either a destination account or a recipient name
    if (_selectedType == 'transfer') {
      if (!_sendToPerson && _selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a destination account')));
        return;
      }
      if (_sendToPerson && _recipientController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter recipient name')));
        return;
      }
    }

    // Build note for send-to-person transfers
    String? note = _noteController.text.isEmpty ? null : _noteController.text;
    if (_sendToPerson && _recipientController.text.isNotEmpty) {
      note =
          'Sent to ${_recipientController.text}${note != null ? ' - $note' : ''}';
    }
    if (_selectedType == 'withdrawal' && (note == null || note.isEmpty)) {
      note = 'Cash withdrawal';
    }
    // Default expense name to category name if title is empty
    if (_selectedType == 'expense' &&
        (note == null || note.isEmpty) &&
        _selectedCategoryId != null) {
      final cat = provider.categories
          .where((c) => c.id == _selectedCategoryId)
          .firstOrNull;
      if (cat != null) note = cat.name;
    }

    final description = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;

    // If editing an existing transaction
    if (widget.initialTransaction != null) {
      final transaction = Transaction(
        id: widget.initialTransaction!.id,
        type: _selectedType,
        amount: amount,
        fees: fees,
        date: _selectedDate.toIso8601String(),
        note: note,
        description: description,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId!,
        toAccountId: _sendToPerson ? null : _selectedToAccountId,
        imagePath: _imagePath,
        expenseSubType: _selectedType == 'expense' ? _expenseSubType : null,
      );
      provider.updateTransaction(transaction);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Transaction updated'),
            backgroundColor: AppTheme.goldPrimary),
      );
      return;
    }

    // Create recurring income rule
    if (_selectedType == 'income' && _isRecurringIncome) {
      final rule = RecurringRule(
        id: const Uuid().v4(),
        frequency: _incomeFrequency,
        nextDate: _incomeNextDate.toIso8601String(),
        isActive: true,
        templateTransaction: Transaction(
          id: '${const Uuid().v4()}_template',
          type: 'income',
          amount: amount,
          date: DateTime.now().toIso8601String(),
          note: note,
          accountId: _selectedAccountId!,
          isRecurring: true,
        ),
      );
      // Also record current income transaction
      final currentTx = Transaction(
        id: const Uuid().v4(),
        type: 'income',
        amount: amount,
        date: _selectedDate.toIso8601String(),
        note: note,
        accountId: _selectedAccountId!,
        imagePath: _imagePath,
        isRecurring: true,
      );
      provider.addTransaction(currentTx);
      provider.addRecurringRule(rule);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Recurring income added'),
            backgroundColor: AppTheme.success),
      );
      return;
    }

    // Create subscription as recurring rule
    if (_selectedType == 'expense' && _expenseSubType == 'subscription') {
      // Use the user-selected date/time as the first due date (may be today-future or future)
      final nextDate = _selectedDate;
      final rule = RecurringRule(
        id: const Uuid().v4(),
        frequency: _subscriptionFrequency,
        nextDate: nextDate.toIso8601String(),
        isActive: true,
        templateTransaction: Transaction(
          id: '${const Uuid().v4()}_template',
          type: 'expense',
          amount: amount,
          date: DateTime.now().toIso8601String(),
          note: note,
          categoryId: _selectedCategoryId,
          accountId: _selectedAccountId!,
          isRecurring: true,
        ),
      );
      provider.addRecurringRule(rule);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Subscription added'),
            backgroundColor: AppTheme.info),
      );
      return;
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      type: _selectedType,
      amount: amount,
      fees: fees,
      date: _selectedDate.toIso8601String(),
      note: note,
      description: description,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId!,
      toAccountId: _sendToPerson ? null : _selectedToAccountId,
      imagePath: _imagePath,
      expenseSubType: _selectedType == 'expense' ? _expenseSubType : null,
    );

    provider.addTransaction(transaction);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${_getTypeLabel(context)} added successfully'),
          backgroundColor: AppTheme.goldPrimary),
    );
  }

  String _getTypeLabel(BuildContext context) {
    final s = S.of(context);
    switch (_selectedType) {
      case 'expense':
        return s.expense;
      case 'income':
        return s.incomeLabel;
      case 'transfer':
        return s.transfer;
      case 'withdrawal':
        return s.withdrawal;
      default:
        return s.transaction;
    }
  }
}
