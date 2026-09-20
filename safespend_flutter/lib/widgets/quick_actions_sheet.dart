import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';

import '../l10n/app_localizations.dart';
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
    final s = S.of(context);

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
                s.addTransaction,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              _buildActionButton(
                context,
                s.addExpense,
                IOSIcons.receipt_long_rounded,
                AppTheme.expenseIcon,
                onExpense,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                s.addIncome,
                IOSIcons.arrow_downward_rounded,
                AppTheme.incomeIcon,
                onIncome,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                s.withdrawal,
                IOSIcons.account_balance_wallet_rounded,
                AppTheme.withdrawalIcon,
                onWithdrawal,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                s.transfer,
                IOSIcons.swap_horiz_rounded,
                AppTheme.transferIcon,
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

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252728) : const Color(0xFFF0F1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                  ),
                ),
                Icon(
                  IOSIcons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.adaptiveIcon(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact panel shown above the global navigation bar when the add button is
/// expanded. Keeping the action list in one widget makes the global add menu
/// and its callback contract independently testable.
class QuickActionsPanel extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onWithdrawal;
  final VoidCallback onTransfer;

  const QuickActionsPanel({
    super.key,
    required this.onExpense,
    required this.onIncome,
    required this.onWithdrawal,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final actions = <({
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
    })>[
      (
        label: s.expense,
        icon: IOSIcons.arrow_upward_rounded,
        color: AppTheme.expenseIcon,
        onTap: onExpense,
      ),
      (
        label: s.incomeLabel,
        icon: IOSIcons.arrow_downward_rounded,
        color: AppTheme.incomeIcon,
        onTap: onIncome,
      ),
      (
        label: s.withdraw,
        icon: IOSIcons.account_balance_wallet_rounded,
        color: AppTheme.withdrawalIcon,
        onTap: onWithdrawal,
      ),
      (
        label: s.transfer,
        icon: IOSIcons.swap_horiz_rounded,
        color: AppTheme.transferIcon,
        onTap: onTransfer,
      ),
    ];

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.16),
              blurRadius: 34,
              spreadRadius: -8,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              width: 254,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF242427).withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.74),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.14),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.82),
                          Colors.white.withValues(alpha: 0.42),
                          Colors.white.withValues(alpha: 0.24),
                        ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < actions.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == actions.length - 1 ? 0 : 6,
                      ),
                      child: _CompactQuickActionRow(
                        label: actions[index].label,
                        icon: actions[index].icon,
                        color: actions[index].color,
                        isDark: isDark,
                        onTap: actions[index].onTap,
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

class _CompactQuickActionRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _CompactQuickActionRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CompactQuickActionRow> createState() => _CompactQuickActionRowState();
}

class _CompactQuickActionRowState extends State<_CompactQuickActionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1C1C1E);
    final rowBackground = widget.isDark
        ? Colors.white.withValues(alpha: _pressed ? 0.12 : 0.055)
        : Colors.white.withValues(alpha: _pressed ? 0.72 : 0.44);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: rowBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.48),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
