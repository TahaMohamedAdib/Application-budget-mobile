import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../utils/currency_helper.dart';
import '../services/supabase_sync_service.dart';
import '../services/supabase_config.dart';
import '../l10n/app_localizations.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final s = S.of(context);
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
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
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
                          s.accounts,
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
                            icon: const Icon(Icons.add,
                                size: 20, color: Colors.white),
                            onPressed: () =>
                                _showAddAccountModal(context, provider, s),
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
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  s.noAccountsYet,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.tapPlusToAddFirstAccount,
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
                              return Slidable(
                                key: Key(account.id),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.22,
                                  children: [
                                    CustomSlidableAction(
                                      onPressed: (_) async {
                                        final confirmed = await showDialog<
                                                bool>(
                                              context: context,
                                              builder: (dCtx) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                title: Text(s.delete),
                                                content: Text(
                                                    '${s.delete} "${account.name}"? ${s.allAssociatedTransactionsWillBeRemoved}'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dCtx, false),
                                                      child: Text(s.cancel)),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            dCtx, true),
                                                    style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            AppTheme.error),
                                                    child: Text(s.delete),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;
                                        if (confirmed)
                                          provider.deleteAccount(account.id);
                                      },
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                            color: AppTheme.error,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.delete_rounded,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => _showEditAccountModal(
                                        context, provider, account, s),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _getAccountColor(
                                                      account.color)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border(
                                                  left: BorderSide(
                                                      color: _getAccountColor(
                                                          account.color),
                                                      width: 3)),
                                            ),
                                            child: account.imagePath != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            13),
                                                    child: account.imagePath!
                                                            .startsWith('http')
                                                        ? Image.network(
                                                            account.imagePath!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __,
                                                                    ___) =>
                                                                Icon(_getAccountIcon(account.type),
                                                                    color: _getAccountColor(account
                                                                        .color),
                                                                    size: 20))
                                                        : Image.file(File(account.imagePath!),
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => Icon(
                                                                _getAccountIcon(account.type),
                                                                color: _getAccountColor(account.color),
                                                                size: 20)),
                                                  )
                                                : Icon(
                                                    _getAccountIcon(
                                                        account.type),
                                                    color: _getAccountColor(
                                                        account.color),
                                                    size: 20,
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (account.bankName != null)
                                                  Text(
                                                    account.bankName!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                Text(
                                                  account.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      _getAccountTypeLabel(
                                                          account.type, s),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                    if (account.salaryAmount !=
                                                            null &&
                                                        account.salaryAmount! >
                                                            0) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppTheme
                                                              .goldPrimary
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          'Salary day ${account.salaryDay}',
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: AppTheme
                                                                  .goldPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                cf.format(account.balance),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: account.balance >= 0
                                                      ? _getAccountColor(account.color)
                                                      : AppTheme.error,
                                                ),
                                              ),
                                              if (!account.includeInNetWorth)
                                                Text(
                                                  s.excluded,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
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

  String _getAccountTypeLabel(String type, S s) {
    switch (type) {
      case 'bank':
        return s.bankAccount;
      case 'savings':
        return s.savingsAccount;
      case 'investment':
        return s.investmentAccount;
      case 'debt':
        return s.debtAccount;
      default:
        return s.account;
    }
  }

  void _showAddAccountModal(BuildContext context, AppProvider provider, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAccountModal(
        onSave: (account) {
          provider.addAccount(account);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${account.name} ${s.added}')),
          );
        },
      ),
    );
  }

  void _showEditAccountModal(
      BuildContext context, AppProvider provider, Account account, S s) {
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
            SnackBar(content: Text('${updatedAccount.name} ${s.updated}')),
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
  final _debtPaymentController = TextEditingController();
  String _selectedType = 'bank';
  String _selectedColor = '#B8860B';
  bool _includeInNetWorth = true;
  String? _imagePath;
  bool _enableDebtPayment = false;
  int _debtPaymentDay = 1;
  String? _debtPaymentSourceId;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      final a = widget.account!;
      _nameController.text = a.name;
      _bankNameController.text = a.bankName ?? '';
      _balanceController.text = a.balance.toString();
      _selectedType = a.type;
      _selectedColor = a.color ?? '#B8860B';
      _includeInNetWorth = a.includeInNetWorth;
      _imagePath = a.imagePath;
      if (a.debtPaymentAmount != null && a.debtPaymentAmount! > 0) {
        _enableDebtPayment = true;
        _debtPaymentController.text = a.debtPaymentAmount.toString();
        _debtPaymentDay = a.debtPaymentDay ?? 1;
        _debtPaymentSourceId = a.debtPaymentSourceId;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    _debtPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    widget.account == null ? s.addAccount : s.edit,
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
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.accountName,
                  hintText: s.hintCheckingAccount,
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
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.bankName,
                  hintText: s.hintChaseBank,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),

              // Balance with currency symbol from settings
              Builder(builder: (ctx) {
                final provider = Provider.of<AppProvider>(ctx, listen: false);
                final symbol =
                    CurrencyHelper.getSymbol(provider.settings.currency);
                return TextField(
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.balance,
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Logo Upload
              Text(s.logo, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Builder(builder: (ctx) {
                final accentColor = Color(int.parse(
                    _selectedColor.replaceFirst('#', '0xFF')));
                return Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _imagePath != null
                            ? Colors.transparent
                            : accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: accentColor.withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: _imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _imagePath!.startsWith('http')
                                  ? Image.network(_imagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.broken_image_rounded,
                                          size: 28,
                                          color: accentColor))
                                  : Image.file(File(_imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.broken_image_rounded,
                                          size: 28,
                                          color: accentColor)),
                            )
                          : Icon(_typeIcon(_selectedType),
                              size: 28, color: accentColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final image = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          if (image != null) {
                            setState(() => _imagePath = image.path);
                            final uid =
                                SupabaseConfig.client?.auth.currentUser?.id;
                            if (uid != null) {
                              final url =
                                  await SupabaseSyncService.uploadAccountLogo(
                                      uid, image.path);
                              if (url != null && mounted)
                                setState(() => _imagePath = url);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: accentColor.withOpacity(0.35),
                                width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_rounded,
                                  size: 18, color: accentColor),
                              const SizedBox(width: 8),
                              Text(s.uploadFromGallery,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Color Picker
              Text(
                s.color,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  '#B8860B', // Gold
                  '#EF4444', // Red
                  '#0b715f', // Green
                  '#3B82F6', // Blue
                  '#8B5CF6', // Purple
                  '#F59E0B', // Amber
                  '#EC4899', // Pink
                  '#64748B', // Slate
                ].map((color) => _buildColorOption(color)).toList(),
              ),
              const SizedBox(height: 24),

              // ── Debt Monthly Payment (only for debt accounts) ──
              if (_selectedType == 'debt') ...[
                SwitchListTile(
                  value: _enableDebtPayment,
                  onChanged: (v) => setState(() => _enableDebtPayment = v),
                  title: Text(s.monthlyPayment),
                  subtitle: Text(s.automaticallyPayDebtMonthly),
                  activeThumbColor: AppTheme.goldPrimary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_enableDebtPayment) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (ctx) {
                    final provider =
                        Provider.of<AppProvider>(ctx, listen: false);
                    final symbol =
                        CurrencyHelper.getSymbol(provider.settings.currency);
                    return TextField(
                      controller: _debtPaymentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.paymentAmount,
                        hintText: '0.00',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(symbol,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.goldPrimary)),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _debtPaymentDay,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s.paymentDayOfMonth,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                    ),
                    items: List.generate(
                        28,
                        (i) => DropdownMenuItem(
                            value: i + 1, child: Text('${s.day} ${i + 1}'))),
                    onChanged: (v) => setState(() => _debtPaymentDay = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (ctx) {
                    final provider =
                        Provider.of<AppProvider>(ctx, listen: false);
                    final bankAccounts = provider.accounts
                        .where(
                            (a) => a.type != 'debt' && a.type != 'investment')
                        .toList();
                    return DropdownButtonFormField<String>(
                      value: _debtPaymentSourceId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: s.payFromAccount,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.account_balance_rounded),
                      ),
                      hint: Text(s.selectAccount),
                      items: [
                        DropdownMenuItem(
                            value: AppProvider.cashOnHandId,
                            child: Text(s.cashOnHand)),
                        ...bankAccounts.map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name))),
                      ],
                      onChanged: (v) =>
                          setState(() => _debtPaymentSourceId = v),
                    );
                  }),
                ],
                const SizedBox(height: 16),
              ],

              // Include in Net Worth
              SwitchListTile(
                value: _includeInNetWorth,
                onChanged: (value) =>
                    setState(() => _includeInNetWorth = value),
                title: Text(s.includeInNetWorth),
                subtitle: Text(s.countThisAccountInNetWorth),
                activeThumbColor: AppTheme.goldPrimary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

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
                    widget.account == null ? s.addAccount : s.save,
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
        color:
            isSelected ? AppTheme.goldPrimary : Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildColorOption(String colorHex) {
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    final isSelected = _selectedColor == colorHex;

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorHex),
      child: Container(
        width: 44,
        height: 44,
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'debt':
        return Icons.credit_card;
      default:
        return Icons.account_balance;
    }
  }

  void _saveAccount() {
    if (_nameController.text.isEmpty) {
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pleaseEnterAccountName)),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text) ?? 0;

    final debtAmt = _enableDebtPayment
        ? (double.tryParse(_debtPaymentController.text) ?? 0)
        : null;
    final account = Account(
      id: widget.account?.id ?? const Uuid().v4(),
      name: _nameController.text,
      type: _selectedType,
      balance: balance,
      bankName:
          _bankNameController.text.isEmpty ? null : _bankNameController.text,
      color: _selectedColor,
      includeInNetWorth: _includeInNetWorth,
      imagePath: _imagePath,
      salaryAmount: null,
      salaryDay: null,
      lastSalaryDate: widget.account?.lastSalaryDate,
      debtPaymentAmount: (_selectedType == 'debt' &&
              _enableDebtPayment &&
              debtAmt != null &&
              debtAmt > 0)
          ? debtAmt
          : null,
      debtPaymentDay: (_selectedType == 'debt' && _enableDebtPayment)
          ? _debtPaymentDay
          : null,
      debtPaymentSourceId: (_selectedType == 'debt' && _enableDebtPayment)
          ? _debtPaymentSourceId
          : null,
    );

    widget.onSave(account);
  }
}
