import '../utils/system_note.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../services/supabase_sync_service.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/transaction.dart';
import 'account_picker_field.dart';
import 'transaction_form_sheet.dart';
import 'app_form_sheet.dart';
import 'app_picker_field.dart';
import '../models/recurring_rule.dart';
import '../l10n/app_localizations.dart';
import '../widgets/stored_image.dart';

Color _alpha(Color color, double value) => color.withValues(alpha: value);

const _supportedTransactionTypes = {
  'expense',
  'income',
  'transfer',
  'withdrawal',
};

/// Parses monetary input using the active locale while still accepting a
/// canonical dot decimal. Grouping spaces used by several locales are ignored.
double? parseTransactionNumber(String raw, Locale locale) {
  final normalized = raw
      .trim()
      .replaceAll(RegExp(r'[\s\u00A0\u202F]'), '')
      .replaceAll("'", '')
      .replaceAll('\u2019', '');
  if (normalized.isEmpty) return null;

  try {
    final parsed = NumberFormat.decimalPattern(locale.toLanguageTag())
        .parse(normalized)
        .toDouble();
    if (parsed.isFinite) return parsed;
  } on FormatException {
    // Fall through to accept a canonical decimal pasted in another locale.
  }

  var canonical = normalized;
  final lastComma = canonical.lastIndexOf(',');
  final lastDot = canonical.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    if (lastComma > lastDot) {
      canonical = canonical.replaceAll('.', '').replaceAll(',', '.');
    } else {
      canonical = canonical.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    canonical = canonical.replaceAll(',', '.');
  }

  final parsed = double.tryParse(canonical);
  return parsed != null && parsed.isFinite ? parsed : null;
}

