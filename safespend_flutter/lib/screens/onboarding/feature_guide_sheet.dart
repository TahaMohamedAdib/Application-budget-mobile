import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import 'app_tour_screen.dart';

/// Presents a concise, one-time guide when a user first opens a major feature.
Future<void> showAppFeatureGuideSheet(
  BuildContext context,
  AppGuideFeature feature,
) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: (_) => _FeatureGuideSheet(feature: feature),
  );
}

class _FeatureGuideSheet extends StatelessWidget {
  const _FeatureGuideSheet({required this.feature});

  final AppGuideFeature feature;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = _title(s);
    final body = _body(s);
    final accent = _accent;
    final shape = RoundedSuperellipseBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      side: BorderSide(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.07),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.48 : 0.20),
              blurRadius: 40,
              spreadRadius: -12,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: ColoredBox(
              color: dark
                  ? const Color(0xFF1C1E1F).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.96),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Spacer(),
                                  Container(
                                    width: 38,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: dark
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : Colors.black
                                              .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        tooltip: s.close,
                                        icon: const Icon(
                                          IOSIcons.close_rounded,
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 196,
                                width: double.infinity,
                                child: AppFeaturePreview(
                                  feature: feature,
                                  accent: accent,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                      alpha: dark ? 0.20 : 0.12),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(_icon, size: 22, color: accent),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontSize: 24,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              _Capabilities(
                                  items: _capabilities(s), accent: accent),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _GuideAction(label: s.gotIt),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _title(S s) => switch (feature) {
        AppGuideFeature.welcome => s.tourWelcomeTitle,
        AppGuideFeature.home => s.tourHomeTitle,
        AppGuideFeature.coach => s.tourCoachTitle,
        AppGuideFeature.budgets => s.tourBudgetsTitle,
        AppGuideFeature.wealth => s.tourWealthTitle,
      };

  String _body(S s) => switch (feature) {
        AppGuideFeature.welcome => s.tourWelcomeBody,
        AppGuideFeature.home => s.tourHomeBody,
        AppGuideFeature.coach => s.tourCoachBody,
        AppGuideFeature.budgets => s.tourBudgetsBody,
        AppGuideFeature.wealth => s.tourWealthBody,
      };

  IconData get _icon => switch (feature) {
        AppGuideFeature.welcome => IOSIcons.account_balance_wallet_rounded,
        AppGuideFeature.home => IOSIcons.home_rounded,
        AppGuideFeature.coach => IOSIcons.auto_awesome_rounded,
        AppGuideFeature.budgets => IOSIcons.pie_chart_outline_rounded,
        AppGuideFeature.wealth => IOSIcons.trending_up_rounded,
      };

  Color get _accent => switch (feature) {
        AppGuideFeature.coach => AppTheme.aiAccent,
        AppGuideFeature.budgets => AppTheme.warning,
        _ => AppTheme.goldPrimary,
      };

  List<({IconData icon, String label})> _capabilities(S s) => switch (feature) {
        AppGuideFeature.coach => [
            (icon: IOSIcons.add_circle_rounded, label: s.addExpense),
            (icon: IOSIcons.receipt_long_rounded, label: s.addTransaction),
            (icon: IOSIcons.auto_awesome_rounded, label: s.askAnything),
          ],
        AppGuideFeature.budgets => [
            (icon: IOSIcons.calendar_month, label: s.monthlyBudget),
            (icon: IOSIcons.pie_chart_outline_rounded, label: s.spentThisMonth),
            (icon: IOSIcons.check_circle_rounded, label: s.remaining),
          ],
        AppGuideFeature.wealth => [
            (icon: IOSIcons.wealthAccounts, label: s.accounts),
            (icon: IOSIcons.wealthInvestments, label: s.investments),
            (icon: IOSIcons.wealthSavingsGoals, label: s.savingsGoals),
          ],
        _ => [
            (icon: IOSIcons.home_rounded, label: s.today),
            (icon: IOSIcons.pie_chart_outline_rounded, label: s.budgets),
            (icon: IOSIcons.trending_up_rounded, label: s.wealth),
          ],
      };
}

class _GuideAction extends StatelessWidget {
  const _GuideAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 12 + bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Capabilities extends StatelessWidget {
  const _Capabilities({required this.items, required this.accent});

  final List<({IconData icon, String label})> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: accent),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Icon(IOSIcons.check_rounded, size: 16),
                  ],
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 43,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
            ],
          );
        }),
      ),
    );
  }
}
