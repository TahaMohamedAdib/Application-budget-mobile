import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/money_format.dart';
import 'money_amount.dart';
import '../theme/ios_icons.dart';
import '../l10n/app_localizations.dart';
import 'feature_help_button.dart';

Color _withAlpha(Color color, double alpha) => color.withValues(alpha: alpha);

BoxDecoration wealthGlassDecoration(BuildContext context,
    {double radius = 24}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark
        ? _withAlpha(const Color(0xFF242627), 0.94)
        : _withAlpha(const Color(0xFFF0F1F3), 0.92),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: isDark
          ? _withAlpha(Colors.white, 0.10)
          : _withAlpha(Colors.black, 0.075),
    ),
    boxShadow: [
      BoxShadow(
        color: _withAlpha(Colors.black, isDark ? 0.22 : 0.08),
        blurRadius: 24,
        spreadRadius: -10,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class WealthPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final String addTooltip;

  const WealthPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onAdd,
    required this.addTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderButton(
          icon: IOSIcons.arrow_back_rounded,
          tooltip: S.of(context).back,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FeatureHelpButton(title: title, description: subtitle),
        const SizedBox(width: 8),
        _HeaderButton(
          icon: IOSIcons.add_rounded,
          tooltip: addTooltip,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 44,
            height: 44,
            decoration: wealthGlassDecoration(context, radius: 22),
            child: Icon(icon, size: 21, color: AppTheme.adaptiveIcon(context)),
          ),
        ),
      ),
    );
  }
}

class WealthOverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;

  /// The hero figure, as a number rather than preformatted text. The card
  /// fits it to the available width, which it cannot do to a finished string.
  final num amountValue;

  /// Formatter for [amountValue]. The metric slots below stay strings because
  /// several callers put a plain count there, not money.
  final MoneyFormat formatter;

  final Color? amountColor;
  final String firstLabel;
  final String firstValue;
  final Color? firstValueColor;
  final String secondLabel;
  final String secondValue;
  final Color? secondValueColor;
  final double? progress;
  final String? progressLabel;

  const WealthOverviewCard({
    super.key,
    required this.icon,
    required this.label,
    required this.amountValue,
    required this.formatter,
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
    this.amountColor,
    this.firstValueColor,
    this.secondValueColor,
    this.progress,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final normalizedProgress = progress?.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: wealthGlassDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  WealthIconTile(icon: icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              MoneyAmount(
                value: amountValue,
                formatter: formatter,
                fontSize: 34,
                minFontSize: 22,
                currencyInline: true,
                color: amountColor ?? textColor,
              ),
              if (normalizedProgress != null) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: normalizedProgress,
                    minHeight: 7,
                    color: AppTheme.adaptiveIcon(context),
                    backgroundColor: AppTheme.adaptiveIconSurface(context),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(height: 7),
                  Text(progressLabel!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
              const SizedBox(height: 18),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _OverviewMetric(
                      label: firstLabel,
                      value: firstValue,
                      valueColor: firstValueColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OverviewMetric(
                      label: secondLabel,
                      value: secondValue,
                      valueColor: secondValueColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _OverviewMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        // A string, not a number: callers put plain counts here as well as
        // money, so this slot only guarantees it will fit on one line.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class WealthIconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const WealthIconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.adaptiveIcon(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.adaptiveIconSurface(context),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: size * 0.48, color: iconColor),
    );
  }
}

class WealthSectionHeader extends StatelessWidget {
  final String title;
  final String? count;

  const WealthSectionHeader({super.key, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.adaptiveIconSurface(context),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(count!, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
