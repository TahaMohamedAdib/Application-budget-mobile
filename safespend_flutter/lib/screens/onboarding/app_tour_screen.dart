import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../utils/money_format.dart';

/// Product areas represented by onboarding and contextual first-use help.
enum AppGuideFeature { welcome, home, coach, budgets, wealth }

class _TourPage {
  const _TourPage({
    required this.feature,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final AppGuideFeature feature;
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
}

/// First-run product tour, replayable from Settings.
///
/// Each page demonstrates an actual SafeSpend workflow rather than presenting
/// an abstract icon. The layout stays scrollable for Dynamic Type and short
/// screens, supports the native back gesture/swipe, and respects Reduce Motion.
class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_TourPage> _pages(S s) => [
        _TourPage(
          feature: AppGuideFeature.welcome,
          icon: IOSIcons.account_balance_wallet_rounded,
          accent: AppTheme.goldPrimary,
          title: s.tourWelcomeTitle,
          body: s.tourWelcomeBody,
        ),
        _TourPage(
          feature: AppGuideFeature.home,
          icon: IOSIcons.home_rounded,
          accent: AppTheme.goldPrimary,
          title: s.tourHomeTitle,
          body: s.tourHomeBody,
        ),
        // The AI Coach page is omitted while the coach is closed behind its
        // "coming soon" screen: a tour should not sell a tab that cannot be
        // used. Restore this page when the coach reopens.
        _TourPage(
          feature: AppGuideFeature.budgets,
          icon: IOSIcons.pie_chart_outline_rounded,
          accent: AppTheme.warning,
          title: s.tourBudgetsTitle,
          body: s.tourBudgetsBody,
        ),
        _TourPage(
          feature: AppGuideFeature.wealth,
          icon: IOSIcons.trending_up_rounded,
          accent: AppTheme.goldPrimary,
          title: s.tourWealthTitle,
          body: s.tourWealthBody,
        ),
      ];

  Duration _motion(int milliseconds) => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);

