import 'dart:io';
import 'package:flutter/material.dart';
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
import 'app_picker_field.dart';
import '../models/recurring_rule.dart';
import '../l10n/app_localizations.dart';

class AddTransactionModal extends StatefulWidget {
  final String? initialType;
  final Transaction? initialTransaction;
  const AddTransactionModal({super.key, this.initialType, this.initialTransaction});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late String _selectedType;
  bool get _isLocked => widget.initialType != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? widget.initialTransaction?.type ?? 'expense';
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
  bool _sendToPerson = false; // For transfers: send to a person vs between accounts
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
      case 'income': return s.addIncome;
      case 'transfer': return s.transferMoney;
      case 'withdrawal': return s.withdraw;
      case 'expense': return s.addExpense;
      default: return s.addTransaction;
    }
  }

  String _subtitle(BuildContext context) {
    final s = S.of(context);
    switch (_selectedType) {
      case 'income': return s.recordMoneyComingIn;
      case 'transfer': return s.moveMoneyBetweenAccounts;
      case 'withdrawal': return s.withdrawCash;
      case 'expense': return s.recordPurchaseOrPayment;
      default: return '';
    }
  }

  IconData get _typeIcon {
    switch (_selectedType) {
      case 'income': return Icons.arrow_downward_rounded;
      case 'transfer': return Icons.swap_horiz_rounded;
      case 'withdrawal': return Icons.account_balance_wallet_rounded;
      case 'expense': return Icons.arrow_upward_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  Color get _typeColor {
    switch (_selectedType) {
      case 'income': return AppTheme.success;
      case 'transfer': return AppTheme.info;
      case 'withdrawal': return AppTheme.warning;
      case 'expense': return AppTheme.error;
      default: return AppTheme.goldPrimary;
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

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 20),

                  // Header with icon badge when locked to a type
                  if (_isLocked || widget.initialTransaction != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_typeIcon, color: _typeColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.initialTransaction != null ? S.of(context).editTransaction : _title(context),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(_subtitle(context), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ] else ...[
                    // Generic header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.of(context).addTransaction, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Type Selector (only when NOT opened from speed dial)
                    Row(
                      children: [
                        Expanded(child: _buildTypeChip('expense', S.of(context).expense, Icons.arrow_upward_rounded, AppTheme.error)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('income', S.of(context).incomeLabel, Icons.arrow_downward_rounded, AppTheme.success)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('transfer', S.of(context).transfer, Icons.swap_horiz_rounded, AppTheme.info)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('withdrawal', S.of(context).withdrawal, Icons.account_balance_wallet_rounded, AppTheme.warning)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Amount
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // Bank fees (for expense, withdrawal, transfer)
                  if (_selectedType == 'expense' || _selectedType == 'withdrawal' || _selectedType == 'transfer') ...[
                    TextField(
                      controller: _feesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bank Fees',
                        hintText: '0.00',
                        prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        prefixIcon: const Icon(Icons.account_balance_rounded),
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
                      items: provider.categories.map((cat) => AppPickerItem(
                        value: cat.id,
                        label: cat.name,
                        leadingIcon: _categoryIconData(cat.icon),
                        iconColor: AppTheme.goldPrimary,
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                    const SizedBox(height: 12),
                    // Expense sub-type selector
                    Row(
                      children: [
                        Expanded(child: _buildSubTypeChip(null, 'One-time', Icons.receipt_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSubTypeChip('subscription', 'Subscription', Icons.repeat_rounded)),
                      ],
                    ),
                    if (_expenseSubType == 'subscription') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: ['weekly', 'monthly', 'yearly'].map((f) {
                          final isActive = _subscriptionFrequency == f;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _subscriptionFrequency = f),
                              child: Container(
                                margin: EdgeInsets.only(right: f == 'yearly' ? 0 : 6),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.info.withOpacity(0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isActive ? AppTheme.info : Theme.of(context).dividerColor),
                                ),
                                child: Center(child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppTheme.info : Theme.of(context).textTheme.bodySmall?.color))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // From Account (includes Cash for expense/income/transfer, excludes for withdrawal since withdrawal always comes from a bank)
                  _buildAccountDropdown(
                    provider: provider,
                    value: _selectedAccountId,
                    label: _selectedType == 'transfer' ? 'From' : (_selectedType == 'withdrawal' ? 'Withdraw From' : 'Account'),
                    icon: Icons.account_balance_wallet_rounded,
                    showCashOnHand: _selectedType != 'withdrawal',
                    onChanged: (value) => setState(() {
                      _selectedAccountId = value;
                      _selectedToAccountId = null; // reset To when From changes
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Transfer: toggle between "Own Account" and "Send to Person"
                  if (_selectedType == 'transfer') ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _sendToPerson = false; _selectedToAccountId = null; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_sendToPerson ? AppTheme.info.withOpacity(0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: !_sendToPerson ? AppTheme.info : Theme.of(context).dividerColor),
                              ),
                              child: Center(child: Text('Own Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: !_sendToPerson ? AppTheme.info : Theme.of(context).textTheme.bodySmall?.color))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _sendToPerson = true; _selectedToAccountId = null; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _sendToPerson ? AppTheme.info.withOpacity(0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _sendToPerson ? AppTheme.info : Theme.of(context).dividerColor),
                              ),
                              child: Center(child: Text('Send to Person', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sendToPerson ? AppTheme.info : Theme.of(context).textTheme.bodySmall?.color))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_sendToPerson)
                      _buildAccountDropdown(
                        provider: provider,
                        value: _selectedToAccountId,
                        label: 'To',
                        icon: Icons.account_balance_rounded,
                        showCashOnHand: false,
                        excludeId: _selectedAccountId,
                        onChanged: (value) => setState(() => _selectedToAccountId = value),
                      )
                    else
                      TextField(
                        controller: _recipientController,
                        decoration: InputDecoration(
                          labelText: 'Recipient Name',
                          hintText: 'Who are you sending to?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          prefixIcon: const Icon(Icons.person_rounded),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Withdrawal info callout
                  if (_selectedType == 'withdrawal')
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This amount will be deducted from your account and added to Cash.',
                              style: TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w500),
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
                          date.year, date.month, date.day,
                          time?.hour ?? _selectedDate.hour,
                          time?.minute ?? _selectedDate.minute,
                        ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: Theme.of(context).textTheme.bodySmall),
                              Text(DateFormat('MMM d, yyyy · h:mm a').format(_selectedDate), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recurring income toggle (income type only)
                  if (_selectedType == 'income') ...[
                    Row(
                      children: [
                        Expanded(child: _buildSubTypeChip(null, 'One-time', Icons.receipt_rounded)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRecurringIncome = !_isRecurringIncome),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _isRecurringIncome ? AppTheme.success.withOpacity(0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isRecurringIncome ? AppTheme.success : Theme.of(context).dividerColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.repeat_rounded, size: 18, color: _isRecurringIncome ? AppTheme.success : Theme.of(context).textTheme.bodySmall?.color),
                                  const SizedBox(height: 3),
                                  Text('Recurring', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _isRecurringIncome ? AppTheme.success : Theme.of(context).textTheme.bodySmall?.color)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isRecurringIncome) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: ['weekly', 'monthly', 'yearly'].map((f) {
                          final isActive = _incomeFrequency == f;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                              _incomeFrequency = f;
                              final now = DateTime.now();
                              _incomeNextDate = f == 'weekly'
                                  ? now.add(const Duration(days: 7))
                                  : f == 'yearly'
                                      ? DateTime(now.year + 1, now.month, now.day)
                                      : DateTime(now.year, now.month + 1, now.day);
                            }),
                              child: Container(
                                margin: EdgeInsets.only(right: f == 'yearly' ? 0 : 6),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.success.withOpacity(0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isActive ? AppTheme.success : Theme.of(context).dividerColor),
                                ),
                                child: Center(child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppTheme.success : Theme.of(context).textTheme.bodySmall?.color))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _incomeNextDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) setState(() => _incomeNextDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Next Income Date', style: Theme.of(context).textTheme.bodySmall),
                                Text(DateFormat('MMM d, yyyy').format(_incomeNextDate), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ]),
                              const Spacer(),
                              Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
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
                    decoration: InputDecoration(
                      labelText: 'Title (Optional)',
                      hintText: 'e.g., Netflix, Groceries...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g., Monthly plan, Morning coffee...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      prefixIcon: const Icon(Icons.notes_rounded),
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
                          final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (image != null) {
                            setState(() => _imagePath = image.path); // show locally first
                            // Try uploading to Supabase Storage in background
                            final uid = SupabaseConfig.client?.auth.currentUser?.id;
                            if (uid != null) {
                              final url = await SupabaseSyncService.uploadReceipt(uid, image.path);
                              if (url != null && mounted) setState(() => _imagePath = url);
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _imagePath != null ? Colors.transparent : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: _imagePath != null
                            ? Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _imagePath!.startsWith('http')
                                        ? Image.network(_imagePath!, width: 56, height: 56, fit: BoxFit.cover)
                                        : Image.file(File(_imagePath!), width: 56, height: 56, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Text('Receipt attached', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                                  Icon(Icons.close_rounded, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                                ],
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.goldPrimary),
                                  ),
                                  const SizedBox(width: 14),
                                  Text('Attach receipt / photo', style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _addTransaction(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLocked ? _typeColor : AppTheme.goldPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.initialTransaction != null
                            ? S.of(context).saveChanges
                            : (_isLocked ? _title(context) : '${S.of(context).add} ${_getTypeLabel(context)}'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildSubTypeChip(String? value, String label, IconData icon) {
    final isSelected = _expenseSubType == value;
    final color = value == 'subscription'
        ? AppTheme.info
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return GestureDetector(
      onTap: () => setState(() => _expenseSubType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? (value == null ? AppTheme.goldPrimary.withOpacity(0.12) : color.withOpacity(0.12)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (value == null ? AppTheme.goldPrimary : color) : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? (value == null ? AppTheme.goldPrimary : color) : Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? (value == null ? AppTheme.goldPrimary : color) : Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Theme.of(context).dividerColor, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required AppProvider provider,
    required String? value,
    required String label,
    required IconData icon,
    required bool showCashOnHand,
    required ValueChanged<String?> onChanged,
    String? excludeId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf     = CurrencyHelper.formatter(provider.settings.currency);

    // Determine display info for current selection
    String selName    = 'Select account';
    String? selBal;
    Widget  selIcon   = Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color);

    if (value == AppProvider.cashOnHandId) {
      selName  = 'Cash';
      selBal   = cf.format(provider.totalCash);
      selIcon  = const Icon(Icons.payments_rounded, size: 20, color: AppTheme.warning);
    } else if (value != null) {
      final acc = provider.accounts.where((a) => a.id == value).firstOrNull;
      if (acc != null) {
        selName = acc.name;
        selBal  = cf.format(acc.balance);
        selIcon = acc.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: acc.imagePath!.startsWith('http')
                    ? Image.network(acc.imagePath!, width: 20, height: 20, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(_accountIcon(acc.type), size: 20, color: AppTheme.goldPrimary))
                    : Image.file(File(acc.imagePath!), width: 20, height: 20, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(_accountIcon(acc.type), size: 20, color: AppTheme.goldPrimary)),
              )
            : Icon(_accountIcon(acc.type), size: 20, color: AppTheme.goldPrimary);
      }
    } else if (showCashOnHand) {
      // Auto-default to cash if nothing else selected
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(AppProvider.cashOnHandId));
    } else if (provider.accounts.isNotEmpty) {
      final first = provider.accounts.firstWhere(
        (a) => excludeId == null || a.id != excludeId,
        orElse: () => provider.accounts.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(first.id));
    }

    return GestureDetector(
      onTap: () => _showAccountSheet(
        provider: provider,
        currentValue: value,
        label: label,
        showCashOnHand: showCashOnHand,
        excludeId: excludeId,
        onChanged: onChanged,
        cf: cf,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8),
        ),
        child: Row(
          children: [
            selIcon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(selName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (selBal != null) ...[
              Text(selBal, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(width: 6),
            ],
            Icon(Icons.expand_more_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet({
    required AppProvider provider,
    required String? currentValue,
    required String label,
    required bool showCashOnHand,
    required String? excludeId,
    required ValueChanged<String?> onChanged,
    required NumberFormat cf,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 16),
              Text(label, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (showCashOnHand)
                _buildAccountSheetRow(
                  ctx: ctx, isDark: isDark,
                  iconWidget: const Icon(Icons.payments_rounded, size: 20, color: AppTheme.warning),
                  iconBg: AppTheme.warning.withOpacity(0.12),
                  name: 'Cash',
                  sublabel: 'Cash on hand',
                  balance: cf.format(provider.totalCash),
                  isSelected: currentValue == AppProvider.cashOnHandId,
                  onTap: () { onChanged(AppProvider.cashOnHandId); Navigator.pop(ctx); },
                ),
              ...provider.accounts
                  .where((a) => excludeId == null || a.id != excludeId)
                  .map((a) {
                final iconW = a.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: a.imagePath!.startsWith('http')
                            ? Image.network(a.imagePath!, width: 22, height: 22, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(_accountIcon(a.type), size: 20, color: AppTheme.goldPrimary))
                            : Image.file(File(a.imagePath!), width: 22, height: 22, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(_accountIcon(a.type), size: 20, color: AppTheme.goldPrimary)),
                      )
                    : Icon(_accountIcon(a.type), size: 20, color: AppTheme.goldPrimary);
                return _buildAccountSheetRow(
                  ctx: ctx, isDark: isDark,
                  iconWidget: iconW,
                  iconBg: AppTheme.goldPrimary.withOpacity(0.12),
                  name: a.name,
                  sublabel: a.bankName ?? (a.type[0].toUpperCase() + a.type.substring(1)),
                  balance: cf.format(a.balance),
                  isSelected: currentValue == a.id,
                  onTap: () { onChanged(a.id); Navigator.pop(ctx); },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSheetRow({
    required BuildContext ctx,
    required bool isDark,
    required Widget iconWidget,
    required Color iconBg,
    required String name,
    required String sublabel,
    required String balance,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(sublabel, style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(balance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.goldPrimary : Theme.of(ctx).dividerColor,
              size: 22,
            ),
          ],
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

  String _categoryIconData(String iconName) {
    switch (iconName) {
      case 'home': return AppIcons.home;
      case 'flash': return AppIcons.lightning;
      case 'phone': return AppIcons.phone;
      case 'tv': return AppIcons.tv;
      case 'shield': return AppIcons.shield;
      case 'credit_card': return AppIcons.creditCard;
      case 'shopping_cart': return AppIcons.cart;
      case 'car': return AppIcons.car;
      case 'restaurant': return AppIcons.food;
      case 'shopping_bag': return AppIcons.shoppingBag;
      case 'favorite': return AppIcons.heart;
      case 'sports_esports': return AppIcons.gaming;
      case 'face': return AppIcons.personal;
      case 'school': return AppIcons.education;
      case 'flight': return AppIcons.travel;
      case 'card_giftcard': return AppIcons.gift;
      case 'pets': return AppIcons.pets;
      case 'autorenew': return AppIcons.autoRenew;
      case 'fitness_center': return AppIcons.gym;
      case 'local_cafe': return AppIcons.coffee;
      case 'child_care': return AppIcons.baby;
      case 'build': return AppIcons.tools;
      default: return AppIcons.categoryIcon;
    }
  }

  void _addTransaction(AppProvider provider) {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final fees = double.tryParse(_feesController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (amount > 999999999) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount exceeds maximum limit')));
      return;
    }
    if (fees < 0 || fees > 999999) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid fees')));
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }

    if (_selectedType == 'expense' && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a budget category')));
      return;
    }

    // For transfers: require either a destination account or a recipient name
    if (_selectedType == 'transfer') {
      if (!_sendToPerson && _selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a destination account')));
        return;
      }
      if (_sendToPerson && _recipientController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter recipient name')));
        return;
      }
    }

    // Build note for send-to-person transfers
    String? note = _noteController.text.isEmpty ? null : _noteController.text;
    if (_sendToPerson && _recipientController.text.isNotEmpty) {
      note = 'Sent to ${_recipientController.text}${note != null ? ' - $note' : ''}';
    }
    if (_selectedType == 'withdrawal' && (note == null || note.isEmpty)) {
      note = 'Cash withdrawal';
    }
    // Default expense name to category name if title is empty
    if (_selectedType == 'expense' && (note == null || note.isEmpty) && _selectedCategoryId != null) {
      final cat = provider.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      if (cat != null) note = cat.name;
    }

    final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;

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
        goalId: widget.initialTransaction!.goalId,
        imagePath: _imagePath,
        expenseSubType: _selectedType == 'expense' ? _expenseSubType : null,
      );
      provider.updateTransaction(transaction);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Transaction updated'), backgroundColor: AppTheme.goldPrimary),
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
        SnackBar(content: const Text('Recurring income added'), backgroundColor: AppTheme.success),
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
        SnackBar(content: const Text('Subscription added'), backgroundColor: AppTheme.info),
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
      SnackBar(content: Text('${_getTypeLabel(context)} added successfully'), backgroundColor: AppTheme.goldPrimary),
    );
  }

  String _getTypeLabel(BuildContext context) {
    final s = S.of(context);
    switch (_selectedType) {
      case 'expense': return s.expense;
      case 'income': return s.incomeLabel;
      case 'transfer': return s.transfer;
      case 'withdrawal': return s.withdrawal;
      default: return s.transaction;
    }
  }
}
