import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/currency_helper.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/goal.dart';
import '../widgets/app_form_sheet.dart';
import '../widgets/app_picker_field.dart';
import '../widgets/wealth_ui.dart';
import '../utils/money_format.dart';
import '../l10n/app_localizations.dart';

// ── PersonalDebtsScreen ────────────────────────────────────────────────────
// Tracks informal money the user owes to people (friends, family, etc.).
// Uses Goal(type: 'personal_debt'), categoryId stores the reason text.

class PersonalDebtsScreen extends StatelessWidget {
  const PersonalDebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppTheme.incomeIcon;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = S.of(context);
        final cf = MoneyFormat.of(provider.settings);
        final entries =
            provider.goals.where((g) => g.type == 'personal_debt').toList();

        final totalOwed = entries.fold(0.0, (s, g) => s + g.targetAmount);
        final totalReturned = entries.fold(0.0, (s, g) => s + g.currentAmount);
        final totalLeft = totalOwed - totalReturned;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: WealthPageHeader(
                      title: s.personalDebts,
                      subtitle: s.moneyPeopleOweMe,
                      onBack: () => Navigator.pop(context),
                      onAdd: () => _showForm(context, provider, null),
                      addTooltip: s.tr('addPersonalDebt'),
                    ),
                  ).animate().fadeIn(duration: 260.ms, curve: Curves.easeOut),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: WealthOverviewCard(
                      icon: IOSIcons.wealthPersonalDebts,
                      label: s.tr('stillOwedToYou'),
                      amountValue: totalLeft,
                      formatter: cf,
                      amountColor: totalLeft > 0 ? AppTheme.incomeIcon : null,
                      firstLabel: s.tr('totalLent'),
                      firstValue: cf.format(totalOwed),
                      secondLabel: s.received,
                      secondValue: cf.format(totalReturned),
                      secondValueColor:
                          totalReturned > 0 ? AppTheme.incomeIcon : null,
                      progress: totalOwed > 0 ? totalReturned / totalOwed : 0,
                      progressLabel: totalOwed > 0
                          ? s.tr('percentReceived', {
                              'percent': ((totalReturned / totalOwed) * 100)
                                  .toStringAsFixed(1),
                            })
                          : s.tr('noPersonalDebtsRecorded'),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 80.ms),
                ),

                // ── Section title ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: WealthSectionHeader(
                      title: s.tr('peopleWhoOweYou'),
                      count: '${entries.length}',
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 160.ms),
                ),

                // ── List ──
                entries.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: wealthGlassDecoration(context),
                            child: Column(children: [
                              const Text('🤝', style: TextStyle(fontSize: 60))
                                  .animate(
                                      onPlay: (c) => c.repeat(reverse: true))
                                  .scaleXY(
                                      begin: 1.0,
                                      end: 1.08,
                                      duration: 1200.ms,
                                      curve: Curves.easeInOut),
                              const SizedBox(height: 16),
                              Text(s.tr('allClear'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(s.tr('nobodyOwesYou'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center),
                            ]),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 220.ms),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCard(context, provider,
                                entries[index], cf, isDark, accent, index),
                            childCount: entries.length,
                          ),
                        ),
                      ),

                // ── Payment History ──
                ..._buildReturnHistory(context, provider, cf, isDark),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildReturnHistory(
      BuildContext context, AppProvider provider, MoneyFormat cf, bool isDark) {
    final s = S.of(context);
    final returnTransactions = provider.transactions
        .where((t) =>
            t.type == 'personal_debt_return' ||
            (t.type == 'income' &&
                (t.categoryId == 'debt_payment' ||
                    provider.goals.any((g) =>
                        g.type == 'personal_debt' && g.id == t.categoryId))))
        .toList()
      ..sort(
          (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    if (returnTransactions.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: WealthSectionHeader(title: s.paymentHistory),
        )
            .animate()
            .fadeIn(duration: 280.ms, delay: 200.ms, curve: Curves.easeOut),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: Container(
            decoration: wealthGlassDecoration(context),
            child: Column(
              children: returnTransactions
                  .take(20)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final t = entry.value;
                final isLast = entry.key ==
                    (returnTransactions.length > 20
                        ? 19
                        : returnTransactions.length - 1);
                final date = DateTime.parse(t.date);
                final isIncoming = t.type == 'income';
                final financialColor =
                    isIncoming ? AppTheme.incomeIcon : AppTheme.expenseIcon;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.adaptiveIconSurface(context),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                            isIncoming
                                ? IOSIcons.arrow_downward_rounded
                                : IOSIcons.arrow_upward_rounded,
                            color: financialColor,
                            size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                S
                                        .forLocale(context
                                            .read<AppProvider>()
                                            .settings
                                            .locale)
                                        .systemNote(t.note) ??
                                    s.debtPayment,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(IOSIcons.account_balance_wallet_rounded,
                                  size: 12,
                                  color: AppTheme.adaptiveIcon(context)),
                              const SizedBox(width: 4),
                              Text(
                                t.accountId == AppProvider.cashOnHandId
                                    ? s.tr('cash')
                                    : (provider.accounts
                                            .where((a) => a.id == t.accountId)
                                            .firstOrNull
                                            ?.name ??
                                        s.tr('unknown')),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 11),
                              ),
                              Text('  ·  ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 11)),
                              Icon(IOSIcons.access_time_rounded,
                                  size: 12,
                                  color: AppTheme.adaptiveIcon(context)),
                              const SizedBox(width: 4),
                              Text(
                                  '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 11)),
                            ]),
                          ])),
                      Text(cf.signed(t.amount, positive: isIncoming),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: financialColor)),
                    ]),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: 76,
                        color: Theme.of(context).dividerColor),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    ];
  }

  // ── Entry card ──
  Widget _buildCard(BuildContext context, AppProvider provider, Goal goal,
      MoneyFormat cf, bool isDark, Color accent, int index) {
    final s = S.of(context);
    final returned = goal.currentAmount;
    final remaining = goal.targetAmount - returned;
    final progress =
        goal.targetAmount > 0 ? (returned / goal.targetAmount) : 0.0;
    final reason = goal.categoryId; // reused field for storing reason text
    final isFullyReturned = remaining <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: wealthGlassDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row: icon + name + amount
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.adaptiveIconSurface(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(goal.icon, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(goal.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (reason != null && reason.isNotEmpty)
                    Text(reason,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                  isFullyReturned
                      ? s.received.toUpperCase()
                      : cf.format(remaining),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isFullyReturned ? AppTheme.success : accent)),
              Text(isFullyReturned ? '' : s.remaining.toLowerCase(),
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              backgroundColor:
                  isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF1),
              color: AppTheme.success,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                    s.tr('amountReceivedShort', {
                      'amount': cf.format(returned),
                    }),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.success)),
                Text(
                    s.tr('percentReceived', {
                      'percent': (progress * 100).round(),
                    }),
                    style: Theme.of(context).textTheme.bodySmall),
              ]),

          const SizedBox(height: 14),

          // Action buttons
          Row(children: [
            // Return money button
            if (!isFullyReturned)
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _showReturnModal(context, provider, goal, cf),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IOSIcons.arrow_downward_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 5),
                          Text(s.received,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ),
            if (!isFullyReturned) const SizedBox(width: 8),
            // Edit
            Expanded(
              child: GestureDetector(
                onTap: () => _showForm(context, provider, goal),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Wrap(
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [
                        Icon(IOSIcons.edit_rounded,
                            color: AppTheme.adaptiveIcon(context), size: 14),
                        const SizedBox(width: 4),
                        Text(s.edit,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Delete
            GestureDetector(
              onTap: () async {
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(s.tr('deleteEntry')),
                        content: Text(
                            s.deleteConfirm.replaceAll('{name}', goal.name)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: Text(s.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(d, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.error),
                            child: Text(s.delete),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (ok) provider.deleteGoal(goal.id);
              },
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveIconSurface(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(IOSIcons.delete_rounded,
                    color: AppTheme.adaptiveIcon(context), size: 16),
              ),
            ),
          ]),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (200 + index * 70).ms);
  }

  // ── Record how much was returned ──
  void _showReturnModal(
      BuildContext context, AppProvider provider, Goal goal, MoneyFormat cf) {
    final s = S.of(context);
    final ctrl = TextEditingController();
    final remaining = goal.targetAmount - goal.currentAmount;
    String targetAccountId = AppProvider.cashOnHandId;

    showAppFormSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AppFormSheet(
            header: AppFormSheetHeader(
              title: s.paymentReceived,
              icon: IOSIcons.arrow_downward_rounded,
              accent: AppTheme.incomeIcon,
            ),
            body:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child:
                    Text(goal.name, style: Theme.of(ctx).textTheme.bodySmall),
              ),
              const SizedBox(height: 8),
              Text(
                  s.tr('stillOwedAmount', {
                    'amount': cf.format(remaining),
                  }),
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.incomeIcon)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: false,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: s.amountReceived,
                  hintText: '0.00',
                  prefixText:
                      '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 14),
              AppPickerField<String>(
                label: s.tr('depositTo'),
                value: targetAccountId,
                prefixIcon: AppIcons.wallet,
                items: [
                  AppPickerItem(
                    value: AppProvider.cashOnHandId,
                    label: s.cashOnHand,
                    leadingIcon: AppIcons.money,
                    iconColor: AppTheme.cashOnHandIcon,
                  ),
                  ...provider.accounts.map((a) => AppPickerItem(
                        value: a.id,
                        label: a.name,
                        leadingIcon: AppIcons.bank,
                        iconColor: AppTheme.adaptiveIcon(ctx),
                      )),
                ],
                onChanged: (v) => setModal(
                    () => targetAccountId = v ?? AppProvider.cashOnHandId),
              )
            ]),
            actions: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(ctrl.text) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(s.enterValidAmount)));
                    return;
                  }
                  final clampedAmount = amount.clamp(0, remaining).toDouble();
                  provider.receiveDebtPayment(
                      goal.id, clampedAmount, targetAccountId);
                  Navigator.pop(ctx);
                  final isFullyReturned =
                      (goal.currentAmount + clampedAmount) >= goal.targetAmount;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isFullyReturned
                            ? s.tr('personPaidInFull', {
                                'name': goal.name,
                              })
                            : s.receivedFrom
                                .replaceAll(
                                    '{amount}', cf.format(clampedAmount))
                                .replaceAll('{name}', goal.name)),
                        backgroundColor: AppTheme.success),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(s.recordPayment,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            )),
      ),
    );
  }

  // ── Add / Edit form ──
  void _showForm(BuildContext context, AppProvider provider, Goal? existing) {
    final s = S.of(context);
    final cf = MoneyFormat.of(provider.settings);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final reasonCtrl = TextEditingController(text: existing?.categoryId ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.targetAmount.toStringAsFixed(2) : '');
    final returnedCtrl = TextEditingController(
        text:
            existing != null ? existing.currentAmount.toStringAsFixed(2) : '');
    String emoji = existing?.icon ?? '🤝';
    final emojis = ['🤝', '👤', '👨‍👩‍👧', '👫', '💵', '🏡', '🎓', '🛒'];
    final isEdit = existing != null;

    showAppFormSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AppFormSheet(
            header: AppFormSheetHeader(
              title: isEdit ? s.tr('editEntry') : s.tr('someoneOwesMe'),
              icon: IOSIcons.wealthPersonalDebts,
              accent: AppTheme.adaptiveIcon(ctx),
            ),
            body:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.icon,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: emojis.map((e) {
                    final sel = emoji == e;
                    return GestureDetector(
                      onTap: () => setModal(() => emoji = e),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.adaptiveIconSurface(ctx)
                              : (isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : AppTheme.lightBackground),
                          borderRadius: BorderRadius.circular(12),
                          border: sel
                              ? Border.all(
                                  color: AppTheme.adaptiveIcon(ctx), width: 2)
                              : null,
                        ),
                        child: Center(
                            child:
                                Text(e, style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  }).toList()),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: s.tr('personName'),
                  hintText: s.tr('personNameHint'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: Icon(IOSIcons.person_rounded,
                      color: AppTheme.adaptiveIcon(ctx)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: s.tr('reason'),
                  hintText: s.tr('reasonHint'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: Icon(IOSIcons.notes_rounded,
                      color: AppTheme.adaptiveIcon(ctx)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.tr('amountLent'),
                  hintText: '0.00',
                  prefixText:
                      '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: returnedCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.tr('alreadyReceivedOptional'),
                  hintText: '0.00',
                  prefixText:
                      '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              )
            ]),
            actions: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(s.tr('enterPersonName'))));
                    return;
                  }
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(s.enterValidAmount)));
                    return;
                  }
                  final returned = (double.tryParse(returnedCtrl.text) ?? 0)
                      .clamp(0, amount)
                      .toDouble();
                  final name = nameCtrl.text.trim();
                  final messenger = ScaffoldMessenger.of(context);

                  if (isEdit) {
                    provider.updateGoal(existing!.copyWith(
                      name: name,
                      categoryId: reasonCtrl.text.trim().isEmpty
                          ? null
                          : reasonCtrl.text.trim(),
                      targetAmount: amount,
                      currentAmount: returned,
                      icon: emoji,
                    ));
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                        content: Text(s.tr('namedItemUpdated', {
                          'name': name,
                        })),
                        backgroundColor: AppTheme.incomeIcon));
                  } else {
                    provider.addGoal(Goal(
                      id: const Uuid().v4(),
                      type: 'personal_debt',
                      name: name,
                      categoryId: reasonCtrl.text.trim().isEmpty
                          ? null
                          : reasonCtrl.text.trim(),
                      targetAmount: amount,
                      currentAmount: returned,
                      icon: emoji,
                      color: '#73757F',
                    ));
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(s.tr('personalDebtAdded', {
                        'name': name,
                        'amount': cf.format(amount),
                      })),
                      backgroundColor: AppTheme.incomeIcon,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.incomeIcon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(isEdit ? s.saveChanges : s.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            )),
      ),
    );
  }
}
