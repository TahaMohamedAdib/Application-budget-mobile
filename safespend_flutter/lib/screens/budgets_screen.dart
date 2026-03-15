import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/currency_helper.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/category.dart';
import 'settings_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final allCategories = provider.categories;
        final totalBudget = allCategories.fold(0.0, (sum, c) => sum + c.budgetLimit);
        final totalSpent = allCategories.fold(0.0, (sum, c) => sum + provider.getCategorySpending(c.id));

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
                            Text('Budgets', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              allCategories.isEmpty
                                  ? 'Create categories to manage spending'
                                  : 'Spent ${cf.format(totalSpent)} of ${cf.format(totalBudget)} this month',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: const Icon(Icons.settings_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

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
                              Text('Monthly Budget', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                '${(totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0).round()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${cf.format(totalSpent)} / ${cf.format(totalBudget)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1).toDouble() : 0,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: totalSpent > totalBudget ? AppTheme.error : Colors.white,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalSpent > totalBudget
                                ? 'Over budget by ${cf.format(totalSpent - totalBudget)}'
                                : '${cf.format(totalBudget - totalSpent)} remaining',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

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
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.goldPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.pie_chart_rounded, size: 40, color: AppTheme.goldPrimary),
                            ),
                            const SizedBox(height: 24),
                            Text('No budget categories yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                              'Create categories to track your spending.\nSet a limit for each to stay on budget.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddCategoryModal(context, provider),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Your First Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.goldPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

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
                            statusColor = AppTheme.warning; // Orange: at/near limit
                          } else if (budget > 0) {
                            statusColor = AppTheme.success; // Green: under limit
                          } else {
                            statusColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => _showCategoryExpenses(context, provider, cat, cf),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.premiumCard(context),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42, height: 42,
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(_categoryIcon(cat.icon), color: statusColor, size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cat.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                budget > 0 ? '${cf.format(spent)} of ${cf.format(budget)}' : 'No limit set',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: budget > 0 ? statusColor : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (budget > 0) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              spent > budget ? '+${cf.format(spent - budget)}' : cf.format(budget - spent),
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(width: 4),
                                          Text(cf.format(spent), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                        ],
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _showEditCategoryModal(context, provider, cat, cf),
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 34, height: 34,
                                            decoration: BoxDecoration(
                                              color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(Icons.edit_rounded, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (budget > 0) ...[
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: ratio.clamp(0, 1).toDouble(),
                                          backgroundColor: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                                          color: statusColor,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: (150 + entry.key * 60).ms);
                        }),

                        // Add Category card
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _showAddCategoryModal(context, provider),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.goldPrimary.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldPrimary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.add_rounded, color: AppTheme.goldPrimary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    'Add Category',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.goldPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: (150 + allCategories.length * 60).ms),
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

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home_rounded;
      case 'flash': return Icons.flash_on_rounded;
      case 'phone': return Icons.phone_android_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      case 'face': return Icons.face_rounded;
      case 'school': return Icons.school_rounded;
      case 'flight': return Icons.flight_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'pets': return Icons.pets_rounded;
      case 'more_horiz': return Icons.more_horiz_rounded;
      case 'autorenew': return Icons.autorenew_rounded;
      default: return Icons.category_rounded;
    }
  }

  void _showCategoryExpenses(BuildContext context, AppProvider provider, Category cat, NumberFormat cf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final expenses = provider.transactions.where((t) {
      return t.type == 'expense' &&
          t.categoryId == cat.id &&
          DateTime.parse(t.date).isAfter(startOfMonth.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon(cat.icon), color: AppTheme.goldPrimary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            cat.budgetLimit > 0
                                ? '${cf.format(totalSpent)} of ${cf.format(cat.budgetLimit)} this month'
                                : '${cf.format(totalSpent)} spent this month',
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
                            Icon(Icons.receipt_long_rounded, size: 48, color: Theme.of(ctx).textTheme.bodySmall?.color),
                            const SizedBox(height: 16),
                            Text('No expenses yet', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Expenses added to this category will show here', style: Theme.of(ctx).textTheme.bodySmall, textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => Divider(height: 1, indent: 76, color: Theme.of(ctx).dividerColor),
                        itemBuilder: (ctx, index) {
                          final t = expenses[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.error, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.note ?? 'Expense', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(DateFormat('MMM d, yyyy').format(DateTime.parse(t.date)), style: Theme.of(ctx).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-${cf.format(t.amount)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.error),
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

  void _showEditCategoryModal(BuildContext context, AppProvider provider, Category cat, NumberFormat cf) {
    final nameCtrl = TextEditingController(text: cat.name);
    final budgetCtrl = TextEditingController(text: cat.budgetLimit > 0 ? cat.budgetLimit.toStringAsFixed(0) : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spent = provider.getCategorySpending(cat.id);
    String selectedIcon = cat.icon;

    final iconOptions = <String, IconData>{
      'home': Icons.home_rounded,
      'flash': Icons.flash_on_rounded,
      'phone': Icons.phone_android_rounded,
      'tv': Icons.tv_rounded,
      'shield': Icons.shield_rounded,
      'credit_card': Icons.credit_card_rounded,
      'shopping_cart': Icons.shopping_cart_rounded,
      'car': Icons.directions_car_rounded,
      'restaurant': Icons.restaurant_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'favorite': Icons.favorite_rounded,
      'sports_esports': Icons.sports_esports_rounded,
      'face': Icons.face_rounded,
      'school': Icons.school_rounded,
      'flight': Icons.flight_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'pets': Icons.pets_rounded,
      'autorenew': Icons.autorenew_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'local_cafe': Icons.local_cafe_rounded,
      'child_care': Icons.child_care_rounded,
      'build': Icons.build_rounded,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Category', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Delete Category?'),
                              content: Text('Are you sure you want to delete "${cat.name}"? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dCtx);
                                    Navigator.pop(ctx);
                                    provider.deleteCategory(cat.id);
                                  },
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Spent this month: ${cf.format(spent)}', style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: Icon(_categoryIcon(selectedIcon)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Monthly Spending Limit',
                      hintText: '0.00',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Icon', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iconOptions.entries.map((entry) {
                      final isSelected = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.goldPrimary.withOpacity(0.15) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: AppTheme.goldPrimary, width: 2) : null,
                          ),
                          child: Icon(entry.value, size: 20, color: isSelected ? AppTheme.goldPrimary : Theme.of(ctx).textTheme.bodySmall?.color),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a category name')));
                          return;
                        }
                        final budget = double.tryParse(budgetCtrl.text) ?? 0;
                        if (budget <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please set a spending limit')));
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

  void _showAddCategoryModal(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedIcon = 'category';

    final iconOptions = <String, IconData>{
      'home': Icons.home_rounded,
      'flash': Icons.flash_on_rounded,
      'phone': Icons.phone_android_rounded,
      'tv': Icons.tv_rounded,
      'shield': Icons.shield_rounded,
      'credit_card': Icons.credit_card_rounded,
      'shopping_cart': Icons.shopping_cart_rounded,
      'car': Icons.directions_car_rounded,
      'restaurant': Icons.restaurant_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'favorite': Icons.favorite_rounded,
      'sports_esports': Icons.sports_esports_rounded,
      'face': Icons.face_rounded,
      'school': Icons.school_rounded,
      'flight': Icons.flight_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'pets': Icons.pets_rounded,
      'autorenew': Icons.autorenew_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'local_cafe': Icons.local_cafe_rounded,
      'child_care': Icons.child_care_rounded,
      'build': Icons.build_rounded,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Add Category', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Clothing',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: Icon(_categoryIcon(selectedIcon)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Monthly Budget Limit',
                      hintText: '0.00',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Choose Icon', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iconOptions.entries.map((entry) {
                      final isSelected = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.goldPrimary.withOpacity(0.15) : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: AppTheme.goldPrimary, width: 2) : null,
                          ),
                          child: Icon(entry.value, size: 20, color: isSelected ? AppTheme.goldPrimary : Theme.of(ctx).textTheme.bodySmall?.color),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a category name')));
                          return;
                        }
                        final budget = double.tryParse(budgetCtrl.text) ?? 0;
                        if (budget <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please set a spending limit')));
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
                          SnackBar(content: Text('"${newCat.name}" added'), backgroundColor: AppTheme.goldPrimary),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
