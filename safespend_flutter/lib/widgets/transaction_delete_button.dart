import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';

/// A stable destructive affordance beside the transaction's primary action.
/// The localized tooltip also supplies its screen-reader label.
class TransactionDeleteButton extends StatelessWidget {
  const TransactionDeleteButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: S.of(context).delete,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: AppTheme.error,
          backgroundColor: AppTheme.error.withValues(alpha: dark ? 0.12 : 0.07),
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(IOSIcons.delete_outline_rounded, size: 21),
      ),
    );
  }
}
