import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../utils/currency_helper.dart';
import '../models/goal.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import '../widgets/app_form_sheet.dart';
import '../widgets/app_picker_field.dart';
import '../widgets/wealth_ui.dart';
import '../utils/money_format.dart';
import '../l10n/app_localizations.dart';
import '../widgets/stored_image.dart';
import '../services/supabase_sync_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = S.of(context);
        final cf = MoneyFormat.of(provider.settings);
        final savingsGoals =
            provider.goals.where((g) => g.type == 'savings').toList();
        final totalSaved =
            savingsGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
        final totalTarget =
            savingsGoals.fold(0.0, (sum, g) => sum + g.targetAmount);

        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: WealthPageHeader(
                      title: s.savingsGoals,
                      subtitle: s.tr('buildTowardWhatMatters'),
                      onBack: () => Navigator.pop(context),
                      onAdd: () => _showAddGoalModal(context, provider),
                      addTooltip: s.tr('addSavingsGoal'),
                    ),
                  ).animate().fadeIn(duration: 260.ms),
                ),

                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: WealthOverviewCard(
                      icon: IOSIcons.wealthSavingsGoals,
                      label: s.tr('totalSaved'),
                      amountValue: totalSaved,
                      formatter: cf,
                      firstLabel: s.tr('target'),
                      firstValue: cf.format(totalTarget),
                      secondLabel: s.goals,
                      secondValue: '${savingsGoals.length}',
                      progress: totalTarget > 0 ? totalSaved / totalTarget : 0,
                      progressLabel: totalTarget > 0
                          ? s.tr('percentOfTotalTargets', {
                              'percent': ((totalSaved / totalTarget) * 100)
                                  .toStringAsFixed(1),
                            })
                          : s.tr('createGoalToBeginSaving'),
                    )
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: 0.05, end: 0),
                  ),
                ),

                // Goals List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: WealthSectionHeader(
                      title: s.tr('yourGoals'),
                      count: '${savingsGoals.length}',
                    ),
                  ),
                ),

                // Goals List
                if (savingsGoals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(IOSIcons.flag_outlined,
                              size: 64, color: AppTheme.adaptiveIcon(context)),
                          const SizedBox(height: 16),
                          Text(s.tr('noSavingsGoals'),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(s.tr('tapPlusToCreateFirstGoal'),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = savingsGoals[index];
                          return _buildGoalCard(
                              context, goal, provider, cf, isDark, index);
                        },
                        childCount: savingsGoals.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, AppProvider provider,
      MoneyFormat cf, bool isDark, int index) {
    final s = S.of(context);
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final hasMonthly = goal.monthlyPayment != null && goal.monthlyPayment! > 0;
    final dueDate =
        goal.targetDate != null ? DateTime.tryParse(goal.targetDate!) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: wealthGlassDecoration(context),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                onTap: () => _showGoalDetails(context, goal, provider, cf),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildGoalIcon(goal, 44),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(goal.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (goal.description != null &&
                                    goal.description!.isNotEmpty)
                                  Text(goal.description!,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(cf.format(goal.currentAmount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              AppTheme.adaptiveIcon(context))),
                              Text('${s.of_} ${cf.format(goal.targetAmount)}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.adaptiveIcon(context)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.adaptiveIcon(context))),
                          const Spacer(),
                          if (hasMonthly)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.adaptiveIconSurface(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(IOSIcons.autorenew_rounded,
                                      size: 12,
                                      color: AppTheme.adaptiveIcon(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                      '${cf.format(goal.monthlyPayment!)}${s.perMonth}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.adaptiveIcon(context),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          if (dueDate != null) ...[
                            const SizedBox(width: 8),
                            Text(
                                MaterialLocalizations.of(context)
                                    .formatMediumDate(dueDate),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildGoalActionButton(
                            icon: IOSIcons.add_rounded,
                            label: s.tr('addSavings'),
                            backgroundColor:
                                AppTheme.adaptiveIconSurface(context),
                            foregroundColor:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    AppTheme.adaptiveIcon(context),
                            onTap: () => _showContributeModal(
                                context, goal, provider, cf),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGoalActionButton(
                            icon: IOSIcons.edit_rounded,
                            label: s.edit,
                            backgroundColor:
                                AppTheme.adaptiveIconSurface(context),
                            foregroundColor:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    AppTheme.adaptiveIcon(context),
                            borderColor: Theme.of(context).dividerColor,
                            onTap: () =>
                                _showEditGoalModal(context, goal, provider),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGoalActionButton(
                            icon: IOSIcons.delete_outline_rounded,
                            label: s.delete,
                            backgroundColor:
                                AppTheme.adaptiveIconSurface(context),
                            foregroundColor: AppTheme.error,
                            borderColor: Theme.of(context).dividerColor,
                            onTap: () =>
                                _confirmDelete(context, goal, provider),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 280.ms, delay: (50 * index).ms)
          .slideX(begin: 0.05, end: 0),
    );
  }

  Widget _buildGoalIcon(Goal goal, double size) {
    if (goal.imagePath != null && goal.imagePath!.isNotEmpty) {
      // StoredImage resolves whichever form the row holds: a storage object
      // path (current), a local file path (not yet uploaded), or a full URL
      // (older rows). Private-bucket links are signed on demand.
      return StoredImage(
        reference: goal.imagePath,
        bucket: SupabaseSyncService.logosBucket,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 3),
        placeholder: _buildEmojiIcon(goal.icon, size),
        errorWidget: _buildEmojiIcon(goal.icon, size),
      );
    }
    return _buildEmojiIcon(goal.icon, size);
  }

  Widget _buildEmojiIcon(String emoji, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.adaptiveIconSurface(context),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.5))),
    );
  }

  Widget _buildGoalActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor == null ? null : Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppTheme.adaptiveIcon(context)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDetails(
      BuildContext context, Goal goal, AppProvider provider, MoneyFormat cf) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(3))),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildGoalIcon(goal, 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(goal.name,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              if (goal.description != null)
                                Text(goal.description!,
                                    style: Theme.of(ctx).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(ctx, s.tr('saved'),
                        cf.format(goal.currentAmount), null),
                    _buildDetailRow(ctx, s.tr('target'),
                        cf.format(goal.targetAmount), null),
                    _buildDetailRow(
                        ctx,
                        s.remaining,
                        cf.format(goal.targetAmount - goal.currentAmount),
                        null),
                    if (goal.targetDate != null)
                      _buildDetailRow(
                          ctx,
                          s.dueDate,
                          MaterialLocalizations.of(ctx).formatMediumDate(
                              DateTime.parse(goal.targetDate!)),
                          null),
                    if (goal.monthlyPayment != null &&
                        goal.monthlyPayment! > 0) ...[
                      const Divider(height: 24),
                      Text(s.tr('autoSave'),
                          style: Theme.of(ctx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildDetailRow(ctx, s.monthlyAmount,
                          cf.format(goal.monthlyPayment!), null),
                      if (goal.paymentDay != null)
                        _buildDetailRow(ctx, s.paymentDayOfMonth,
                            '${s.day} ${goal.paymentDay}', null),
                      if (goal.paymentSourceAccountId != null) ...[
                        Builder(builder: (_) {
                          final acc = provider.accounts
                              .where((a) => a.id == goal.paymentSourceAccountId)
                              .firstOrNull;
                          final name = goal.paymentSourceAccountId ==
                                  AppProvider.cashOnHandId
                              ? s.cashOnHand
                              : (acc?.name ?? s.tr('unknown'));
                          return _buildDetailRow(
                              ctx, s.fromAccount, name, null);
                        }),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext ctx, String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Goal goal, AppProvider provider) {
    final s = S.of(ctx);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${s.deleteGoal}?'),
        content: Text(s.deleteConfirm.replaceAll('{name}', goal.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx), child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              provider.deleteGoal(goal.id);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(s.tr('namedItemDeleted', {
                      'name': goal.name,
                    })),
                    backgroundColor: AppTheme.error),
              );
            },
            child:
                Text(s.delete, style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showContributeModal(
      BuildContext context, Goal goal, AppProvider provider, MoneyFormat cf) {
    final s = S.of(context);
    final amountCtrl = TextEditingController();
    String? selectedAccountId = AppProvider.cashOnHandId;

    showAppFormSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AppFormSheet(
            header: AppFormSheetHeader(
                title: s.tr('addToSavings'),
                icon: IOSIcons.wealthSavingsGoals,
                accent: AppTheme.adaptiveIcon(ctx)),
            body:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(goal.name, style: Theme.of(ctx).textTheme.bodySmall),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                decoration: InputDecoration(
                  labelText: s.amount,
                  prefixText:
                      '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              AppPickerField<String>(
                label: s.fromAccount,
                value: selectedAccountId,
                prefixIcon: AppIcons.wallet,
                items: [
                  AppPickerItem(
                    value: AppProvider.cashOnHandId,
                    label: s.cashOnHand,
                    subtitle: s.tr('cash'),
                    leadingIcon: AppIcons.money,
                    iconColor: AppTheme.cashOnHandIcon,
                  ),
                  ...provider.accounts.map((a) => AppPickerItem(
                        value: a.id,
                        label: a.name,
                        subtitle: cf.format(a.balance),
                        leadingIcon: AppIcons.bank,
                        iconColor: AppTheme.adaptiveIcon(ctx),
                        imagePath: a.imagePath,
                      )),
                ],
                onChanged: (v) => setModalState(() => selectedAccountId = v),
              )
            ]),
            actions: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(s.enterValidAmount)));
                    return;
                  }
                  provider.contributeToGoalFromSource(goal.id, amount,
                      selectedAccountId ?? AppProvider.cashOnHandId);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(s.tr('addedAmountToGoal', {
                          'amount': cf.format(amount),
                          'name': goal.name,
                        })),
                        backgroundColor: AppTheme.success),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(s.tr('addSavings'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            )),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context, AppProvider provider) {
    _showGoalForm(context, provider, null);
  }

  void _showEditGoalModal(
      BuildContext context, Goal goal, AppProvider provider) {
    _showGoalForm(context, provider, goal);
  }

  void _showGoalForm(
      BuildContext context, AppProvider provider, Goal? existingGoal) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cf = MoneyFormat.of(provider.settings);
    final isEditing = existingGoal != null;

    final nameCtrl = TextEditingController(text: existingGoal?.name ?? '');
    final descCtrl =
        TextEditingController(text: existingGoal?.description ?? '');
    final targetCtrl = TextEditingController(
        text: existingGoal?.targetAmount.toStringAsFixed(2) ?? '');
    final savedCtrl = TextEditingController(
        text: existingGoal?.currentAmount.toStringAsFixed(2) ?? '0.00');
    final monthlyCtrl = TextEditingController(
        text: existingGoal?.monthlyPayment?.toStringAsFixed(2) ?? '');

    String selectedEmoji = existingGoal?.icon ?? '🎯';
    String? imagePath = existingGoal?.imagePath;
    DateTime? dueDate = existingGoal?.targetDate != null
        ? DateTime.tryParse(existingGoal!.targetDate!)
        : null;
    bool hasMonthly = existingGoal?.monthlyPayment != null &&
        existingGoal!.monthlyPayment! > 0;
    int paymentDay = existingGoal?.paymentDay ?? 1;
    String? paymentSourceAccountId =
        existingGoal?.paymentSourceAccountId ?? AppProvider.cashOnHandId;
    String? initialSavedFromAccountId = AppProvider.cashOnHandId;

    final emojiOptions = [
      '🎯',
      '🏠',
      '🚗',
      '✈️',
      '💍',
      '🎓',
      '💻',
      '📱',
      '🏖️',
      '💰',
      '🎁',
      '🏆'
    ];

    showAppFormSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AppFormSheet(
            header: AppFormSheetHeader(
              title: isEditing ? s.editGoal : s.tr('newSavingsGoal'),
              icon: IOSIcons.wealthSavingsGoals,
              accent: AppTheme.adaptiveIcon(ctx),
            ),
            body:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.icon,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, maxWidth: 512);
                      if (picked != null)
                        setModalState(() => imagePath = picked.path);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceElevated
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                        border: imagePath != null
                            ? Border.all(
                                color: AppTheme.adaptiveIcon(ctx), width: 2)
                            : null,
                      ),
                      child: imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(imagePath!),
                                  fit: BoxFit.cover))
                          : const Icon(IOSIcons.add_photo_alternate_outlined,
                              size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: emojiOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final emoji = emojiOptions[i];
                          final isSelected =
                              imagePath == null && selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () => setModalState(() {
                              selectedEmoji = emoji;
                              imagePath = null;
                            }),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.adaptiveIconSurface(ctx)
                                    : (isDark
                                        ? AppTheme.darkSurfaceElevated
                                        : const Color(0xFFF5F5F5)),
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected
                                    ? Border.all(
                                        color: AppTheme.adaptiveIcon(ctx),
                                        width: 2)
                                    : null,
                              ),
                              child: Center(
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 28))),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: s.tr('goalName'),
                  hintText: s.tr('goalNameHint'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: s.tr('descriptionOptional'),
                  hintText: s.tr('savingForHint'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: s.targetAmount,
                  prefixText:
                      '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate ??
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setModalState(() => dueDate = picked);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceElevated
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(ctx).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(IOSIcons.calendar_today_rounded,
                          size: 20, color: AppTheme.adaptiveIcon(ctx)),
                      const SizedBox(width: 12),
                      Text(
                          dueDate != null
                              ? MaterialLocalizations.of(ctx)
                                  .formatMediumDate(dueDate!)
                              : s.tr('setDueDateOptional'),
                          style: TextStyle(
                              color: dueDate != null
                                  ? null
                                  : Theme.of(ctx).textTheme.bodySmall?.color)),
                      const Spacer(),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => dueDate = null),
                          child: Icon(IOSIcons.close_rounded,
                              size: 18, color: AppTheme.adaptiveIcon(ctx)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isEditing) ...[
                TextField(
                  controller: savedCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: s.tr('alreadySaved'),
                    prefixText:
                        '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                AppPickerField<String>(
                  label: s.tr('savedFrom'),
                  value: initialSavedFromAccountId,
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
                          subtitle: cf.format(a.balance),
                          leadingIcon: AppIcons.bank,
                          iconColor: AppTheme.adaptiveIcon(ctx),
                          imagePath: a.imagePath,
                        )),
                  ],
                  onChanged: (v) =>
                      setModalState(() => initialSavedFromAccountId = v),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: hasMonthly
                          ? AppTheme.info.withOpacity(0.4)
                          : Theme.of(ctx).dividerColor),
                  color: hasMonthly ? AppTheme.info.withOpacity(0.04) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(IOSIcons.autorenew_rounded,
                            size: 18, color: AppTheme.adaptiveIcon(ctx)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(s.tr('monthlyAutoSave'),
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600))),
                        Switch(
                          value: hasMonthly,
                          onChanged: (v) => setModalState(() => hasMonthly = v),
                          activeColor: AppTheme.info,
                          activeTrackColor: AppTheme.info.withOpacity(0.3),
                        ),
                      ],
                    ),
                    if (hasMonthly) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: monthlyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: s.monthlyAmount,
                          prefixText:
                              '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPickerField<int>(
                        label: s.paymentDayOfMonth,
                        value: paymentDay,
                        prefixIcon: AppIcons.calendar,
                        items: List.generate(
                            28,
                            (i) => AppPickerItem(
                                value: i + 1, label: '${s.day} ${i + 1}')),
                        onChanged: (v) =>
                            setModalState(() => paymentDay = v ?? 1),
                      ),
                      const SizedBox(height: 12),
                      AppPickerField<String>(
                        label: s.fromAccount,
                        value: paymentSourceAccountId,
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
                                subtitle: cf.format(a.balance),
                                leadingIcon: AppIcons.bank,
                                iconColor: AppTheme.adaptiveIcon(ctx),
                                imagePath: a.imagePath,
                              )),
                        ],
                        onChanged: (v) =>
                            setModalState(() => paymentSourceAccountId = v),
                      ),
                    ],
                  ],
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
                        SnackBar(content: Text(s.tr('pleaseEnterGoalName'))));
                    return;
                  }
                  final target = double.tryParse(targetCtrl.text) ?? 0;
                  if (target <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(s.tr('pleaseEnterValidTargetAmount'))));
                    return;
                  }
                  final saved = double.tryParse(savedCtrl.text) ?? 0;
                  final monthly = hasMonthly
                      ? (double.tryParse(monthlyCtrl.text) ?? 0)
                      : null;

                  if (isEditing) {
                    final updated = existingGoal.copyWith(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      targetAmount: target,
                      targetDate: dueDate?.toIso8601String(),
                      icon: selectedEmoji,
                      imagePath: imagePath,
                      monthlyPayment:
                          monthly != null && monthly > 0 ? monthly : null,
                      paymentDay: hasMonthly ? paymentDay : null,
                      paymentSourceAccountId:
                          hasMonthly ? paymentSourceAccountId : null,
                    );
                    provider.updateGoal(updated);
                    _syncSavingsGoalRule(provider, updated);
                  } else {
                    final newGoal = Goal(
                      id: const Uuid().v4(),
                      type: 'savings',
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      targetAmount: target,
                      currentAmount: 0,
                      targetDate: dueDate?.toIso8601String(),
                      icon: selectedEmoji,
                      imagePath: imagePath,
                      monthlyPayment:
                          monthly != null && monthly > 0 ? monthly : null,
                      paymentDay: hasMonthly ? paymentDay : null,
                      paymentSourceAccountId:
                          hasMonthly ? paymentSourceAccountId : null,
                    );
                    provider.addGoal(newGoal);
                    _syncSavingsGoalRule(provider, newGoal);

                    // Add initial contribution if any
                    if (saved > 0) {
                      provider.contributeToGoalFromSource(
                          newGoal.id,
                          saved,
                          initialSavedFromAccountId ??
                              AppProvider.cashOnHandId);
                    }
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? s.tr('goalUpdated')
                          : s.tr('goalCreated')),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEditing ? s.saveChanges : s.tr('createGoal'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            )),
      ),
    );
  }

  void _syncSavingsGoalRule(AppProvider provider, Goal goal) {
    final ruleId = 'savingsgoal_${goal.id}';
    final existingIdx =
        provider.recurringRules.indexWhere((r) => r.id == ruleId);

    if (goal.monthlyPayment == null ||
        goal.monthlyPayment! <= 0 ||
        goal.paymentSourceAccountId == null) {
      if (existingIdx != -1) {
        provider.deleteRecurringRule(ruleId);
      }
      return;
    }

    final now = DateTime.now();
    int day = goal.paymentDay ?? 1;
    DateTime nextDate = DateTime(now.year, now.month, day);
    if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
      nextDate = DateTime(now.year, now.month + 1, day);
    }

    final rule = RecurringRule(
      id: ruleId,
      frequency: 'monthly',
      nextDate: nextDate.toIso8601String(),
      isActive: true,
      templateTransaction: Transaction(
        id: '',
        type: 'goal_contribution',
        amount: goal.monthlyPayment!,
        date: '',
        note: 'Auto-save: ${goal.name}',
        accountId: goal.paymentSourceAccountId!,
        categoryId: goal.id,
      ),
    );

    if (existingIdx != -1) {
      provider.updateRecurringRule(rule);
    } else {
      provider.addRecurringRule(rule);
    }
  }
}
