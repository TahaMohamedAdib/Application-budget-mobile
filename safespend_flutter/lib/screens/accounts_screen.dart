import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Accounts',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 20, color: Colors.white),
                            onPressed: () => _showAddAccountModal(context, provider),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Accounts List
                  Expanded(
                    child: provider.accounts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No accounts yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add your first account',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.accounts.length,
                            itemBuilder: (context, index) {
                              final account = provider.accounts[index];
                              return Dismissible(
                                key: Key(account.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Account?'),
                                      content: Text(
                                        'Are you sure you want to delete "${account.name}"? This will also delete all associated transactions.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) {
                                  provider.deleteAccount(account.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${account.name} deleted'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          provider.addAccount(account);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => _showEditAccountModal(context, provider, account),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: _getAccountColor(account.color).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getAccountIcon(account.type),
                                              color: _getAccountColor(account.color),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (account.bankName != null)
                                                  Text(
                                                    account.bankName!,
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                Text(
                                                  account.name,
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                ),
                                                Text(
                                                  _getAccountTypeLabel(account.type),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '\$${account.balance.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: account.balance >= 0
                                                      ? AppTheme.gold500
                                                      : Colors.red,
                                                ),
                                              ),
                                              if (!account.includeInNetWorth)
                                                Text(
                                                  'Excluded',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'debt':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getAccountColor(String? colorHex) {
    if (colorHex == null) return AppTheme.goldPrimary;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.goldPrimary;
    }
  }

  String _getAccountTypeLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'savings':
        return 'Savings Account';
      case 'investment':
        return 'Investment Account';
      case 'debt':
        return 'Debt/Loan';
      default:
        return 'Account';
    }
  }

  void _showAddAccountModal(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAccountModal(
        onSave: (account) {
          provider.addAccount(account);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${account.name} added')),
          );
        },
      ),
    );
  }

  void _showEditAccountModal(BuildContext context, AppProvider provider, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAccountModal(
        account: account,
        onSave: (updatedAccount) {
          provider.updateAccount(updatedAccount);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${updatedAccount.name} updated')),
          );
        },
      ),
    );
  }
}

class AddAccountModal extends StatefulWidget {
  final Account? account;
  final Function(Account) onSave;

  const AddAccountModal({
    super.key,
    this.account,
    required this.onSave,
  });

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal> {
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'bank';
  String _selectedColor = '#B8860B';
  bool _includeInNetWorth = true;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _bankNameController.text = widget.account!.bankName ?? '';
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedColor = widget.account!.color ?? '#B8860B';
      _includeInNetWorth = widget.account!.includeInNetWorth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.account == null ? 'Add Account' : 'Edit Account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Account Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., Checking Account',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
              ),
              const SizedBox(height: 16),
              
              // Bank Name (Optional)
              TextField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name (Optional)',
                  hintText: 'e.g., Chase, Bank of America',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),
              
              // Balance
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Balance',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),
              
              // Account Type
              Text(
                'Account Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip('bank', 'Bank Account', Icons.account_balance),
                ],
              ),
              const SizedBox(height: 24),
              
              // Color Picker
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  '#B8860B', // Gold
                  '#EF4444', // Red
                  '#10B981', // Green
                  '#3B82F6', // Blue
                  '#8B5CF6', // Purple
                  '#F59E0B', // Amber
                  '#EC4899', // Pink
                  '#64748B', // Slate
                ].map((color) => _buildColorOption(color)).toList(),
              ),
              const SizedBox(height: 24),
              
              // Include in Net Worth
              SwitchListTile(
                value: _includeInNetWorth,
                onChanged: (value) => setState(() => _includeInNetWorth = value),
                title: const Text('Include in Net Worth'),
                subtitle: const Text('Count this account in net worth calculations'),
                activeThumbColor: AppTheme.goldPrimary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.account == null ? 'Add Account' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = type);
      },
      selectedColor: AppTheme.goldPrimary.withOpacity(0.3),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: isSelected ? AppTheme.goldPrimary : Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildColorOption(String colorHex) {
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    final isSelected = _selectedColor == colorHex;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorHex),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  void _saveAccount() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text) ?? 0;

    final account = Account(
      id: widget.account?.id ?? const Uuid().v4(),
      name: _nameController.text,
      type: _selectedType,
      balance: balance,
      bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
      color: _selectedColor,
      includeInNetWorth: _includeInNetWorth,
    );

    widget.onSave(account);
  }
}