/// Shared route for adding and editing transactions from any entry point.
Future<void> showTransactionSheet(
  BuildContext context, {
  String? initialType,
  Transaction? initialTransaction,
}) {
  return showAppFormSheet<void>(
    context: context,
    builder: (_) => AddTransactionModal(
      initialType: initialType,
      initialTransaction: initialTransaction,
    ),
  );
}

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
  bool get _isLocked =>
      widget.initialTransaction == null &&
      _supportedTransactionTypes.contains(widget.initialType);
  bool _isSubmitting = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final requestedType =
        widget.initialTransaction?.type ?? widget.initialType ?? 'expense';
    _selectedType = _supportedTransactionTypes.contains(requestedType)
        ? requestedType
        : 'expense';
    if (widget.initialTransaction != null) {
      final t = widget.initialTransaction!;
      _amountController.text = t.amount.toString();
      if (t.fees > 0) _feesController.text = t.fees.toString();
      _noteController.text = S
              .forLocale(context.read<AppProvider>().settings.locale)
              .systemNote(t.note) ??
          '';
      _descriptionController.text = t.description ?? '';
      _selectedCategoryId = t.categoryId;
      _selectedAccountId = t.accountId;
      _selectedToAccountId = t.toAccountId;
      _selectedDate = DateTime.parse(t.date);
      _expenseSubType = t.expenseSubType;
      _imagePath = t.imagePath;
      _isRecurringIncome = t.type == 'income' && t.isRecurring;

      if (t.type == 'transfer' && t.toAccountId == null) {
        _sendToPerson = true;
        _hydrateRecipientFromNote(S
            .forLocale(context.read<AppProvider>().settings.locale)
            .systemNote(t.note));
      }
    }
  }

  void _hydrateRecipientFromNote(String? storedNote) {
    if (storedNote == null || !storedNote.startsWith('Sent to ')) return;
    final content = storedNote.substring('Sent to '.length);
    final separator = content.indexOf(' - ');
    if (separator < 0) {
      _recipientController.text = content;
      _noteController.clear();
      return;
    }
    _recipientController.text = content.substring(0, separator);
    _noteController.text = content.substring(separator + 3);
  }

  void _clearValidation() {
    if (_validationMessage != null && mounted) {
      setState(() => _validationMessage = null);
    }
  }

  void _selectType(String type) {
    if (_selectedType == type || !_supportedTransactionTypes.contains(type)) {
      return;
    }
    setState(() {
      _selectedType = type;
      _validationMessage = null;
      _selectedToAccountId = null;
      _sendToPerson = false;
      _recipientController.clear();
      if (type != 'expense') {
        _selectedCategoryId = null;
        _expenseSubType = null;
      }
      if (type != 'income') _isRecurringIncome = false;
      if (type == 'withdrawal' &&
          _selectedAccountId == AppProvider.cashOnHandId) {
        _selectedAccountId = null;
      }
    });
  }

  void _normalizeAccountSelections(AppProvider provider) {
    final accountIds = provider.accounts.map((account) => account.id).toSet();
    final cashAllowed = _selectedType != 'withdrawal';
    final sourceIsValid = accountIds.contains(_selectedAccountId) ||
        (cashAllowed && _selectedAccountId == AppProvider.cashOnHandId);

    if (!sourceIsValid) {
      _selectedAccountId = provider.accounts.isNotEmpty
          ? provider.accounts.first.id
          : cashAllowed
              ? AppProvider.cashOnHandId
              : null;
    }

    if (_selectedType == 'transfer' && !_sendToPerson) {
      final destinationIsValid = accountIds.contains(_selectedToAccountId) &&
          _selectedToAccountId != _selectedAccountId;
      if (!destinationIsValid) {
        _selectedToAccountId = provider.accounts
            .where((account) => account.id != _selectedAccountId)
            .firstOrNull
            ?.id;
      }
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
        final s = S.of(context);
        _normalizeAccountSelections(provider);

        return TransactionFormSheet(
          header: _buildCompactHeader(isDark),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _glassInputDecoration(
                    isDark: isDark,
                    label: s.tr('bankFees'),
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
                  label: s.category,
                  value: _selectedCategoryId,
                  prefixIcon: AppIcons.categoryIcon,
                  items: provider.categories
                      .map((cat) => AppPickerItem(
                            value: cat.id,
                            label: s.categoryDisplayName(cat.id, cat.name),
                            leadingIcon: _categoryIconData(cat.icon),
                            iconColor: AppTheme.adaptiveIcon(context),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                const SizedBox(height: 12),
                // Expense sub-type selector
                if (widget.initialTransaction == null)
                  _buildSegmentedControl(
                    isDark: isDark,
                    children: [
                      _buildSegmentOption(
                        isDark: isDark,
                        isSelected: _expenseSubType == null,
                        label: s.tr('oneTime'),
                        icon: IOSIcons.receipt_rounded,
                        onTap: () => setState(() => _expenseSubType = null),
                      ),
                      _buildSegmentOption(
                        isDark: isDark,
                        isSelected: _expenseSubType == 'subscription',
                        label: s.subscription,
                        icon: IOSIcons.repeat_rounded,
                        onTap: () =>
                            setState(() => _expenseSubType = 'subscription'),
                      ),
                    ],
                  ),
                if (widget.initialTransaction == null &&
                    _expenseSubType == 'subscription') ...[
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
                    ? s.fromAccount
                    : (_selectedType == 'withdrawal'
                        ? s.tr('withdrawFrom')
                        : s.account),
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
                      label: s.tr('ownAccount'),
                      icon: IOSIcons.account_balance_rounded,
                      onTap: () => setState(() {
                        _sendToPerson = false;
                        _selectedToAccountId = null;
                      }),
                    ),
                    _buildSegmentOption(
                      isDark: isDark,
                      isSelected: _sendToPerson,
                      label: s.tr('sendToPerson'),
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
                    label: s.toAccount,
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
                      label: s.tr('recipientName'),
                      hint: s.tr('recipientNameHint'),
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
                          s.tr('withdrawalCashInfo'),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.date,
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              '${MaterialLocalizations.of(context).formatMediumDate(_selectedDate)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_selectedDate))}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(IOSIcons.chevron_right_rounded,
                          size: 20, color: AppTheme.adaptiveIcon(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring income toggle (income type only)
              if (_selectedType == 'income' &&
                  widget.initialTransaction == null) ...[
                _buildSegmentedControl(
                  isDark: isDark,
                  children: [
                    _buildSegmentOption(
                      isDark: isDark,
                      isSelected: !_isRecurringIncome,
                      label: s.tr('oneTime'),
                      icon: IOSIcons.receipt_rounded,
                      onTap: () => setState(() => _isRecurringIncome = false),
                    ),
                    _buildSegmentOption(
                      isDark: isDark,
                      isSelected: _isRecurringIncome,
                      label: s.recurring,
                      icon: IOSIcons.repeat_rounded,
                      onTap: () => setState(() => _isRecurringIncome = true),
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
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setState(() => _incomeNextDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _controlDecoration(isDark),
                      child: Row(
                        children: [
                          Icon(IOSIcons.calendar_today_rounded,
                              size: 16, color: AppTheme.adaptiveIcon(context)),
                          const SizedBox(width: 10),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.tr('nextIncomeDate'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text(
                                    MaterialLocalizations.of(context)
                                        .formatMediumDate(_incomeNextDate),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                              ]),
                          const Spacer(),
                          Icon(IOSIcons.chevron_right_rounded,
                              size: 18, color: AppTheme.adaptiveIcon(context)),
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
                  label: s.tr('titleOptional'),
                  hint: s.tr('transactionTitleHint'),
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
                  label: s.tr('descriptionOptional'),
                  hint: s.tr('transactionDescriptionHint'),
                  icon: IOSIcons.notes_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // Receipt / Photo (optional)
              if (_selectedType == 'expense' || _selectedType == 'income') ...[
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
                        // Upload in the background and keep the returned
                        // object PATH, not a URL: these buckets are private,
                        // so a URL expires within the hour and would leave
                        // the receipt broken — permanently, after a
                        // reinstall. The path is re-signed on demand.
                        final uid = SupabaseConfig.client?.auth.currentUser?.id;
                        if (uid != null) {
                          final objectPath =
                              await SupabaseSyncService.uploadReceipt(
                                  uid, image.path);
                          // On failure the local path stays, so the image is
                          // still visible on this device even though it did
                          // not reach the server.
                          if (objectPath != null && mounted) {
                            setState(() => _imagePath = objectPath);
                          }
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
                              StoredImage(
                                reference: _imagePath,
                                width: 56,
                                height: 56,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(s.tr('receiptAttached'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600))),
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
                                  color: AppTheme.adaptiveIconSurface(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(IOSIcons.receipt_long_rounded,
                                    size: 20,
                                    color: AppTheme.adaptiveIcon(context)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  s.tr('attachReceiptPhoto'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color),
                                ),
                              ),
                              Icon(IOSIcons.chevron_right_rounded,
                                  size: 20,
                                  color: AppTheme.adaptiveIcon(context)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
          actions: _buildActions(provider, isDark),
        );
      },
    );
  }

  Widget _buildActions(AppProvider provider, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Submit Button
        if (_validationMessage != null) ...[
          Semantics(
            liveRegion: true,
            child: Container(
              key: const Key('transaction-validation-message'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: _controlDecoration(
                isDark,
                tint: Theme.of(context).colorScheme.error,
                radius: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    IOSIcons.info_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _validationMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
              onPressed: _isSubmitting ? null : () => _addTransaction(provider),
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
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _selectedType == 'withdrawal'
                          ? const Color(0xFF171719)
                          : Colors.white,
                    ),
              ),
            ),
          ),
        ),
      ],
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
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Text(
              _sheetTitle(context),
              key: ValueKey(_selectedType),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _typeColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('transaction-sheet-close'),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          tooltip: S.of(context).close,
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            backgroundColor: _alpha(isDark ? Colors.white : Colors.black, 0.07),
            foregroundColor: AppTheme.adaptiveIcon(context),
          ),
          icon: const Icon(IOSIcons.close_rounded, size: 20),
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
        onChanged: (_) => _clearValidation(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        cursorColor: _typeColor,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: isDark ? Colors.white : const Color(0xFF111113),
            ),
        decoration: InputDecoration(
          labelText: S.of(context).amount,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: '0.00',
          hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).hintColor,
              ),
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
        autofocus: false,
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
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
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
            constraints: const BoxConstraints(minHeight: 44),
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
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? foreground : secondary,
                    ),
                  ),
                ),
              ],
            ),
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
                label: switch (frequency) {
                  'weekly' => S.of(context).weekly,
                  'yearly' => S.of(context).yearly,
                  _ => S.of(context).monthly,
                },
                onTap: () => onChanged(frequency),
              ))
          .toList(),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () => _selectType(type),
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
          constraints: const BoxConstraints(minHeight: 48),
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

  void _showValidation(String message) {
    if (_validationMessage == message) return;
    setState(() => _validationMessage = message);
  }

  void _addTransaction(AppProvider provider) {
    if (_isSubmitting) return;

    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final amountText = _amountController.text.trim();
    final feesText = _feesController.text.trim();
    if (amountText.isEmpty) {
      _showValidation(s.pleaseEnterAmount);
      return;
    }

    final amount = parseTransactionNumber(amountText, locale);
    final fees =
        feesText.isEmpty ? 0.0 : parseTransactionNumber(feesText, locale);
    if (amount == null || amount <= 0) {
      _showValidation(s.enterValidAmount);
      return;
    }
    if (amount > 999999999) {
      _showValidation(s.tr('amountExceedsMaximum'));
      return;
    }
    if (fees == null || fees < 0 || fees > 999999) {
      _showValidation(s.tr('enterValidFees'));
      return;
    }

    final accountIds = provider.accounts.map((account) => account.id).toSet();
    final sourceIsCash = _selectedAccountId == AppProvider.cashOnHandId;
    final sourceIsValid = accountIds.contains(_selectedAccountId) ||
        (_selectedType != 'withdrawal' && sourceIsCash);
    if (_selectedAccountId == null || !sourceIsValid) {
      _showValidation(s.tr('pleaseSelectAccount'));
      return;
    }

    if (_selectedType == 'expense' &&
        !provider.categories.any((c) => c.id == _selectedCategoryId)) {
      _showValidation(s.tr('pleaseSelectBudgetCategory'));
      return;
    }

    final recipient = _recipientController.text.trim();
    if (_selectedType == 'transfer') {
      if (!_sendToPerson &&
          (!accountIds.contains(_selectedToAccountId) ||
              _selectedToAccountId == _selectedAccountId)) {
        _showValidation(s.tr('pleaseSelectDestinationAccount'));
        return;
      }
      if (_sendToPerson && recipient.isEmpty) {
        _showValidation(s.tr('pleaseEnterRecipientName'));
        return;
      }
    }

    var noteText = _noteController.text.trim();
    String? note = noteText.isEmpty ? null : noteText;
    if (_selectedType == 'transfer' && _sendToPerson) {
      note = '${s.tr('sentToRecipient', {'name': recipient})}'
          '${note != null ? ' - $note' : ''}';
    }
    if (_selectedType == 'withdrawal' && note == null) {
      note = systemNote('cashWithdrawal');
    }
    if (_selectedType == 'expense' && note == null) {
      final category = provider.categories
          .where((c) => c.id == _selectedCategoryId)
          .firstOrNull;
      if (category != null) {
        final key = 'defaultCategory_${category.id}';
        note = s.tr(key) == key ? category.name : systemNote(key);
      }
    }
    final originalNote = widget.initialTransaction?.note;
    if (originalNote != null && noteText == s.systemNote(originalNote)) {
      note = originalNote;
    }

    final descriptionText = _descriptionController.text.trim();
    final description = descriptionText.isEmpty ? null : descriptionText;
    final categoryId = _selectedType == 'expense' ? _selectedCategoryId : null;
    final toAccountId = _selectedType == 'transfer' && !_sendToPerson
        ? _selectedToAccountId
        : null;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSubmitting = true;
      _validationMessage = null;
    });

    if (widget.initialTransaction != null) {
      final original = widget.initialTransaction!;
      final transaction = Transaction(
        id: original.id,
        type: _selectedType,
        amount: amount,
        fees: fees,
        date: _selectedDate.toIso8601String(),
        note: note,
        description: description,
        categoryId: categoryId,
        accountId: _selectedAccountId!,
        toAccountId: toAccountId,
        imagePath: _imagePath,
        expenseSubType: _selectedType == 'expense' ? _expenseSubType : null,
        isRecurring: original.isRecurring,
      );
      provider.updateTransaction(transaction);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.tr('transactionUpdated')),
          backgroundColor: AppTheme.goldPrimary,
        ),
      );
      return;
    }

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
          description: description,
          accountId: _selectedAccountId!,
          isRecurring: true,
        ),
      );
      final currentTransaction = Transaction(
        id: const Uuid().v4(),
        type: 'income',
        amount: amount,
        date: _selectedDate.toIso8601String(),
        note: note,
        description: description,
        accountId: _selectedAccountId!,
        imagePath: _imagePath,
        isRecurring: true,
      );
      provider.addTransaction(currentTransaction);
      provider.addRecurringRule(rule);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.tr('recurringIncomeAdded')),
          backgroundColor: AppTheme.success,
        ),
      );
      return;
    }

    if (_selectedType == 'expense' && _expenseSubType == 'subscription') {
      final rule = RecurringRule(
        id: const Uuid().v4(),
        frequency: _subscriptionFrequency,
        nextDate: _selectedDate.toIso8601String(),
        isActive: true,
        templateTransaction: Transaction(
          id: '${const Uuid().v4()}_template',
          type: 'expense',
          amount: amount,
          fees: fees,
          date: DateTime.now().toIso8601String(),
          note: note,
          description: description,
          categoryId: categoryId,
          accountId: _selectedAccountId!,
          isRecurring: true,
          expenseSubType: 'subscription',
        ),
      );
      provider.addRecurringRule(rule);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.tr('subscriptionAdded')),
          backgroundColor: AppTheme.info,
        ),
      );
      return;
    }

    provider.addTransaction(Transaction(
      id: const Uuid().v4(),
      type: _selectedType,
      amount: amount,
      fees: fees,
      date: _selectedDate.toIso8601String(),
      note: note,
      description: description,
      categoryId: categoryId,
      accountId: _selectedAccountId!,
      toAccountId: toAccountId,
      imagePath: _imagePath,
      expenseSubType: _selectedType == 'expense' ? _expenseSubType : null,
    ));
    final successMessage = s.tr('itemAddedSuccessfully', {
      'item': _getTypeLabel(context),
    });
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: AppTheme.goldPrimary,
      ),
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
