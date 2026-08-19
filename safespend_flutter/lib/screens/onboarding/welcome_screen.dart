import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/onboarding_ui.dart';

/// First screen of the first run.
///
/// It used to paint its own slate gradient and pin white text over it, which
/// meant it ignored the user's theme and looked like a different app than the
/// one behind it. It now sits on the shared lit backdrop and takes its colours
/// from the theme, so light mode is genuinely light.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OnboardingScaffold(
      scrollable: false,
      footer: Column(
        children: [
          OnboardingButton(
            label: s.getStarted,
            icon: IOSIcons.arrow_forward_rounded,
            onTap: onNext,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 420.ms)
              .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          Text(
            s.obWelcomeFootnote,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 560.ms),
        ],
      ),
      child: Column(
        children: [
          const Spacer(flex: 3),
          const AppLogoWidget(size: 112, onDark: false)
              .animate()
              .fadeIn(duration: 600.ms)
              .scaleXY(
                begin: 0.78,
                end: 1,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 34),
          Column(
            children: [
              Text(
                s.obWelcomeTo,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SafeSpend',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1.05,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.obTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 180.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 34),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(icon: IOSIcons.shield_rounded, label: s.obPillPrivate),
              _Pill(icon: IOSIcons.auto_awesome_rounded, label: s.obPillSmart),
              _Pill(icon: IOSIcons.bolt_rounded, label: s.obPillFast),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 320.ms),
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OnboardingGlass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.adaptiveIcon(context)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
