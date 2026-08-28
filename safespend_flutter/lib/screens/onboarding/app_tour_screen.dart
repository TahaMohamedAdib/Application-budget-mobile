import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';

/// A single page of the guided tour.
class _TourPage {
  const _TourPage({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
}

/// A polished, iOS-style guided tour shown once on first launch.
///
/// Frosted-glass hero card, spring-in illustrations, a soft animated accent
/// gradient behind each page, custom page dots, and Skip / Next / Get Started
/// controls. Purely presentational — [onDone] is called when the user finishes
/// or skips; the caller persists the "seen" flag.
class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_TourPage> _pages(S s) => [
        _TourPage(
          icon: IOSIcons.account_balance_wallet_rounded,
          accent: AppTheme.goldPrimary,
          title: s.tourWelcomeTitle,
          body: s.tourWelcomeBody,
        ),
        _TourPage(
          icon: IOSIcons.home_rounded,
          accent: AppTheme.goldPrimary,
          title: s.tourHomeTitle,
          body: s.tourHomeBody,
        ),
        _TourPage(
          icon: IOSIcons.auto_awesome_rounded,
          accent: AppTheme.aiAccent,
          title: s.tourCoachTitle,
          body: s.tourCoachBody,
        ),
        _TourPage(
          icon: IOSIcons.pie_chart_outline_rounded,
          accent: AppTheme.warning,
          title: s.tourBudgetsTitle,
          body: s.tourBudgetsBody,
        ),
        _TourPage(
          icon: IOSIcons.trending_up_rounded,
          accent: AppTheme.goldPrimary,
          title: s.tourWealthTitle,
          body: s.tourWealthBody,
        ),
      ];

  void _next(int lastIndex) {
    if (_index >= lastIndex) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _pages(s);
    final page = pages[_index];
    final isLast = _index == pages.length - 1;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Stack(
        children: [
          // Ambient accent glow behind the current page — cross-fades on change.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _AccentGlow(
              key: ValueKey(_index),
              color: page.accent,
              isDark: isDark,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                    child: AnimatedOpacity(
                      opacity: isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: TextButton(
                        onPressed: isLast ? null : widget.onDone,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          s.tourSkip,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _TourPageView(page: pages[i], isDark: isDark),
                  ),
                ),

                // Dots
                _Dots(count: pages.length, index: _index, accent: page.accent),
                const SizedBox(height: 28),

                // Primary action
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _PrimaryButton(
                      label: isLast ? s.tourGetStarted : s.tourNext,
                      accent: page.accent,
                      onPressed: () => _next(pages.length - 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The illustration + title + body for one page, with staggered spring-in.
class _TourPageView extends StatelessWidget {
  const _TourPageView({required this.page, required this.isDark});

  final _TourPage page;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Frosted-glass icon medallion
          _GlassMedallion(icon: page.icon, accent: page.accent, isDark: isDark)
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.82, 0.82),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 44),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color:
                  isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 120.ms)
              .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 240.ms)
              .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// A frosted-glass circular medallion holding the page's icon.
class _GlassMedallion extends StatelessWidget {
  const _GlassMedallion({
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.28 : 0.18),
                accent.withValues(alpha: isDark ? 0.12 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.30 : 0.22),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(icon, size: 58, color: accent),
        ),
      ),
    );
  }
}

/// Soft radial accent glow anchored to the top of the screen.
class _AccentGlow extends StatelessWidget {
  const _AccentGlow({super.key, required this.color, required this.isDark});

  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.65),
            radius: 1.1,
            colors: [
              color.withValues(alpha: isDark ? 0.22 : 0.14),
              Colors.transparent,
            ],
            stops: const [0.0, 0.75],
          ),
        ),
      ),
    );
  }
}

/// Animated page indicator — the active dot stretches into a pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.accent});

  final int count;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.12);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 26 : 8,
          decoration: BoxDecoration(
            color: active ? accent : inactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Full-width primary CTA that adopts the current page's accent colour.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
