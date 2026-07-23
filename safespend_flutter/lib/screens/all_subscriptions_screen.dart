import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_helper.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import '../widgets/storage_image.dart';

class AllSubscriptionsScreen extends StatelessWidget {
  const AllSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cf = CurrencyHelper.formatter(provider.settings.currency);
        final now = DateTime.now();
        final allRules = provider.recurringRules
            .where((r) => r.isActive && DateTime.parse(r.nextDate).isAfter(now))
            .toList()
          ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            shape: BoxShape.circle,
                            boxShadow: isDark ? [] : AppTheme.cardShadowLight,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming Subscriptions',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${allRules.length} active · swipe left to delete',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  child: allRules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.autorenew_rounded, size: 56, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text('No upcoming subscriptions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Add recurring expenses from the + button', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: allRules.length,
                          separatorBuilder: (_, __) => Divider(height: 1, indent: 76, color: Theme.of(context).dividerColor),
                          itemBuilder: (context, index) {
                            final rule = allRules[index];
                            return Slidable(
                              key: Key(rule.id),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                extentRatio: 0.22,
                                children: [
                                  CustomSlidableAction(
                                    onPressed: (_) async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (dCtx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: const Text('Delete Subscription?'),
                                          content: Text('Delete "${rule.templateTransaction.note ?? 'Subscription'}"? This cannot be undone.'),
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
                                      if (confirmed) provider.deleteRecurringRule(rule.id);
                                    },
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      width: 48, height: 48,
                                      decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                                      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _showEditSubscriptionModal(context, provider, rule, cf),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  child: Row(
                                    children: [
                                      Builder(builder: (ctx) {
                                        final cat = rule.templateTransaction.categoryId != null
                                            ? provider.categories.where((c) => c.id == rule.templateTransaction.categoryId).firstOrNull
                                            : null;
                                        final account = provider.accounts.where((a) => a.id == rule.templateTransaction.accountId).firstOrNull;
                                        return Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBackground,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: cat != null && cat.icon.startsWith('img:')
                                                ? _buildImageIcon(cat.icon.substring(4))
                                                : account?.imagePath != null
                                                    ? _buildAccountLogo(account!.imagePath!)
                                                    : cat != null
                                                        ? Icon(_categoryIconData(cat.icon), color: AppTheme.brandPrimary, size: 20)
                                                        : const Icon(Icons.autorenew_rounded, color: AppTheme.brandPrimary, size: 20),
                                          ),
                                        );
                                      }),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rule.templateTransaction.note ?? 'Subscription',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Builder(builder: (ctx) {
                                              final nd = DateTime.parse(rule.nextDate);
                                              final isToday = nd.year == now.year && nd.month == now.month && nd.day == now.day;
                                              final dateStr = isToday ? 'Today · ${DateFormat('h:mm a').format(nd)}' : 'Due ${DateFormat('MMM d').format(nd)}';
                                              return Text(
                                                '$dateStr · ${rule.frequency[0].toUpperCase()}${rule.frequency.substring(1)}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        cf.format(rule.templateTransaction.amount),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandPrimary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.brandPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageIcon(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: 44, height: 44,
          errorBuilder: (_, __, ___) => const Icon(Icons.autorenew_rounded, color: AppTheme.brandPrimary, size: 20));
    }
    return Image.file(File(path), fit: BoxFit.cover, width: 44, height: 44,
        errorBuilder: (_, __, ___) => const Icon(Icons.autorenew_rounded, color: AppTheme.brandPrimary, size: 20));
  }

  Widget _buildAccountLogo(String path) {
    const fallback = Icon(
      Icons.autorenew_rounded,
      color: AppTheme.brandPrimary,
      size: 20,
    );
    return StorageImage(
      stored: path,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      placeholder: fallback,
    );
  }

  IconData _categoryIconData(String iconName) {
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
      case 'autorenew': return Icons.autorenew_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'local_cafe': return Icons.local_cafe_rounded;
      case 'child_care': return Icons.child_care_rounded;
      case 'build': return Icons.build_rounded;
      default: return Icons.autorenew_rounded;
    }
  }

  void _showEditSubscriptionModal(BuildContext context, AppProvider provider, RecurringRule rule, NumberFormat cf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteCtrl = TextEditingController(text: rule.templateTransaction.note ?? '');
    final amountCtrl = TextEditingController(text: rule.templateTransaction.amount.toString());
    String frequency = rule.frequency;
    DateTime nextDate = DateTime.parse(rule.nextDate.substring(0, 10));

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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppTheme.info.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.autorenew_rounded, color: AppTheme.info, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('Edit Subscription', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextField(
                    controller: noteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Subscription Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      prefixIcon: const Icon(Icons.label_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixText: '${CurrencyHelper.getSymbol(provider.settings.currency)} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Frequency
                  Text('Frequency', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: ['weekly', 'monthly', 'yearly'].map((f) {
                      final isActive = frequency == f;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => frequency = f),
                          child: Container(
                            margin: EdgeInsets.only(right: f == 'yearly' ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.info.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? AppTheme.info : Theme.of(ctx).dividerColor, width: 1.5),
                            ),
                            child: Center(child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? AppTheme.info : Theme.of(ctx).textTheme.bodySmall?.color))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Next Date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: nextDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) setModalState(() => nextDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(ctx).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(ctx).textTheme.bodySmall?.color),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Next Due Date', style: Theme.of(ctx).textTheme.bodySmall),
                            Text(DateFormat('MMM d, yyyy').format(nextDate), style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                          return;
                        }
                        final updatedRule = rule.copyWith(
                          frequency: frequency,
                          nextDate: nextDate.toIso8601String().substring(0, 10),
                          templateTransaction: Transaction(
                            id: rule.templateTransaction.id,
                            type: 'expense',
                            amount: amount,
                            date: rule.templateTransaction.date,
                            note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                            categoryId: rule.templateTransaction.categoryId,
                            accountId: rule.templateTransaction.accountId,
                            isRecurring: true,
                            expenseSubType: 'subscription',
                          ),
                        );
                        provider.updateRecurringRule(updatedRule);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subscription updated'), backgroundColor: AppTheme.brandPrimary),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
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
}
