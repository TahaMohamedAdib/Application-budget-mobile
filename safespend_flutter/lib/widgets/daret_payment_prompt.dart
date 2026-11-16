import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/daret.dart';
import '../providers/app_provider.dart';
import '../utils/money_format.dart';

String _paymentAction(S strings, DaretPayment payment) =>
    strings.tr(payment.isPayout ? 'daretMarkReceived' : 'daretMarkPaid');

String _paymentDetails(
    BuildContext context, DaretPayment payment, MoneyFormat format) {
  final date =
      MaterialLocalizations.of(context).formatMediumDate(payment.dueDate);
  return '${format.format(payment.amount)} · $date';
}

Future<void> showDaretPayments(
    BuildContext context, AppProvider provider) async {
  final strings = S.of(context);
  final format = MoneyFormat.of(provider.settings);
  final selected = await showDialog<DaretPayment>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.tr('daretPaymentsDue')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final payment in provider.dueDaretPayments())
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_paymentAction(strings, payment)),
              subtitle: Text(
                '${payment.daretName}\n${_paymentDetails(dialogContext, payment, format)}',
              ),
              onTap: () => Navigator.pop(dialogContext, payment),
              trailing: const Icon(Icons.chevron_right),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.close),
        ),
      ],
    ),
  );
  if (!context.mounted || selected == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_paymentAction(strings, selected)),
      content: Text(
        '${selected.daretName}\n${_paymentDetails(dialogContext, selected, format)}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(strings.confirm),
        ),
      ],
    ),
  );
  if (!context.mounted || confirmed != true) return;
  bool recorded;
  try {
    recorded = await provider.confirmDaretPayment(selected);
  } catch (_) {
    recorded = false;
  }
  if (!context.mounted || recorded) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(strings.tr('actionCouldNotBeCompleted'))),
  );
}

class DaretPaymentPrompt extends StatelessWidget {
  const DaretPaymentPrompt({super.key, required this.provider});

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final payments = provider.dueDaretPayments();
    if (payments.isEmpty) return const SizedBox.shrink();
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: Text(strings.tr('daretPaymentsDue')),
          subtitle:
              Text(strings.tr('daretPendingCount', {'count': payments.length})),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDaretPayments(context, provider),
        ),
      ),
    );
  }
}
