import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/onboarding_ui.dart';

/// The answer to [HookScreen]: what the app actually does about it.
class AhaScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AhaScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OnboardingScaffold(
      onBack: onBack,
      footer: OnboardingButton(label: s.obAhaCta, onTap: onNext),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          OnboardingHero(
            icon: IOSIcons.lightbulb,
            title: s.obAhaTitle,
            subtitle: s.obAhaSubtitle,
          ).animate().fadeIn(duration: 420.ms).slideY(
                begin: 0.08,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 28),
          ...[
            OnboardingBullet(
              icon: IOSIcons.today,
              title: s.obAhaPoint1,
              detail: s.obAhaPoint1Detail,
            ),
            OnboardingBullet(
              icon: IOSIcons.account_balance_wallet_rounded,
              title: s.obAhaPoint2,
              detail: s.obAhaPoint2Detail,
            ),
            OnboardingBullet(
              icon: IOSIcons.autorenew_rounded,
              title: s.obAhaPoint3,
              detail: s.obAhaPoint3Detail,
            ),
            OnboardingBullet(
              icon: IOSIcons.psychology,
              title: s.obAhaPoint4,
              detail: s.obAhaPoint4Detail,
            ),
          ].animate(interval: 85.ms).fadeIn(duration: 380.ms).slideY(
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
