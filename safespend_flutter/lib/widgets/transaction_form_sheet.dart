import 'package:flutter/material.dart';
import 'app_form_sheet.dart';

/// Transaction-specific header and stable keys over the common form surface.
class TransactionFormSheet extends StatelessWidget {
  const TransactionFormSheet(
      {super.key,
      required this.header,
      required this.body,
      required this.actions});
  final Widget header;
  final Widget body;
  final Widget actions;

  @override
  Widget build(BuildContext context) => AppFormSheet(
        header: header,
        body: body,
        actions: actions,
        headerIncludesCloseButton: true,
        surfaceKey: const ValueKey('transaction-sheet-surface'),
        fieldsKey: const ValueKey('transaction-sheet-fields'),
      );
}
