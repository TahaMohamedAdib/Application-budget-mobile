import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';

class AddTransactionModal extends StatefulWidget {
  final String? initialType;
  const AddTransactionModal({super.key, this.initialType});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late String _selectedType;
  bool get _isLocked => widget.initialType != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'expense';
  }

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _recipientController = TextEditingController();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _sendToPerson = false; // For transfers: send to a person vs between accounts

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  String get _title {
    switch (_selectedType) {
      case 'income': return 'Add Income';
      case 'transfer': return 'Transfer Money';
      case 'withdrawal': return 'Withdrawal';
      case 'expense': return 'Add Expense';
      default: return 'Add Transaction';
    }
  }

  String get _subtitle {
    switch (_selectedType) {
      case 'income': return 'Record money coming in';
      case 'transfer': return 'Move money between accounts';
      case 'withdrawal': return 'Withdraw cash — adds to Cash on Hand';
      case 'expense': return 'Record a purchase or payment';
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
                  // Handle bar
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),

                  // Header with icon badge when locked to a type
                  if (_isLocked) ...[
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_typeIcon, color: _typeColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(_subtitle, style: Theme.of(context).textTheme.bodySmall),
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
                        Text('Add Transaction', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Type Selector (only when NOT opened from speed dial)
                    Row(
                      children: [
                        Expanded(child: _buildTypeChip('expense', 'Expense', Icons.arrow_upward_rounded, AppTheme.error)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('income', 'Income', Icons.arrow_downward_rounded, AppTheme.success)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('transfer', 'Transfer', Icons.swap_horiz_rounded, AppTheme.info)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('withdrawal', 'Withdrawal', Icons.account_balance_wallet_rounded, AppTheme.warning)),
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

                  // Category (for expenses only)
                  if (_selectedType == 'expense') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                      hint: const Text('Select category'),
                      items: provider.categories.map((category) {
                        return DropdownMenuItem(value: category.id, child: Text(category.name));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // From Account (includes Cash on Hand for expense/income/transfer, excludes for withdrawal since withdrawal always comes from a bank)
                  _buildAccountDropdown(
                    provider: provider,
                    value: _selectedAccountId,
                    label: _selectedType == 'transfer' ? 'From' : (_selectedType == 'withdrawal' ? 'Withdraw From' : 'Account'),
                    icon: Icons.account_balance_wallet_rounded,
                    showCashOnHand: _selectedType != 'withdrawal',
                    onChanged: (value) => setState(() => _selectedAccountId = value),
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
                        showCashOnHand: true,
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
                              'This amount will be deducted from your account and added to Cash on Hand.',
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
                      if (date != null) setState(() => _selectedDate = date);
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
                              Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional)',
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      prefixIcon: const Icon(Icons.note_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                        _isLocked ? _title : 'Add ${_getTypeLabel()}',
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
    final cf = CurrencyHelper.formatter(provider.settings.currency);
    final items = <DropdownMenuItem<String>>[];

    // Add Cash on Hand option
    if (showCashOnHand) {
      items.add(DropdownMenuItem(
        value: AppProvider.cashOnHandId,
        child: Row(
          children: [
            const Icon(Icons.payments_rounded, size: 18, color: AppTheme.warning),
            const SizedBox(width: 8),
            const Text('Cash on Hand'),
            const Spacer(),
            Text(cf.format(provider.totalCash), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ));
    }

    // Add real accounts
    for (final account in provider.accounts) {
      if (excludeId != null && account.id == excludeId) continue;
      items.add(DropdownMenuItem(
        value: account.id,
        child: Row(
          children: [
            Icon(_accountIcon(account.type), size: 18, color: AppTheme.goldPrimary),
            const SizedBox(width: 8),
            Text(account.name),
            const Spacer(),
            Text(cf.format(account.balance), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ));
    }

    // Default selection
    if (value == null && items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(items.first.value);
      });
    }

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        prefixIcon: Icon(icon),
      ),
      hint: const Text('Select account'),
      items: items,
      onChanged: onChanged,
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

  void _addTransaction(AppProvider provider) {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
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

    final transaction = Transaction(
      id: const Uuid().v4(),
      type: _selectedType,
      amount: amount,
      date: _selectedDate.toIso8601String(),
      note: note,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId!,
      toAccountId: _sendToPerson ? null : _selectedToAccountId,
    );

    provider.addTransaction(transaction);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_getTypeLabel()} added successfully'), backgroundColor: AppTheme.goldPrimary),
    );
  }

  String _getTypeLabel() {
    switch (_selectedType) {
      case 'expense': return 'Expense';
      case 'income': return 'Income';
      case 'transfer': return 'Transfer';
      case 'withdrawal': return 'Withdrawal';
      default: return 'Transaction';
    }
  }
}