  void _goTo(int page, int count) {
    final target = page.clamp(0, count - 1);
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    HapticFeedback.lightImpact();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pages = _pages(s);
    final last = _index == pages.length - 1;
    final compact = MediaQuery.sizeOf(context).height < 700 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _TourHeader(
              index: _index,
              count: pages.length,
              onBack:
                  _index == 0 ? null : () => _goTo(_index - 1, pages.length),
              onSkip: last ? null : _finish,
              motion: _motion(220),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => _TourPageView(
                  page: pages[index],
                  active: index == _index,
                  compact: compact,
                  motion: _motion(250),
                ),
              ),
            ),
            _TourFooter(
              label: last ? s.tourGetStarted : s.tourNext,
              showArrow: !last,
              onPressed: () =>
                  last ? _finish() : _goTo(_index + 1, pages.length),
              motion: _motion(220),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourHeader extends StatelessWidget {
  const _TourHeader({
    required this.index,
    required this.count,
    required this.onBack,
    required this.onSkip,
    required this.motion,
  });

  final int index;
  final int count;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: AnimatedOpacity(
              opacity: onBack == null ? 0 : 1,
              duration: motion,
              child: IconButton(
                onPressed: onBack,
                tooltip: S.of(context).back,
                icon: const Icon(IOSIcons.arrow_back_rounded, size: 21),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: '${index + 1} / $count',
              child: ExcludeSemantics(
                child: Row(
                  children: List.generate(
                    count,
                    (i) => Expanded(
                      child: AnimatedContainer(
                        duration: motion,
                        curve: Curves.easeOutCubic,
                        height: 4,
                        margin: EdgeInsetsDirectional.only(
                          end: i == count - 1 ? 0 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: i <= index
                              ? AppTheme.goldPrimary
                              : _inactiveTrack(context),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            height: 48,
            child: AnimatedOpacity(
              opacity: onSkip == null ? 0 : 1,
              duration: motion,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).textTheme.bodyMedium?.color,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  S.of(context).tourSkip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourPageView extends StatelessWidget {
  const _TourPageView({
    required this.page,
    required this.active,
    required this.compact,
    required this.motion,
  });

  final _TourPage page;
  final bool active;
  final bool compact;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: active ? 1 : 0.62,
                    duration: motion,
                    child: AnimatedScale(
                      scale: active ? 1 : 0.97,
                      duration: motion,
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        width: double.infinity,
                        height: compact ? 214 : 292,
                        child: AppFeaturePreview(
                          feature: page.feature,
                          accent: page.accent,
                          compact: compact,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 22 : 30),
                  Icon(
                    page.icon,
                    size: 22,
                    color: page.accent,
                    semanticLabel: page.title,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: compact ? 25 : 29,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.65,
                        ),
                  ),
                  const SizedBox(height: 11),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Text(
                      page.body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.45,
                          ),
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

class _TourFooter extends StatelessWidget {
  const _TourFooter({
    required this.label,
    required this.showArrow,
    required this.onPressed,
    required this.motion,
  });

  final String label;
  final bool showArrow;
  final VoidCallback onPressed;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.white,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: motion,
                child: Row(
                  key: ValueKey(label),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showArrow) ...[
                      const SizedBox(width: 8),
                      const Icon(IOSIcons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Realistic feature mockup shared by the tour and contextual help sheets.
class AppFeaturePreview extends StatelessWidget {
  const AppFeaturePreview({
    super.key,
    required this.feature,
    required this.accent,
    this.compact = false,
  });

  final AppGuideFeature feature;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final money = MoneyFormat.of(context.read<AppProvider>().settings);
    final child = switch (feature) {
      AppGuideFeature.welcome => _WelcomePreview(s: s),
      AppGuideFeature.home => _HomePreview(s: s, format: money.format),
      AppGuideFeature.coach => _CoachPreview(s: s),
      AppGuideFeature.budgets => _BudgetsPreview(s: s, format: money.format),
      AppGuideFeature.wealth => _WealthPreview(s: s, format: money.format),
    };
    return ExcludeSemantics(
      child: _PreviewShell(accent: accent, compact: compact, child: child),
    );
  }
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({
    required this.accent,
    required this.compact,
    required this.child,
  });

  final Color accent;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(compact ? 28 : 34),
      side: BorderSide(color: _previewBorder(context)),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.10),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            accent.withValues(alpha: 0.12),
                            const Color(0xFF202223),
                            const Color(0xFF181A1B),
                          ]
                        : [
                            Colors.white,
                            accent.withValues(alpha: 0.07),
                            const Color(0xFFF1F3F3),
                          ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: compact ? -58 : -72,
                end: compact ? -44 : -52,
                child: Container(
                  width: compact ? 150 : 190,
                  height: compact ? 150 : 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: dark ? 0.09 : 0.07),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 14 : 18),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePreview extends StatelessWidget {
  const _WelcomePreview({required this.s});

  final S s;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final logo = dark
        ? 'assets/icons/logo app dark mode.jpeg'
        : 'assets/icons/logo app light mode.jpeg';
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight.clamp(170.0, 250.0) * 0.52;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 2,
              child: Text(
                'SafeSpend',
                style: TextStyle(
                  color: _previewPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Container(
              width: size,
              height: size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.32 : 0.15),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppTheme.goldPrimary,
                  child: Icon(
                    IOSIcons.account_balance_wallet_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              bottom: 8,
              child: _FeatureChip(
                icon: IOSIcons.check_circle_rounded,
                label: s.safeToSpend,
                color: AppTheme.success,
              ),
            ),
            PositionedDirectional(
              end: 0,
              top: 30,
              child: _FeatureChip(
                icon: IOSIcons.pie_chart_outline_rounded,
                label: s.budgets,
                color: AppTheme.warning,
              ),
            ),
            PositionedDirectional(
              end: 4,
              bottom: 8,
              child: _FeatureChip(
                icon: IOSIcons.trending_up_rounded,
                label: s.wealth,
                color: AppTheme.goldPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomePreview extends StatelessWidget {
  const _HomePreview({required this.s, required this.format});

  final S s;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewHeader(icon: IOSIcons.home_rounded, title: s.today),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: _PreviewCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.safeToSpend, style: _caption(context)),
                      const SizedBox(height: 3),
                      Text(
                        format(1824.50),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _amountStyle(context, 18),
                      ),
                      const SizedBox(height: 8),
                      const _Progress(value: 0.68, color: AppTheme.success),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 5,
                child: _PreviewCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Ring(value: 0.62, color: AppTheme.goldPrimary),
                      const SizedBox(height: 5),
                      Text(
                        s.spentThisMonth,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _caption(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _PreviewCard(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Column(
            children: [
              _Transaction(
                icon: IOSIcons.shopping_bag_rounded,
                label: s.expense,
                amount: '-${format(42.80)}',
                color: AppTheme.error,
              ),
              const SizedBox(height: 6),
              _Transaction(
                icon: IOSIcons.payments_rounded,
                label: s.incomeLabel,
                amount: '+${format(850)}',
                color: AppTheme.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoachPreview extends StatelessWidget {
  const _CoachPreview({required this.s});

  final S s;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewHeader(
          icon: IOSIcons.auto_awesome_rounded,
          title: s.coach,
          accent: AppTheme.aiAccent,
        ),
        const SizedBox(height: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _Bubble(label: s.spentThisMonth, user: true),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Bubble(label: s.tourCoachBody, user: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 38,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 6, 0),
          decoration: BoxDecoration(
            color: _previewSurface(context),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _previewBorder(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.askAnything,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _caption(context),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.aiAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IOSIcons.arrow_upward_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetsPreview extends StatelessWidget {
  const _BudgetsPreview({required this.s, required this.format});

  final S s;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewHeader(
          icon: IOSIcons.pie_chart_outline_rounded,
          title: s.monthlyBudget,
          trailing: format(2400),
          accent: AppTheme.warning,
        ),
        const SizedBox(height: 9),
        Expanded(
          child: _PreviewCard(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BudgetRow(
                  icon: IOSIcons.receipt_long_rounded,
                  label: s.bills,
                  amount: format(720),
                  value: 0.72,
                  color: AppTheme.warning,
                ),
                _BudgetRow(
                  icon: IOSIcons.repeat_rounded,
                  label: s.subscriptions,
                  amount: format(214),
                  value: 0.43,
                  color: AppTheme.aiAccent,
                ),
                _BudgetRow(
                  icon: IOSIcons.shopping_bag_rounded,
                  label: s.expenses,
                  amount: format(580),
                  value: 0.58,
                  color: AppTheme.goldPrimary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _Stat(label: s.spentThisMonthOnly, value: format(1514))),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: s.remaining,
                value: format(886),
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WealthPreview extends StatelessWidget {
  const _WealthPreview({required this.s, required this.format});

  final S s;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewHeader(
          icon: IOSIcons.trending_up_rounded,
          title: s.netWorth,
          trailing: format(18420),
        ),
        const SizedBox(height: 9),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: _PreviewCard(
                  padding: const EdgeInsets.all(10),
                  child: CustomPaint(
                    painter: _ChartPainter(
                      color: AppTheme.goldPrimary,
                      grid: _previewBorder(context),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(
                      child: _WealthTile(
                        icon: IOSIcons.wealthInvestments,
                        label: s.investments,
                        value: format(9200),
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _WealthTile(
                        icon: IOSIcons.wealthSavingsGoals,
                        label: s.savingsGoals,
                        value: format(3400),
                        color: AppTheme.aiAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _Stat(label: s.accounts, value: '3')),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: s.debt,
                value: format(1280),
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.accent = AppTheme.goldPrimary,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniIcon(icon: icon, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _previewPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          Flexible(
            child: Text(
              trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: _caption(context),
            ),
          ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard(
      {required this.child, this.padding = const EdgeInsets.all(11)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _previewSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _previewBorder(context)),
      ),
      child: child,
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(maxWidth: 128),
      padding: const EdgeInsetsDirectional.fromSTEB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF2C2E2F).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _previewBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.24 : 0.09),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _previewPrimary(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, required this.user});

  final String label;
  final bool user;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 285),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: user
            ? AppTheme.goldPrimary
            : AppTheme.aiAccent.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.18
                    : 0.12,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(15),
          topRight: const Radius.circular(15),
          bottomLeft: Radius.circular(user ? 15 : 5),
          bottomRight: Radius.circular(user ? 5 : 15),
        ),
      ),
      child: Text(
        label,
        maxLines: user ? 1 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: user ? Colors.white : _previewPrimary(context),
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String amount;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniIcon(icon: icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _previewPrimary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(amount, style: _caption(context)),
                ],
              ),
              const SizedBox(height: 4),
              _Progress(value: value, color: color),
            ],
          ),
        ),
      ],
    );
  }
}

class _Transaction extends StatelessWidget {
  const _Transaction({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.adaptiveIcon(context)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _previewPrimary(context),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _caption(context),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? _previewPrimary(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WealthTile extends StatelessWidget {
  const _WealthTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _caption(context),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _previewPrimary(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.12,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 5,
        color: color,
        backgroundColor: color.withValues(alpha: 0.13),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: color.withValues(alpha: 0.13),
          ),
          Center(
            child: Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: _previewPrimary(context),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.color, required this.grid});

  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final points = [
      Offset(0, size.height * 0.78),
      Offset(size.width * 0.18, size.height * 0.64),
      Offset(size.width * 0.37, size.height * 0.70),
      Offset(size.width * 0.55, size.height * 0.43),
      Offset(size.width * 0.72, size.height * 0.49),
      Offset(size.width, size.height * 0.18),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.grid != grid;
}

Color _previewPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;

Color _previewSurface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.075)
        : Colors.white.withValues(alpha: 0.78);

Color _previewBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

Color _inactiveTrack(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

TextStyle _caption(BuildContext context) => TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkTextSecondary
          : AppTheme.lightTextSecondary,
      fontSize: 10,
      height: 1.2,
      fontWeight: FontWeight.w500,
    );

TextStyle _amountStyle(BuildContext context, double size) => TextStyle(
      color: _previewPrimary(context),
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
    );
