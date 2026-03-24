import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionsSheet extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onWithdrawal;
  final VoidCallback onTransfer;

  const QuickActionsSheet({
    super.key,
    required this.onExpense,
    required this.onIncome,
    required this.onWithdrawal,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              _buildActionButton(
                context,
                'Add Expense',
                Icons.receipt_long_rounded,
                AppTheme.error,
                onExpense,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                'Add Income',
                Icons.arrow_downward_rounded,
                AppTheme.success,
                onIncome,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                'Withdrawal',
                Icons.account_balance_wallet_rounded,
                AppTheme.warning,
                onWithdrawal,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                'Transfer',
                Icons.swap_horiz_rounded,
                AppTheme.info,
                onTransfer,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
