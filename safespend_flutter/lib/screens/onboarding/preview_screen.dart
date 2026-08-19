import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/onboarding_ui.dart';

/// A tour of the five tabs, immediately before the questionnaire.
///
/// Tab names come from the same keys the navigation bar uses, so what is
/// promised here matches what the user finds a minute later — including in
/// languages where the nav labels are not literal translations of the English.
class PreviewScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PreviewScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OnboardingScaffold(
      onBack: onBack,
      footer: OnboardingButton(label: s.obPreviewCta, onTap: onNext),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          OnboardingHero(
            icon: IOSIcons.home_rounded,
            title: s.obPreviewTitle,
            subtitle: s.obPreviewSubtitle,
          ).animate().fadeIn(duration: 420.ms).slideY(
                begin: 0.08,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 28),
          ...[
            OnboardingBullet(
              icon: IOSIcons.today,
              title: s.today,
              detail: s.obPreviewTodayDetail,
            ),
            OnboardingBullet(
              icon: IOSIcons.calendar_month,
              title: s.plan,
              detail: s.obPreviewPlanDetail,
            ),
            OnboardingBullet(
              icon: IOSIcons.trending_up_rounded,
              title: s.wealth,
              detail: s.obPreviewWealthDetail,
            ),
            OnboardingBullet(
              icon: IOSIcons.account_balance_rounded,
              title: s.accounts,
              detail: s.obPreviewAccountsDetail,
            ),
            OnboardingBullet(
              icon: IOSIcons.psychology,
              title: s.coach,
              detail: s.obPreviewCoachDetail,
            ),
          ].animate(interval: 80.ms).fadeIn(duration: 360.ms).slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
