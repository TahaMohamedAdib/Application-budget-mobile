import 'package:flutter/material.dart';

import '../models/account.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'app_picker_field.dart';
import '../utils/money_format.dart';

const _allAccountsValue = '__all_accounts__';
const _noAccountValue = '__no_account__';

class AccountPickerField extends StatelessWidget {
  final AppProvider provider;
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<Account>? accounts;
  final bool includeCashOnHand;
  final bool includeAllAccounts;
  final bool includeNoAccount;
  final String allAccountsLabel;
  final String noAccountLabel;
  final String cashLabel;
  final String? excludeAccountId;
  final String? prefixIcon;
  final String? helperText;
  final AppPickerTriggerBuilder<String>? triggerBuilder;

  const AccountPickerField({
    super.key,
    required this.provider,
    required this.label,
    required this.value,
    required this.onChanged,
    this.accounts,
    this.includeCashOnHand = true,
    this.includeAllAccounts = false,
    this.includeNoAccount = false,
    this.allAccountsLabel = 'All Accounts',
    this.noAccountLabel = 'No account',
    this.cashLabel = 'Cash on Hand',
    this.excludeAccountId,
    this.prefixIcon = AppIcons.wallet,
    this.helperText,
    this.triggerBuilder,
  }) : assert(!includeAllAccounts || !includeNoAccount);

  String? get _pickerValue {
    if (value != null) return value;
    if (includeAllAccounts) return _allAccountsValue;
    if (includeNoAccount) return _noAccountValue;
    return null;
  }

  String _iconForType(String type) {
    switch (type) {
      case 'bank':
        return AppIcons.bank;
      case 'savings':
        return AppIcons.savings;
      case 'investment':
        return AppIcons.investments;
      case 'debt':
        return AppIcons.creditCard;
      default:
        return AppIcons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = MoneyFormat.of(provider.settings);
    final eligibleAccounts = (accounts ?? provider.accounts)
        .where((account) => account.id != excludeAccountId)
        .toList();
    final total =
        eligibleAccounts.fold(0.0, (sum, account) => sum + account.balance);

    return AppPickerField<String>(
      label: label,
      value: _pickerValue,
      prefixIcon: prefixIcon,
      helperText: helperText,
      triggerBuilder: triggerBuilder,
      items: [
        if (includeAllAccounts)
          AppPickerItem(
            value: _allAccountsValue,
            label: allAccountsLabel,
            subtitle: '${formatter.format(total)} combined',
            leadingIcon: AppIcons.wallet,
            iconColor: AppTheme.adaptiveIcon(context),
          ),
        if (includeNoAccount)
          AppPickerItem(
            value: _noAccountValue,
            label: noAccountLabel,
            subtitle: 'Do not change an account balance',
            leadingIcon: AppIcons.close,
            iconColor: AppTheme.adaptiveIcon(context, alpha: 0.58),
          ),
        if (includeCashOnHand)
          AppPickerItem(
            value: AppProvider.cashOnHandId,
            label: cashLabel,
            subtitle: formatter.format(provider.totalCash),
            leadingIcon: AppIcons.money,
            iconColor: AppTheme.cashOnHandIcon,
          ),
        ...eligibleAccounts.map(
          (account) => AppPickerItem(
            value: account.id,
            label: account.name,
            subtitle:
                '${formatter.format(account.balance)} · ${account.bankName ?? _accountTypeLabel(account.type)}',
            leadingIcon: _iconForType(account.type),
            iconColor: AppTheme.adaptiveIcon(context),
            imagePath: account.imagePath,
          ),
        ),
      ],
      onChanged: (selected) {
        if (selected == _allAccountsValue || selected == _noAccountValue) {
          onChanged(null);
          return;
        }
        onChanged(selected);
      },
    );
  }

  String _accountTypeLabel(String type) {
    if (type.isEmpty) return 'Account';
    return '${type[0].toUpperCase()}${type.substring(1)}';
  }
}
