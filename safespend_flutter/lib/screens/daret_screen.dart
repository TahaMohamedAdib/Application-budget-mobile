import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/currency_helper.dart';
import '../models/daret.dart';
import '../widgets/app_form_sheet.dart';
import '../widgets/app_picker_field.dart';
import '../widgets/wealth_ui.dart';
import '../l10n/app_localizations.dart';

class DaretScreen extends StatefulWidget {
  const DaretScreen({super.key});

  @override
  State<DaretScreen> createState() => _DaretScreenState();
}

class _DaretScreenState extends State<DaretScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final activeDarets = provider.darets.where((d) => d.isActive).toList();
        final completedDarets =
            provider.darets.where((d) => !d.isActive || d.isComplete).toList();
        final totalLiability = provider.totalDaretLiability;

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
                      title: s.savingsCircle,
                      subtitle: 'Plan contributions and payouts',
                      onBack: () => Navigator.pop(context),
                      onAdd: () => _showAddDaretModal(context, provider),
                      addTooltip: 'Add savings circle',
                    ),
                  ).animate().fadeIn(duration: 260.ms),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: WealthOverviewCard(
                      icon: IOSIcons.wealthSavingsCircle,
                      label: s.remaining,
                      amount: cf.format(totalLiability),
                      amountColor:
                          totalLiability > 0 ? AppTheme.expenseIcon : null,
                      firstLabel: s.activeDarets,
                      firstValue: '${activeDarets.length}',
                      secondLabel: s.completedUppercase,
                      secondValue: '${completedDarets.length}',
                    ).animate().fadeIn(duration: 280.ms, delay: 60.ms),
                  ),
                ),
                if (activeDarets.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: WealthSectionHeader(
                        title: s.activeUppercase,
                        count: '${activeDarets.length}',
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final daret = activeDarets[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _buildDaretCard(
                            context, daret, provider, cf, isDark),
                      ).animate().fadeIn(
                          duration: 280.ms, delay: (80 + index * 40).ms);
                    },
                    childCount: activeDarets.length,
                  ),
                ),
                if (completedDarets.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: WealthSectionHeader(
                        title: s.completedUppercase,
                        count: '${completedDarets.length}',
                      ),
                    ),
                  ),
                if (completedDarets.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final daret = completedDarets[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _buildDaretCard(
                              context, daret, provider, cf, isDark),
                        );
                      },
                      childCount: completedDarets.length,
                    ),
                  ),
                if (provider.darets.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(IOSIcons.groups_rounded,
                              size: 64,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(s.noDaretsYet,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(s.tapToCreateDaret,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center),
                        ],
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

  Widget _buildDaretCard(BuildContext context, Daret daret,
      AppProvider provider, NumberFormat cf, bool isDark) {
    final s = S.of(context);
    return GestureDetector(
      onTap: () => _showDaretDetail(context, daret, provider, cf, isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: wealthGlassDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                      child: Text('🤝', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(daret.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                          '${daret.totalShares} ${s.people} · ${daret.userShares} ${daret.userShares > 1 ? s.shares : s.share}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(cf.format(daret.monthlyPayment),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.expenseIcon)),
                    Text(s.perMonth,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: daret.progress,
                backgroundColor:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.adaptiveIcon(context)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    s.monthOf
                        .replaceAll('{current}', '${daret.currentMonth}')
                        .replaceAll('{total}', '${daret.totalShares}'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                if (daret.nextPayoutMonth > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.incomeIcon.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                        s.payoutMonth
                            .replaceAll('{month}', '${daret.nextPayoutMonth}'),
                        style: const TextStyle(
                            color: AppTheme.incomeIcon,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(s.allPayoutsReceived,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDaretDetail(BuildContext context, Daret daret, AppProvider provider,
      NumberFormat cf, bool isDark) {
    final s = S.of(context);
    final sourceAccount = daret.paymentSourceId == AppProvider.cashOnHandId
        ? null
        : provider.accounts
            .where((a) => a.id == daret.paymentSourceId)
            .firstOrNull;
    final destAccount = daret.destinationAccountId == AppProvider.cashOnHandId
        ? null
        : provider.accounts
            .where((a) => a.id == daret.destinationAccountId)
            .firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
                child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor,
                        borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.adaptiveIconSurface(ctx),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                            child: Text('🤝', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(daret.name,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                                '${daret.totalShares} ${s.people} · ${daret.userShares} ${daret.userShares > 1 ? s.shares : s.share}',
                                style: Theme.of(ctx).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: wealthGlassDecoration(ctx),
                    child: Column(
                      children: [
                        _detailRow(ctx, s, s.contributionPerShare,
                            cf.format(daret.contributionPerShare)),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.monthlyPayment,
                            cf.format(daret.monthlyPayment),
                            valueColor: AppTheme.expenseIcon),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.singlePayout,
                            cf.format(daret.singlePayoutAmount),
                            valueColor: AppTheme.incomeIcon),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.totalCyclePayout,
                            cf.format(daret.totalCyclePayout),
                            valueColor: AppTheme.incomeIcon),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.totalPaidSoFar,
                            cf.format(daret.totalPaidSoFar),
                            valueColor: AppTheme.expenseIcon),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.totalReceivedSoFar,
                            cf.format(daret.totalReceivedSoFar),
                            valueColor: AppTheme.incomeIcon),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.remainingLiability,
                            cf.format(daret.remainingLiability),
                            valueColor: AppTheme.expenseIcon),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: wealthGlassDecoration(ctx),
                    child: Column(
                      children: [
                        _detailRow(ctx, s, s.sourceAccount,
                            sourceAccount?.name ?? s.cashOnHand),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.payoutTo,
                            destAccount?.name ?? s.cashOnHand),
                        const SizedBox(height: 12),
                        _detailRow(ctx, s, s.paymentDay,
                            '${daret.paymentDay}${_daySuffix(daret.paymentDay)} ${s.payoutDayOfEachMonth}'),
                        const SizedBox(height: 12),
                        _detailRow(
                            ctx,
                            s,
                            s.startDate,
                            DateFormat.yMMMd()
                                .format(DateTime.parse(daret.startDate))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(s.payoutTimeline,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: wealthGlassDecoration(ctx),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(daret.totalShares, (i) {
                        final month = i + 1;
                        final isPayout = daret.payoutMonths.contains(month);
                        final isCurrent = month == daret.currentMonth;
                        final isPast = month < daret.currentMonth;
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isPayout
                                ? (isPast
                                    ? AppTheme.incomeIcon
                                    : AppTheme.incomeIcon
                                        .withValues(alpha: 0.15))
                                : isCurrent
                                    ? AppTheme.adaptiveIconSurface(ctx)
                                    : isPast
                                        ? (isDark
                                            ? Colors.white10
                                            : Colors.black.withOpacity(0.05))
                                        : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? AppTheme.adaptiveIcon(ctx)
                                  : (isPayout
                                      ? AppTheme.incomeIcon
                                          .withValues(alpha: 0.3)
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.black.withOpacity(0.08))),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text('$month',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: (isPayout || isCurrent)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isPayout
                                      ? (isPast
                                          ? Colors.white
                                          : AppTheme.incomeIcon)
                                      : isCurrent
                                          ? AppTheme.adaptiveIcon(ctx)
                                          : Theme.of(ctx)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                )),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _legendDot(s, AppTheme.incomeIcon, s.payoutMonth),
                      const SizedBox(width: 16),
                      _legendDot(
                          s, AppTheme.adaptiveIcon(ctx), s.currentMonthLabel),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditDaretModal(context, daret, provider);
                          },
                          icon: const Icon(IOSIcons.edit_rounded, size: 18),
                          label: Text(s.edit),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Theme.of(ctx).dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDelete(context, daret, provider);
                          },
                          icon: Icon(IOSIcons.delete_rounded,
                              size: 18, color: AppTheme.adaptiveIcon(ctx)),
                          label: Text(s.delete,
                              style: TextStyle(color: AppTheme.error)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: AppTheme.error.withOpacity(0.3)),
                          ),
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
    );
  }

  Widget _detailRow(BuildContext ctx, S s, String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(ctx).textTheme.bodySmall),
        Text(value,
            style: Theme.of(ctx)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  Widget _legendDot(S s, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _confirmDelete(BuildContext context, Daret daret, AppProvider provider) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteDaret,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(s.deleteDaretConfirm.replaceAll('{name}', daret.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              provider.deleteDaret(daret.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  void _showAddDaretModal(BuildContext context, AppProvider provider) {
    _showDaretFormModal(context, provider, null);
  }

  void _showEditDaretModal(
      BuildContext context, Daret daret, AppProvider provider) {
    _showDaretFormModal(context, provider, daret);
  }

  void _showDaretFormModal(
      BuildContext context, AppProvider provider, Daret? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DaretFormSheet(provider: provider, existing: existing),
    );
  }
}

class _DaretFormSheet extends StatefulWidget {
  final AppProvider provider;
  final Daret? existing;
  const _DaretFormSheet({required this.provider, this.existing});

  @override
  State<_DaretFormSheet> createState() => _DaretFormSheetState();
}

class _DaretFormSheetState extends State<_DaretFormSheet> {
  final _nameController = TextEditingController();
  final _contributionController = TextEditingController();
  final _totalSharesController = TextEditingController();

  int _userShares = 1;
  List<int?> _payoutMonths = [null];
  String? _paymentSourceId;
  String? _destinationAccountId;
  int _paymentDay = 1;
  DateTime _startDate = DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!;
      _nameController.text = d.name;
      _contributionController.text = d.contributionPerShare.toStringAsFixed(
          d.contributionPerShare.truncateToDouble() == d.contributionPerShare
              ? 0
              : 2);
      _totalSharesController.text = d.totalShares.toString();
      _userShares = d.userShares;
      _payoutMonths = d.payoutMonths.map<int?>((e) => e).toList();
      _paymentSourceId = d.paymentSourceId;
      _destinationAccountId = d.destinationAccountId;
      _paymentDay = d.paymentDay;
      _startDate = DateTime.parse(d.startDate);
    } else {
      _paymentSourceId = widget.provider.accounts.isNotEmpty
          ? widget.provider.accounts.first.id
          : AppProvider.cashOnHandId;
      _destinationAccountId = widget.provider.accounts.isNotEmpty
          ? widget.provider.accounts.first.id
          : AppProvider.cashOnHandId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contributionController.dispose();
    _totalSharesController.dispose();
    super.dispose();
  }

  int get _totalShares => int.tryParse(_totalSharesController.text) ?? 0;
  double get _contribution =>
      double.tryParse(_contributionController.text) ?? 0;

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    if (_contribution <= 0 || _totalShares <= 0) return;
    final validPayouts = _payoutMonths.whereType<int>().toList();
    if (validPayouts.length != _userShares) return;

    final daret = Daret(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      contributionPerShare: _contribution,
      totalShares: _totalShares,
      userShares: _userShares,
      payoutMonths: validPayouts,
      startDate: _startDate.toIso8601String(),
      paymentSourceId: _paymentSourceId ?? AppProvider.cashOnHandId,
      destinationAccountId: _destinationAccountId ?? AppProvider.cashOnHandId,
      paymentDay: _paymentDay,
    );

    if (_isEditing) {
      widget.provider.updateDaret(daret);
    } else {
      widget.provider.addDaret(daret);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final cf = CurrencyHelper.formatter(widget.provider.settings.currency);
    final accounts = widget.provider.accounts;

    return AppFormSheet(
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const AppFormSheetHandle(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppFormSheetHeader(
                title: _isEditing ? s.editDaret : s.newDaret,
                icon: IOSIcons.wealthSavingsCircle,
                accent: AppTheme.adaptiveIcon(context),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  _label(s, s.name),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration(isDark, s.contributionHint),
                  ),
                  const SizedBox(height: 20),
                  _label(s, s.contributionPerShare),
                  TextField(
                    controller: _contributionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        _inputDecoration(isDark, s.contributionAmountHint),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _label(s, s.totalShares),
                  TextField(
                    controller: _totalSharesController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(isDark, s.totalSharesHint),
                    onChanged: (_) {
                      setState(() {
                        for (int i = 0; i < _payoutMonths.length; i++) {
                          if (_payoutMonths[i] != null &&
                              _payoutMonths[i]! > _totalShares) {
                            _payoutMonths[i] = null;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _label(s, s.yourShares),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceElevated
                          : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(s.howManySlots,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        IconButton(
                          onPressed: _userShares > 1
                              ? () => setState(() {
                                    _userShares--;
                                    if (_payoutMonths.length > _userShares) {
                                      _payoutMonths =
                                          _payoutMonths.sublist(0, _userShares);
                                    }
                                  })
                              : null,
                          icon: Icon(IOSIcons.remove_circle_rounded,
                              color: AppTheme.adaptiveIcon(context,
                                  alpha: _userShares > 1 ? 1 : 0.35)),
                        ),
                        Text('$_userShares',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(
                          onPressed: _userShares <
                                  (_totalShares > 0 ? _totalShares : 10)
                              ? () => setState(() {
                                    _userShares++;
                                    if (_payoutMonths.length < _userShares) {
                                      _payoutMonths.add(null);
                                    }
                                  })
                              : null,
                          icon: Icon(IOSIcons.add_circle_rounded,
                              color: AppTheme.adaptiveIcon(context,
                                  alpha: _userShares <
                                          (_totalShares > 0 ? _totalShares : 10)
                                      ? 1
                                      : 0.35)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(s, s.payoutMonths),
                  ...List.generate(_userShares, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPayoutMonthSelector(isDark, i, s),
                    );
                  }),
                  const SizedBox(height: 8),
                  _label(s, s.paymentDayOfMonth),
                  _buildDaySelector(isDark),
                  const SizedBox(height: 20),
                  _label(s, s.startDate),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceElevated
                            : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(IOSIcons.calendar_today_rounded,
                              size: 18, color: AppTheme.adaptiveIcon(context)),
                          const SizedBox(width: 12),
                          Text(DateFormat.yMMMd().format(_startDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Icon(IOSIcons.chevron_right_rounded,
                              size: 20, color: AppTheme.adaptiveIcon(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(s, s.sourceAccount),
                  AppPickerField(
                    label: s.sourceAccount,
                    value: _paymentSourceId,
                    items: [
                      AppPickerItem(
                          value: AppProvider.cashOnHandId,
                          label: s.cashOnHand,
                          leadingIcon: 'IOSIcons.money_rounded',
                          iconColor: AppTheme.cashOnHandIcon),
                      ...accounts.map((a) => AppPickerItem(
                            value: a.id,
                            label: a.name,
                            leadingIcon: _iconForAccountType(a.type),
                            imagePath: a.imagePath,
                          )),
                    ],
                    onChanged: (v) => setState(() => _paymentSourceId = v),
                  ),
                  const SizedBox(height: 20),
                  _label(s, s.destinationAccount),
                  AppPickerField(
                    label: s.destinationAccount,
                    value: _destinationAccountId,
                    items: [
                      AppPickerItem(
                          value: AppProvider.cashOnHandId,
                          label: s.cashOnHand,
                          leadingIcon: 'IOSIcons.money_rounded',
                          iconColor: AppTheme.cashOnHandIcon),
                      ...accounts.map((a) => AppPickerItem(
                            value: a.id,
                            label: a.name,
                            leadingIcon: _iconForAccountType(a.type),
                            imagePath: a.imagePath,
                          )),
                    ],
                    onChanged: (v) => setState(() => _destinationAccountId = v),
                  ),
                  const SizedBox(height: 24),
                  if (_contribution > 0 && _totalShares > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(s.summary,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: wealthGlassDecoration(context, radius: 18),
                      child: Column(
                        children: [
                          _summaryRow(s.monthlyPayment,
                              cf.format(_contribution * _userShares),
                              valueColor: AppTheme.expenseIcon),
                          const SizedBox(height: 8),
                          _summaryRow(s.singlePayout,
                              cf.format(_contribution * _totalShares),
                              valueColor: AppTheme.incomeIcon),
                          const SizedBox(height: 8),
                          _summaryRow(
                              s.totalCyclePayout,
                              cf.format(
                                  _contribution * _totalShares * _userShares),
                              valueColor: AppTheme.incomeIcon),
                          const SizedBox(height: 8),
                          _summaryRow(
                              s.remainingLiability,
                              cf.format(
                                  (_totalShares * _contribution * _userShares)
                                      .abs()),
                              valueColor: AppTheme.expenseIcon),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton(
                    onPressed: _canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_isEditing ? s.saveChanges : s.createDaret,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) return false;
    if (_contribution <= 0 || _totalShares <= 0) return false;
    final validPayouts = _payoutMonths.whereType<int>().toList();
    if (validPayouts.length != _userShares) return false;
    if (validPayouts.toSet().length != validPayouts.length) return false;
    return true;
  }

  Widget _label(S s, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDecoration(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      filled: true,
      fillColor:
          isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPayoutMonthSelector(bool isDark, int index, S s) {
    final selected = index < _payoutMonths.length ? _payoutMonths[index] : null;
    final takenMonths = _payoutMonths.whereType<int>().toSet();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<int>(
              value: selected,
              hint: Text(s.selectPayoutMonth,
                  style: Theme.of(context).textTheme.bodySmall),
              isExpanded: true,
              underline: const SizedBox(),
              items: _totalShares > 0
                  ? List.generate(_totalShares, (i) {
                      final month = i + 1;
                      final isTaken =
                          takenMonths.contains(month) && month != selected;
                      return DropdownMenuItem<int>(
                        value: month,
                        enabled: !isTaken,
                        child: Text('${s.month} $month',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isTaken ? Colors.grey : null,
                            )),
                      );
                    })
                  : [],
              onChanged: (v) {
                setState(() {
                  if (index < _payoutMonths.length) {
                    _payoutMonths[index] = v;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _paymentDay,
        isExpanded: true,
        underline: const SizedBox(),
        items: List.generate(28, (i) {
          final day = i + 1;
          return DropdownMenuItem<int>(
              value: day, child: Text('$day${_daySuffix(day)}'));
        }),
        onChanged: (v) => setState(() => _paymentDay = v ?? 1),
      ),
    );
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: valueColor)),
      ],
    );
  }

  String _iconForAccountType(String type) {
    // These must be AppIcons constants — AppIcon() resolves them by identity,
    // so a bare name string falls through to a blank circle.
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
}
