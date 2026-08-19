import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../utils/currency_helper.dart';
import '../services/supabase_sync_service.dart';
import '../services/supabase_config.dart';
import '../l10n/app_localizations.dart';
import 'account_picker_field.dart';
import 'app_form_sheet.dart';

/// Opens the sheet that creates a new account.
///
/// This and [showEditAccountSheet] used to live on a standalone Accounts
/// screen. That screen is gone — "See All" goes to Wealth now — but adding,
/// renaming and deleting accounts had to survive it, so the sheet moved here
/// where any screen can reach it.
void showAddAccountSheet(BuildContext context) {
  final provider = context.read<AppProvider>();
  final s = S.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AddAccountModal(
      onSave: (account) {
        provider.addAccount(account);
        Navigator.pop(sheetContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${account.name} ${s.added}')),
        );
      },
    ),
  );
}

/// Opens the same sheet against an existing [account].
void showEditAccountSheet(BuildContext context, Account account) {
  final provider = context.read<AppProvider>();
  final s = S.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AddAccountModal(
      account: account,
      onSave: (updated) {
        provider.updateAccount(updated);
        Navigator.pop(sheetContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updated.name} ${s.updated}')),
        );
      },
    ),
  );
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
    return AppFormSheet(
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppFormSheetHandle(),
              const SizedBox(height: 16),
              AppFormSheetHeader(
                title: widget.account == null ? s.addAccount : s.edit,
                icon: IOSIcons.account_balance_rounded,
                accent: AppTheme.adaptiveIcon(context),
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
                  prefixIcon: Icon(IOSIcons.account_balance_wallet,
                      color: AppTheme.adaptiveIcon(context)),
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
                  prefixIcon: Icon(IOSIcons.account_balance,
                      color: AppTheme.adaptiveIcon(context)),
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
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _imagePath != null
                          ? Colors.transparent
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.goldPrimary.withOpacity(0.3),
                          width: 1.5),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _imagePath!.startsWith('http')
                                ? Image.network(_imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        IOSIcons.broken_image_rounded,
                                        size: 28))
                                : Image.file(File(_imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        IOSIcons.broken_image_rounded,
                                        size: 28)),
                          )
                        : Icon(_typeIcon(_selectedType),
                            size: 28, color: AppTheme.adaptiveIcon(context)),
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.goldPrimary.withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(IOSIcons.photo_library_rounded,
                                size: 18,
                                color: AppTheme.adaptiveIcon(context)),
                            const SizedBox(width: 8),
                            Text(s.uploadFromGallery,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.goldPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                      prefixIcon: Icon(IOSIcons.calendar_today_rounded,
                          color: AppTheme.adaptiveIcon(context)),
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
                    return AccountPickerField(
                      provider: provider,
                      label: s.payFromAccount,
                      value: _debtPaymentSourceId,
                      accounts: bankAccounts,
                      cashLabel: s.cashOnHand,
                      onChanged: (value) =>
                          setState(() => _debtPaymentSourceId = value),
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
            ? Icon(IOSIcons.check,
                color: AppTheme.adaptiveIcon(context), size: 20)
            : null,
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'savings':
        return IOSIcons.savings;
      case 'investment':
        return IOSIcons.investment;
      case 'debt':
        return IOSIcons.credit_card;
      default:
        return IOSIcons.account_balance;
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
