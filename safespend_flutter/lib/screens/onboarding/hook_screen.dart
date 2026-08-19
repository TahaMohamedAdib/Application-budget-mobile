import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/onboarding_ui.dart';

/// The problem statement, before the app explains itself.
///
/// Rewritten away from "78% of Americans" — an unsourced statistic about one
/// country, shown to a user who has just picked one of sixteen languages, is
/// worse than no number at all.
class HookScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const HookScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OnboardingScaffold(
      onBack: onBack,
      footer: OnboardingButton(label: s.obHookCta, onTap: onNext),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          OnboardingHero(
            icon: IOSIcons.help_outline_rounded,
            title: s.obHookTitle,
            subtitle: s.obHookSubtitle,
          ).animate().fadeIn(duration: 420.ms).slideY(
                begin: 0.08,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 28),
          ...[
            OnboardingBullet(
              icon: IOSIcons.receipt_long_rounded,
              title: s.obHookPoint1,
              detail: s.obHookPoint1Detail,
            ),
            OnboardingBullet(
              icon: IOSIcons.trending_down,
              title: s.obHookPoint2,
              detail: s.obHookPoint2Detail,
            ),
            OnboardingBullet(
              icon: IOSIcons.visibility_off_rounded,
              title: s.obHookPoint3,
              detail: s.obHookPoint3Detail,
            ),
          ].animate(interval: 90.ms).fadeIn(duration: 380.ms).slideY(
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
