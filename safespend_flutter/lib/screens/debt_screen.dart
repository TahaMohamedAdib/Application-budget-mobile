import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../utils/currency_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';
import '../models/transaction.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);

        final debtGoals = provider.goals.where((g) => g.type == 'debt').toList();
        final totalDebt = debtGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
        final totalPaid = debtGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
        final totalRemaining = totalDebt - totalPaid;

        // Get debt payment transactions
        final debtTransactions = provider.transactions
            .where((t) => t.type == 'debt_payment')
            .toList()
          ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Debt Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showAddDebtModal(context, provider),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Add Debt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.accentCard(AppTheme.error),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text('Total Remaining Debt', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(cf.format(totalRemaining), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1)),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Debt', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(cf.format(totalDebt), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Paid Off', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(cf.format(totalPaid), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ),

                // Debts List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text('Your Debts', style: Theme.of(context).textTheme.titleLarge),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                ),

                // Debts
                debtGoals.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: AppTheme.premiumCard(context),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.success)
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .scaleXY(begin: 1.0, end: 1.08, duration: 1200.ms, curve: Curves.easeInOut),
                                const SizedBox(height: 16),
                                Text('No debts!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('You have no active debts. Great job!', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final goal = debtGoals[index];
                              final remaining = goal.targetAmount - goal.currentAmount;
                              final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount * 100) : 0.0;
                              final hasDeadline = goal.targetDate != null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: AppTheme.premiumCard(context),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              color: AppTheme.error.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Center(child: Text(goal.icon, style: const TextStyle(fontSize: 20))),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(goal.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                if (hasDeadline)
                                                  Text('Due: ${DateFormat('MMM d, yyyy').format(DateTime.parse(goal.targetDate!))}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(cf.format(remaining), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.error)),
                                              Text('remaining', style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: (progress / 100).clamp(0, 1).toDouble(),
                                          backgroundColor: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF1),
                                          color: AppTheme.success,
                                          minHeight: 7,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${cf.format(goal.currentAmount)} paid', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.success)),
                                          Text('${progress.round()}% complete', style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      // Action buttons row
                                      Row(
                                        children: [
                                          // Pay button
                                          Expanded(
                                            flex: 2,
                                            child: GestureDetector(
                                              onTap: () => _showPayDebtModal(context, provider, goal, cf),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 9),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.success,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.payments_rounded, color: Colors.white, size: 15),
                                                    SizedBox(width: 5),
                                                    Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Edit button
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _showEditDebtModal(context, provider, goal),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 9),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.goldPrimary.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.edit_rounded, color: AppTheme.goldPrimary, size: 14),
                                                    SizedBox(width: 4),
                                                    Text('Edit', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Delete button
                                          GestureDetector(
                                            onTap: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (dCtx) => AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  title: const Text('Delete Debt?'),
                                                  content: Text('Delete "${goal.name}"? This cannot be undone.'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(dCtx, true),
                                                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              ) ?? false;
                                              if (confirmed) provider.deleteGoal(goal.id);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: AppTheme.error.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                                              ),
                                              child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms, delay: (250 + index * 80).ms);
                            },
                            childCount: debtGoals.length,
                          ),
                        ),
                      ),

                // Payment History Header
                if (debtTransactions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text('Payment History', style: Theme.of(context).textTheme.titleLarge),
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  ),

                // Payment History
                if (debtTransactions.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: AppTheme.premiumCard(context),
                        child: Column(
                          children: debtTransactions.take(20).toList().asMap().entries.map((entry) {
                            final t = entry.value;
                            final isLast = entry.key == (debtTransactions.length > 20 ? 19 : debtTransactions.length - 1);
                            final date = DateTime.parse(t.date);

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.credit_card_rounded, color: Color(0xFF8B5CF6), size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.note ?? 'Debt payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(DateFormat('MMM d, yyyy').format(date), style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '-${cf.format(t.amount)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast) Divider(height: 1, indent: 76, color: Theme.of(context).dividerColor),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPayDebtModal(BuildContext context, AppProvider provider, Goal goal, NumberFormat cf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountCtrl = TextEditingController();
    String? selectedAccountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(goal.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record Payment', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(goal.name, style: Theme.of(ctx).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
                  hintText: '0.00',
                  prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 14),
              // Account picker
              DropdownButtonFormField<String>(
                value: selectedAccountId,
                decoration: InputDecoration(
                  labelText: 'Paid from (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No account deduction')),
                  DropdownMenuItem(value: AppProvider.cashOnHandId, child: const Text('Cash')),
                  ...provider.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (v) => setModalState(() => selectedAccountId = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                      return;
                    }
                    // Update goal paid amount (cap at total)
                    final newPaid = (goal.currentAmount + amount).clamp(0, goal.targetAmount).toDouble();
                    provider.updateGoal(goal.copyWith(currentAmount: newPaid));
                    // Create a debt_payment transaction if account selected
                    if (selectedAccountId != null) {
                      provider.addTransaction(Transaction(
                        id: const Uuid().v4(),
                        type: 'debt_payment',
                        amount: amount,
                        date: DateTime.now().toIso8601String(),
                        note: 'Payment: ${goal.name}',
                        accountId: selectedAccountId!,
                      ));
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${cf.format(amount)} paid on ${goal.name}'), backgroundColor: AppTheme.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDebtModal(BuildContext context, AppProvider provider, Goal goal) {
    final nameCtrl = TextEditingController(text: goal.name);
    final totalCtrl = TextEditingController(text: goal.targetAmount.toStringAsFixed(2));
    final paidCtrl = TextEditingController(text: goal.currentAmount.toStringAsFixed(2));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? dueDate = goal.targetDate != null ? DateTime.parse(goal.targetDate!) : null;
    String selectedEmoji = goal.icon;
    final emojiOptions = ['💳', '🏠', '🚗', '📱', '🎓', '💊', '🏦', '💼'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 20),
                  Text('Edit Debt', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  Text('Icon', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: emojiOptions.map((e) {
                      final isSel = selectedEmoji == e;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = e),
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.error.withOpacity(0.12) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: isSel ? Border.all(color: AppTheme.error, width: 2) : null,
                          ),
                          child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Debt Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                      );
                      if (date != null) setModalState(() => dueDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(ctx).dividerColor)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(ctx).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Due Date (Optional)', style: Theme.of(ctx).textTheme.bodySmall),
                            Text(dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate!) : 'Not set', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ]),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(ctx).textTheme.bodySmall?.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final total = double.tryParse(totalCtrl.text) ?? 0;
                        if (total <= 0) return;
                        final paid = double.tryParse(paidCtrl.text) ?? 0;
                        provider.updateGoal(goal.copyWith(
                          name: nameCtrl.text.trim(),
                          targetAmount: total,
                          currentAmount: paid.clamp(0, total),
                          targetDate: dueDate?.toIso8601String(),
                          icon: selectedEmoji,
                        ));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"${nameCtrl.text.trim()}" updated'), backgroundColor: AppTheme.goldPrimary),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDebtModal(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final paidCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? dueDate;
    String selectedEmoji = '💳';
    final emojiOptions = ['💳', '🏠', '🚗', '📱', '🎓', '💊', '🏦', '💼'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 20),
                  Text('Add Debt', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  // Emoji picker
                  Text('Icon', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: emojiOptions.map((e) {
                      final isSel = selectedEmoji == e;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = e),
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.error.withOpacity(0.12) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: isSel ? Border.all(color: AppTheme.error, width: 2) : null,
                          ),
                          child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Debt Name',
                      hintText: 'e.g., Car Loan, Mortgage',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
                      hintText: '0.00',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Already Paid (Optional)',
                      hintText: '0.00',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                      );
                      if (date != null) setModalState(() => dueDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(ctx).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(ctx).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due Date (Optional)', style: Theme.of(ctx).textTheme.bodySmall),
                              Text(
                                dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate!) : 'Not set',
                                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(ctx).textTheme.bodySmall?.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a debt name')));
                          return;
                        }
                        final total = double.tryParse(totalCtrl.text) ?? 0;
                        if (total <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a valid total amount')));
                          return;
                        }
                        final paid = double.tryParse(paidCtrl.text) ?? 0;
                        final debtName = nameCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        provider.addGoal(Goal(
                          id: const Uuid().v4(),
                          type: 'debt',
                          name: debtName,
                          targetAmount: total,
                          currentAmount: paid,
                          targetDate: dueDate?.toIso8601String(),
                          icon: selectedEmoji,
                          color: '#EF4444',
                        ));
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(content: Text('"$debtName" added'), backgroundColor: AppTheme.error),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Add Debt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
