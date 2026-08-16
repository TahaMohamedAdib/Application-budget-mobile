import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Approval gate for an AI-requested change to financial data.
///
/// Nothing mutates until [onConfirm] fires. The card states the effect in
/// plain language rather than echoing tool arguments, so the user approves an
/// outcome they can actually judge.
class AIConfirmationCard extends StatelessWidget {
  const AIConfirmationCard({
    super.key,
    required this.summary,
    required this.onConfirm,
    required this.onCancel,
    this.title = 'Confirm this change',
    this.isResolved = false,
    this.resolvedLabel,
  });

  /// Human-readable description, e.g. "Transfer 1,000.00 MAD\nChecking → Savings".
  final String summary;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String title;

  /// Once acted on, the buttons collapse into a static outcome line so the
  /// transcript stays readable and the action can't be repeated.
  final bool isResolved;
  final String? resolvedLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.adaptiveIcon(context, alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.warning,
                  size: 16, color: AppTheme.adaptiveIcon(context)),
              const SizedBox(width: 8),
              Text(
                isResolved ? (resolvedLabel ?? 'Done') : title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
          ),
          if (!isResolved) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.adaptiveIcon(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: AppTheme.adaptiveIcon(context, alpha: 0.24)),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
