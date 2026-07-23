import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/currency_helper.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../models/category.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final allCategories = provider.categories;
        final totalBudget =
            allCategories.fold(0.0, (sum, c) => sum + c.budgetLimit);
        final totalSpent = allCategories.fold(
            0.0, (sum, c) => sum + provider.getCategorySpending(c.id));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.budgets,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              s.manageBudgets,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen())),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Iconify(
                            AppIcons.settings,
                            size: 24,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                    .slideY(begin: -0.05, end: 0, curve: Curves.easeOut),

                // Overall budget progress (only when categories exist)
                if (allCategories.isNotEmpty && totalBudget > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.goldCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.monthlyBudget,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                '${(totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0).round()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Builder(builder: (ctx) {
                            final rawFmt = NumberFormat('#,##0.##', 'en_US');
                            final symbol = CurrencyHelper.getSymbol(
                                provider.settings.currency);
                            return Text(
                              '${rawFmt.format(totalSpent)} / ${rawFmt.format(totalBudget)} $symbol',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5),
                            );
                          }),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalBudget > 0
                                  ? (totalSpent / totalBudget)
                                      .clamp(0, 1)
                                      .toDouble()
                                  : 0,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: totalSpent > totalBudget
                                  ? AppTheme.error
                                  : Colors.white,
                              minHeight: 7,
                            ),
                          ).animate(onPlay: (c) => c.forward()).shimmer(
                              duration: 1200.ms,
                              delay: 400.ms,
                              color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text(
                            totalSpent > totalBudget
                                ? '${s.overBudgetBy} ${cf.format(totalSpent - totalBudget)}'
                                : '${cf.format(totalBudget - totalSpent)} ${s.remaining}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 80.ms, curve: Curves.easeOut),

                // Empty state
                if (allCategories.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.goldPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Iconify(AppIcons.chartPie,
                                  size: 40, color: AppTheme.goldPrimary),
                            ),
                            const SizedBox(height: 24),
                            Text(s.noBudgetCategories,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                              s.createCategoriesDesc,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showAddCategoryModal(context, provider),
                                icon: const Iconify(AppIcons.add),
                                label: Text(s.createFirstCategory,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.goldPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                      duration: 280.ms, delay: 120.ms, curve: Curves.easeOut),

                // Category list (only when categories exist)
                if (allCategories.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...allCategories.asMap().entries.map((entry) {
                            final cat = entry.value;
                            final spent = provider.getCategorySpending(cat.id);
                            final budget = cat.budgetLimit;
                            final ratio = budget > 0 ? spent / budget : 0.0;
                            Color statusColor;
                            if (spent > budget && budget > 0) {
                              statusColor = AppTheme.error; // Red: over budget
                            } else if (ratio >= 0.95 && budget > 0) {
                              statusColor =
                                  AppTheme.warning; // Orange: at/near limit
                            } else if (budget > 0) {
                              statusColor =
                                  AppTheme.success; // Green: under limit
                            } else {
                              statusColor = Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  Colors.grey;
                            }
                            return Padding(
                              key: Key(cat.id),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () => _showCategoryExpenses(
                                    context, provider, cat, cf),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: spent > budget && budget > 0
                                      ? AppTheme.premiumCard(context).copyWith(
                                          color: Color.lerp(
                                              AppTheme.premiumCard(context)
                                                  .color,
                                              AppTheme.error,
                                              0.06),
                                        )
                                      : AppTheme.premiumCard(context),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: Center(
                                              child: _buildCatIcon(
                                                  cat.icon, statusColor, 44),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(cat.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  budget > 0
                                                      ? '${cf.format(spent)} ${s.of_} ${cf.format(budget)}'
                                                      : s.noLimitSet,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: budget > 0
                                                            ? statusColor
                                                            : null,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (budget > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                spent > budget
                                                    ? '${s.over} ${cf.format(spent - budget)}'
                                                    : cf.format(budget - spent),
                                                style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ] else ...[
                                            const SizedBox(width: 4),
                                            Text(cf.format(spent),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                          ],
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => _showEditCategoryModal(
                                                context, provider, cat, cf),
                                            behavior: HitTestBehavior.opaque,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Iconify(AppIcons.edit,
                                                  size: 20, color: statusColor),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                        context: context,
                                                        builder: (dCtx) =>
                                                            AlertDialog(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                          title: Text(
                                                              '${s.delete} ${s.category}?'),
                                                          content: Text(
                                                              '${s.delete} "${cat.name}"? ${s.cannotBeUndone}.'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      dCtx,
                                                                      false),
                                                              child: Text(
                                                                  s.cancel),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      dCtx,
                                                                      true),
                                                              style: TextButton.styleFrom(
                                                                  foregroundColor:
                                                                      AppTheme
                                                                          .error),
                                                              child: Text(
                                                                  s.delete),
                                                            ),
                                                          ],
                                                        ),
                                                      ) ??
                                                      false;
                                              if (confirmed) {
                                                provider.deleteCategory(cat.id);
                                              }
                                            },
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: AppTheme.error
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: AppTheme.error
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.delete_rounded,
                                                color: AppTheme.error,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (budget > 0) ...[
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: ratio.clamp(0, 1).toDouble(),
                                            backgroundColor: isDark
                                                ? AppTheme.darkBorder
                                                : const Color(0xFFE8ECF1),
                                            color: statusColor,
                                            minHeight: 7,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(
                                duration: 260.ms,
                                delay: (80 + entry.key * 40).ms,
                                curve: Curves.easeOut);
                          }),

                          // Add Category card
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () =>
                                  _showAddCategoryModal(context, provider),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppTheme.goldPrimary.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Iconify(AppIcons.add,
                                        color: AppTheme.goldPrimary, size: 28),
                                    const SizedBox(width: 14),
                                    Text(
                                      s.addCategory,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.goldPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                              duration: 260.ms,
                              delay: (80 + allCategories.length * 40).ms,
                              curve: Curves.easeOut),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatIcon(String iconStr, Color color, double containerSize) {
    if (iconStr.startsWith('img:')) {
      final path = iconStr.substring(4);
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(path),
          width: containerSize,
          height: containerSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Iconify(AppIcons.image, color: color, size: containerSize * 0.45),
        ),
      );
    }
    return Iconify(_categoryIcon(iconStr),
        color: color, size: containerSize * 0.65);
  }

  String _categoryIcon(String iconName) {
    switch (iconName) {
      case 'home':
        return AppIcons.home;
      case 'flash':
        return AppIcons.lightning;
      case 'phone':
        return AppIcons.phone;
      case 'tv':
        return AppIcons.tv;
      case 'shield':
        return AppIcons.shield;
      case 'credit_card':
        return AppIcons.creditCard;
      case 'shopping_cart':
        return AppIcons.cart;
      case 'car':
        return AppIcons.car;
      case 'restaurant':
        return AppIcons.food;
      case 'shopping_bag':
        return AppIcons.shoppingBag;
      case 'favorite':
        return AppIcons.heart;
      case 'sports_esports':
        return AppIcons.gaming;
      case 'face':
        return AppIcons.personal;
      case 'school':
        return AppIcons.education;
      case 'flight':
        return AppIcons.travel;
      case 'card_giftcard':
        return AppIcons.gift;
      case 'pets':
        return AppIcons.pets;
      case 'more_horiz':
        return AppIcons.more;
      case 'autorenew':
        return AppIcons.autoRenew;
      case 'fitness_center':
        return AppIcons.gym;
      case 'local_cafe':
        return AppIcons.coffee;
      case 'child_care':
        return AppIcons.baby;
      case 'build':
        return AppIcons.tools;
      default:
        return AppIcons.categoryIcon;
    }
  }

  void _showCategoryExpenses(BuildContext context, AppProvider provider,
      Category cat, NumberFormat cf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final expenses = provider.transactions.where((t) {
      return t.type == 'expense' &&
          t.categoryId == cat.id &&
          DateTime.parse(t.date)
              .isAfter(startOfMonth.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                  child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Theme.of(ctx).dividerColor,
                          borderRadius: BorderRadius.circular(3)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child:
                            _buildCatIcon(cat.icon, AppTheme.goldPrimary, 44),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            cat.budgetLimit > 0
                                ? '${cf.format(totalSpent)} ${s.of_} ${cf.format(cat.budgetLimit)} ${s.thisMonth}'
                                : '${cf.format(totalSpent)} ${s.spentThisMonth}',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(ctx).dividerColor),
              Flexible(
                child: expenses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Iconify(AppIcons.receipt,
                                size: 48,
                                color:
                                    Theme.of(ctx).textTheme.bodySmall?.color),
                            const SizedBox(height: 16),
                            Text(s.noExpensesYet,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(s.expensesAddedHere,
                                style: Theme.of(ctx).textTheme.bodySmall,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 76,
                            color: Theme.of(ctx).dividerColor),
                        itemBuilder: (ctx, index) {
                          final t = expenses[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Iconify(AppIcons.expense,
                                      color: AppTheme.error, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.note ?? 'Expense',
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                          DateFormat('MMM d, yyyy')
                                              .format(DateTime.parse(t.date)),
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-${cf.format(t.amount)}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.error),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCategoryModal(BuildContext context, AppProvider provider,
      Category cat, NumberFormat cf) {
    final nameCtrl = TextEditingController(text: cat.name);
    final budgetCtrl = TextEditingController(
        text: cat.budgetLimit > 0 ? cat.budgetLimit.toStringAsFixed(0) : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spent = provider.getCategorySpending(cat.id);
    String selectedIcon = cat.icon;

    final iconOptions = <String, String>{
      'home': AppIcons.home,
      'flash': AppIcons.lightning,
      'phone': AppIcons.phone,
      'tv': AppIcons.tv,
      'shield': AppIcons.shield,
      'credit_card': AppIcons.creditCard,
      'shopping_cart': AppIcons.cart,
      'car': AppIcons.car,
      'restaurant': AppIcons.food,
      'shopping_bag': AppIcons.shoppingBag,
      'favorite': AppIcons.heart,
      'sports_esports': AppIcons.gaming,
      'face': AppIcons.personal,
      'school': AppIcons.education,
      'flight': AppIcons.travel,
      'card_giftcard': AppIcons.gift,
      'pets': AppIcons.pets,
      'autorenew': AppIcons.autoRenew,
      'fitness_center': AppIcons.gym,
      'local_cafe': AppIcons.coffee,
      'child_care': AppIcons.baby,
      'build': AppIcons.tools,
    };

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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Theme.of(ctx).dividerColor,
                              borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 20),
                  Text('Edit Category',
                      style: Theme.of(ctx)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Spent this month: ${cf.format(spent)}',
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: selectedIcon.startsWith('img:')
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                    File(selectedIcon.substring(4)),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Iconify(AppIcons.image)),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Iconify(
                                _categoryIcon(selectedIcon),
                                size: 18,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Monthly Spending Limit',
                      hintText: '0.00',
                      prefixText:
                          '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Logo',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(
                          child: selectedIcon.startsWith('img:')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(selectedIcon.substring(4)),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Iconify(AppIcons.image, size: 48),
                                  ),
                                )
                              : Iconify(_categoryIcon(selectedIcon),
                                  size: 48, color: AppTheme.goldPrimary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                                source: ImageSource.gallery, imageQuality: 80);
                            if (image != null)
                              setModalState(
                                  () => selectedIcon = 'img:${image.path}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.goldPrimary.withOpacity(0.3),
                                  width: 1.5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Iconify(AppIcons.image,
                                    size: 18, color: AppTheme.goldPrimary),
                                SizedBox(width: 8),
                                Text('Upload from Gallery',
                                    style: TextStyle(
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
                  const SizedBox(height: 20),
                  Text('Or choose icon',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iconOptions.entries.map((entry) {
                      final isSelected = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.goldPrimary.withOpacity(0.15)
                                : (isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.goldPrimary, width: 2)
                                : null,
                          ),
                          child: Iconify(entry.value,
                              size: 20,
                              color: isSelected
                                  ? AppTheme.goldPrimary
                                  : Theme.of(ctx).textTheme.bodySmall?.color),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Please enter a category name')));
                          return;
                        }
                        final budget = double.tryParse(budgetCtrl.text) ?? 0;
                        if (budget <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Please set a spending limit')));
                          return;
                        }
                        provider.updateCategory(cat.copyWith(
                          name: nameCtrl.text.trim(),
                          icon: selectedIcon,
                          budgetLimit: budget,
                        ));
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
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

  void _showAddCategoryModal(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedIcon = 'category';

    final iconOptions = <String, String>{
      'home': AppIcons.home,
      'flash': AppIcons.lightning,
      'phone': AppIcons.phone,
      'tv': AppIcons.tv,
      'shield': AppIcons.shield,
      'credit_card': AppIcons.creditCard,
      'shopping_cart': AppIcons.cart,
      'car': AppIcons.car,
      'restaurant': AppIcons.food,
      'shopping_bag': AppIcons.shoppingBag,
      'favorite': AppIcons.heart,
      'sports_esports': AppIcons.gaming,
      'face': AppIcons.personal,
      'school': AppIcons.education,
      'flight': AppIcons.travel,
      'card_giftcard': AppIcons.gift,
      'pets': AppIcons.pets,
      'autorenew': AppIcons.autoRenew,
      'fitness_center': AppIcons.gym,
      'local_cafe': AppIcons.coffee,
      'child_care': AppIcons.baby,
      'build': AppIcons.tools,
    };

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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Theme.of(ctx).dividerColor,
                              borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 20),
                  Text('Add Category',
                      style: Theme.of(ctx)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Clothing',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: selectedIcon.startsWith('img:')
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                    File(selectedIcon.substring(4)),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Iconify(AppIcons.image)),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Iconify(
                                _categoryIcon(selectedIcon),
                                size: 18,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monthly Budget Limit',
                      hintText: '0.00',
                      prefixText:
                          '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Logo',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(
                          child: selectedIcon.startsWith('img:')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(selectedIcon.substring(4)),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Iconify(AppIcons.image, size: 48),
                                  ),
                                )
                              : Iconify(_categoryIcon(selectedIcon),
                                  size: 48, color: AppTheme.goldPrimary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                                source: ImageSource.gallery, imageQuality: 80);
                            if (image != null)
                              setModalState(
                                  () => selectedIcon = 'img:${image.path}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurfaceElevated
                                  : AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.goldPrimary.withOpacity(0.3),
                                  width: 1.5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Iconify(AppIcons.image,
                                    size: 18, color: AppTheme.goldPrimary),
                                SizedBox(width: 8),
                                Text('Upload from Gallery',
                                    style: TextStyle(
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
                  const SizedBox(height: 20),
                  Text('Or choose icon',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iconOptions.entries.map((entry) {
                      final isSelected = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.goldPrimary.withOpacity(0.15)
                                : (isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.goldPrimary, width: 2)
                                : null,
                          ),
                          child: Iconify(entry.value,
                              size: 20,
                              color: isSelected
                                  ? AppTheme.goldPrimary
                                  : Theme.of(ctx).textTheme.bodySmall?.color),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Please enter a category name')));
                          return;
                        }
                        final budget = double.tryParse(budgetCtrl.text) ?? 0;
                        if (budget <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Please set a spending limit')));
                          return;
                        }
                        final newCat = Category(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          group: 'variable',
                          icon: selectedIcon,
                          color: '#B8860B',
                          budgetLimit: budget,
                        );
                        provider.addCategory(newCat);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text('"${newCat.name}" added'),
                              backgroundColor: AppTheme.goldPrimary),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Add Category',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
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
