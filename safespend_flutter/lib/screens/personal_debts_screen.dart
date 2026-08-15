import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
        final cf = CurrencyHelper.formatter(provider.settings.currency);
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
                      title: 'Personal Debts',
                      subtitle: 'Money other people owe you',
                      onBack: () => Navigator.pop(context),
                      onAdd: () => _showForm(context, provider, null),
                      addTooltip: 'Add personal debt',
                    ),
                  ).animate().fadeIn(duration: 260.ms, curve: Curves.easeOut),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: WealthOverviewCard(
                      icon: IOSIcons.wealthPersonalDebts,
                      label: 'Still owed to you',
                      amount: cf.format(totalLeft),
                      amountColor: totalLeft > 0 ? AppTheme.incomeIcon : null,
                      firstLabel: 'Total lent',
                      firstValue: cf.format(totalOwed),
                      secondLabel: 'Received',
                      secondValue: cf.format(totalReturned),
                      secondValueColor:
                          totalReturned > 0 ? AppTheme.incomeIcon : null,
                      progress: totalOwed > 0 ? totalReturned / totalOwed : 0,
                      progressLabel: totalOwed > 0
                          ? '${((totalReturned / totalOwed) * 100).toStringAsFixed(1)}% received'
                          : 'No personal debts recorded',
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 80.ms),
                ),

                // ── Section title ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: WealthSectionHeader(
                      title: 'People Who Owe You',
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
                              Text('All clear!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Nobody currently owes you money.',
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

  List<Widget> _buildReturnHistory(BuildContext context, AppProvider provider,
      NumberFormat cf, bool isDark) {
    final returnTransactions = provider.transactions
        .where((t) =>
            t.type == 'personal_debt_return' ||
            (t.type == 'income' && t.categoryId == 'debt_payment'))
        .toList()
      ..sort(
          (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    if (returnTransactions.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: const WealthSectionHeader(title: 'Payment History'),
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
                            Text(t.note ?? 'Debt payment',
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
                                    ? 'Cash'
                                    : (provider.accounts
                                            .where((a) => a.id == t.accountId)
                                            .firstOrNull
                                            ?.name ??
                                        'Unknown'),
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
                              Text(DateFormat('MMM d, h:mm a').format(date),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 11)),
                            ]),
                          ])),
                      Text('${isIncoming ? '+' : '-'}${cf.format(t.amount)}',
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
      NumberFormat cf, bool isDark, Color accent, int index) {
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
              Text(isFullyReturned ? 'RECEIVED' : cf.format(remaining),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isFullyReturned ? AppTheme.success : accent)),
              Text(isFullyReturned ? '' : 'remaining',
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${cf.format(returned)} received',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.success)),
            Text('${(progress * 100).round()}% received',
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
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IOSIcons.arrow_downward_rounded,
                              color: Colors.white, size: 15),
                          SizedBox(width: 5),
                          Text('Received',
                              style: TextStyle(
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
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IOSIcons.edit_rounded,
                            color: AppTheme.adaptiveIcon(context), size: 14),
                        const SizedBox(width: 4),
                        Text('Edit',
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
                        title: const Text('Delete entry?'),
                        content: Text(
                            'Remove "${goal.name}"? This cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(d, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.error),
                            child: const Text('Delete'),
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
      BuildContext context, AppProvider provider, Goal goal, NumberFormat cf) {
    final ctrl = TextEditingController();
    final remaining = goal.targetAmount - goal.currentAmount;
    String targetAccountId = AppProvider.cashOnHandId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AppFormSheet(
          builder: (ctx, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppFormSheetHandle(),
                  const SizedBox(height: 16),
                  AppFormSheetHeader(
                    title: 'Payment Received',
                    icon: IOSIcons.arrow_downward_rounded,
                    accent: AppTheme.incomeIcon,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(goal.name,
                        style: Theme.of(ctx).textTheme.bodySmall),
                  ),
                  const SizedBox(height: 8),
                  Text('Still owed: ${cf.format(remaining)}',
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.incomeIcon)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount Received',
                      hintText: '0.00',
                      prefixText:
                          '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Account selection — where the payment is deposited.
                  AppPickerField<String>(
                    label: 'Deposit to',
                    value: targetAccountId,
                    prefixIcon: AppIcons.wallet,
                    items: [
                      const AppPickerItem(
                        value: AppProvider.cashOnHandId,
                        label: 'Cash on Hand',
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
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(ctrl.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Enter a valid amount')));
                          return;
                        }
                        final clampedAmount =
                            amount.clamp(0, remaining).toDouble();
                        provider.receiveDebtPayment(
                            goal.id, clampedAmount, targetAccountId);
                        Navigator.pop(ctx);
                        final isFullyReturned =
                            (goal.currentAmount + clampedAmount) >=
                                goal.targetAmount;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isFullyReturned
                                  ? '${goal.name} has paid in full!'
                                  : '${cf.format(clampedAmount)} received from ${goal.name}'),
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
                      child: const Text('Record Payment',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  // ── Add / Edit form ──
  void _showForm(BuildContext context, AppProvider provider, Goal? existing) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AppFormSheet(
          builder: (ctx, scrollController) => SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFormSheetHandle(),
                    const SizedBox(height: 16),
                    AppFormSheetHeader(
                      title: isEdit ? 'Edit Entry' : 'Someone Owes Me',
                      icon: IOSIcons.wealthPersonalDebts,
                      accent: AppTheme.adaptiveIcon(ctx),
                    ),
                    const SizedBox(height: 20),

                    // Emoji picker
                    Text('Icon',
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
                                        color: AppTheme.adaptiveIcon(ctx),
                                        width: 2)
                                    : null,
                              ),
                              child: Center(
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 22))),
                            ),
                          );
                        }).toList()),
                    const SizedBox(height: 20),

                    // Person name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Person Name',
                        hintText: 'e.g., Ahmed, Mom, Khalid',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        prefixIcon: Icon(IOSIcons.person_rounded,
                            color: AppTheme.adaptiveIcon(ctx)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason
                    TextField(
                      controller: reasonCtrl,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        hintText: 'e.g., Rent, Groceries, Trip',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        prefixIcon: Icon(IOSIcons.notes_rounded,
                            color: AppTheme.adaptiveIcon(ctx)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount Lent',
                        hintText: '0.00',
                        prefixText:
                            '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Already received
                    TextField(
                      controller: returnedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Already Received (Optional)',
                        hintText: '0.00',
                        prefixText:
                            '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter the person\'s name')));
                            return;
                          }
                          final amount = double.tryParse(amountCtrl.text) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter a valid amount')));
                            return;
                          }
                          final returned =
                              (double.tryParse(returnedCtrl.text) ?? 0)
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
                                content: Text('"$name" updated'),
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
                              content: Text(
                                  'Added: $name owes you ${CurrencyHelper.getSymbol(provider.settings.currency)}${amount.toStringAsFixed(2)}'),
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
                        child: Text(isEdit ? 'Save Changes' : 'Save',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
