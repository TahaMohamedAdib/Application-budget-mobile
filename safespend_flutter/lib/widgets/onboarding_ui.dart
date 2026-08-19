import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Building blocks for the first-run flow.
///
/// The settings surfaces ([settings_ui.dart]) established the app's glass
/// language; onboarding shares it but diverges in two ways, because it is the
/// only part of the app the user meets before they have any data:
///
/// * **Shapes are true squircles.** Every card, tile and button uses
///   [RoundedSuperellipseBorder] rather than a circular-arc radius. It is the
///   iOS 26 shape, and it reads noticeably softer at the large sizes used here.
/// * **The background is lit.** A pair of blurred colour fields sits behind the
///   content so the glass has something to refract. The rest of the app runs on
///   a flat scaffold colour, where that would be a distraction.
///
/// Colour stays reserved for meaning, as everywhere else: icon tiles are glass
/// with a neutral glyph, and the accent appears only on the primary action and
/// the current progress segment.

Color _alpha(Color color, double value) => color.withValues(alpha: value);

/// Squircle of [radius], the shape used by every surface in this file.
ShapeBorder onboardingShape(double radius, {Color? side}) =>
    RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side == null ? BorderSide.none : BorderSide(color: side),
    );

// ── Backdrop ────────────────────────────────────────────────────────────────

/// Two soft, heavily blurred colour fields over the scaffold colour.
///
/// This is what gives the glass panels something to pick up — on a flat
/// background a [BackdropFilter] has nothing to blur and the panels read as
/// plain grey boxes.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -110,
            child: _Glow(
              size: 380,
              color: _alpha(AppTheme.goldPrimary, isDark ? 0.30 : 0.20),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -140,
            child: _Glow(
              size: 420,
              color: _alpha(
                isDark ? AppTheme.aiAccent : AppTheme.aiAccentDeep,
                isDark ? 0.22 : 0.14,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, _alpha(color, 0)],
          ),
        ),
      ),
    );
  }
}

// ── Glass ───────────────────────────────────────────────────────────────────

/// A blurred squircle panel. Every grouped surface in onboarding sits on one.
class OnboardingGlass extends StatelessWidget {
  const OnboardingGlass({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.highlighted = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Draws the accent rim used for a chosen option.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = onboardingShape(radius);

    final border = highlighted
        ? _alpha(AppTheme.goldPrimary, isDark ? 0.55 : 0.45)
        : (isDark ? _alpha(Colors.white, 0.13) : const Color(0xFFDFE2E6));

    Widget panel = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: onboardingShape(radius, side: border),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [_alpha(Colors.white, 0.11), _alpha(Colors.white, 0.045)]
                  : [_alpha(Colors.white, 0.92), _alpha(Colors.white, 0.70)],
            ),
          ),
          child: Stack(
            children: [
              // Specular highlight along the top edge — this is what makes the
              // surface read as curved glass rather than a flat tint.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 52,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _alpha(Colors.white, isDark ? 0.09 : 0.55),
                          _alpha(Colors.white, 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      panel = _Pressable(onTap: onTap!, child: panel);
    }

    // Shadows must sit outside the clip or they are cut away with it.
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: _alpha(Colors.black, isDark ? 0.40 : 0.08),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: panel,
    );
  }
}

/// Scales its child slightly while held, the standard iOS tap response.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Page chrome ─────────────────────────────────────────────────────────────

/// Shared frame: lit backdrop, a top bar carrying back and progress, a
/// scrolling body, and a footer that stays reachable above the keyboard.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.step,
    this.stepCount,
    this.footer,
    this.trailing,
    this.scrollable = true,
  });

  final Widget child;
  final VoidCallback? onBack;

  /// Zero-based index of the current step; omit to hide the progress bar.
  final int? step;
  final int? stepCount;

  /// Pinned to the bottom, clear of the home indicator and the keyboard.
  final Widget? footer;

  /// Sits opposite the back button — a Skip action, typically.
  final Widget? trailing;

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: child,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      // Tap anywhere off a field to dismiss the keyboard. The amount fields
      // raise a numeric pad, which has no return key, so without this the only
      // way out of it is to submit the step.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: OnboardingBackdrop(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (onBack != null || step != null || trailing != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        if (onBack != null)
                          _CircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: onBack!,
                          )
                        else
                          const SizedBox(width: 40),
                        if (step != null && stepCount != null) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: OnboardingProgress(
                              step: step!,
                              count: stepCount!,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ] else
                          const Spacer(),
                        if (trailing != null)
                          trailing!
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                Expanded(
                  child: scrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: body,
                        )
                      : body,
                ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      12 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: footer!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: OnboardingGlass(
        radius: 20,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 16, color: AppTheme.adaptiveIcon(context)),
        ),
      ),
    );
  }
}

/// Segmented progress bar. Segments fill rather than slide so the user can see
/// how many steps remain — a single sliding bar hides the total.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    required this.count,
  });

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(count, (i) {
        final done = i <= step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(right: i < count - 1 ? 5 : 0),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: done
                  ? AppTheme.goldPrimary
                  : _alpha(isDark ? Colors.white : Colors.black, 0.12),
            ),
          ),
        );
      }),
    );
  }
}

// ── Content pieces ──────────────────────────────────────────────────────────

/// Icon tile, title and supporting line that opens every step.
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.centered = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        OnboardingGlass(
          radius: 22,
          child: SizedBox(
            width: 62,
            height: 62,
            child: Icon(icon, size: 29, color: AppTheme.adaptiveIcon(context)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Icon + text line, used for the benefit lists on the narrative screens.
class OnboardingBullet extends StatelessWidget {
  const OnboardingBullet({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnboardingGlass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      detail!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: ShapeDecoration(
        shape: onboardingShape(14),
        color: AppTheme.adaptiveIconSurface(context),
      ),
      child: Icon(icon, size: 20, color: AppTheme.adaptiveIcon(context)),
    );
  }
}

/// Selectable row with a leading icon and a trailing check.
class OnboardingChoice extends StatelessWidget {
  const OnboardingChoice({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnboardingGlass(
        radius: 20,
        highlighted: selected,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (icon != null)
              _IconTile(icon: icon!),
            if (leading != null || icon != null) const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0.6,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliding segmented control, for short mutually-exclusive answers.
class OnboardingSegmented<T> extends StatelessWidget {
  const OnboardingSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = segments.keys.toList();
    final index = keys.indexOf(value).clamp(0, keys.length - 1);

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        shape: onboardingShape(16),
        color: _alpha(Colors.black, isDark ? 0.28 : 0.045),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / keys.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: segWidth * index,
                width: segWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: onboardingShape(
                      13,
                      side: isDark
                          ? _alpha(Colors.white, 0.16)
                          : _alpha(Colors.black, 0.06),
                    ),
                    color: isDark ? _alpha(Colors.white, 0.14) : Colors.white,
                    shadows: [
                      BoxShadow(
                        color: _alpha(Colors.black, isDark ? 0.30 : 0.10),
                        blurRadius: 10,
                        spreadRadius: -3,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: keys.map((key) {
                  final active = key == value;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(key);
                      },
                      child: Center(
                        child: Text(
                          segments[key]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                            color: active
                                ? Theme.of(context).textTheme.titleMedium?.color
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Glass text field with a floating label and an optional prefix.
class OnboardingField extends StatelessWidget {
  const OnboardingField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.words,
    this.autofocus = false,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;

  /// Rendered inside the field ahead of the text — the currency symbol.
  final String? prefix;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  /// Shown beneath the field; also turns the rim red.
  final String? error;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invalid = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: onboardingShape(
              18,
              side: invalid
                  ? _alpha(AppTheme.error, 0.65)
                  : (isDark
                      ? _alpha(Colors.white, 0.13)
                      : const Color(0xFFDFE2E6)),
            ),
            color: isDark
                ? _alpha(Colors.white, 0.06)
                : _alpha(Colors.white, 0.82),
          ),
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Icon(
                    icon,
                    size: 19,
                    color: AppTheme.adaptiveIcon(context),
                  ),
                ),
              if (prefix != null)
                Padding(
                  padding: EdgeInsets.only(left: icon == null ? 16 : 10),
                  child: Text(
                    prefix!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textCapitalization: textCapitalization,
                  textInputAction: textInputAction,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  cursorColor: AppTheme.goldPrimary,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                  decoration: InputDecoration(
                    // The app theme gives every TextField a filled surface and
                    // an outline. Inside this glass rim that paints a second
                    // box, so the field's own decoration is switched off
                    // entirely rather than only its border.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _alpha(
                        Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey,
                        0.6,
                      ),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.fromLTRB(
                      icon == null && prefix == null ? 16 : 10,
                      16,
                      16,
                      16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.topLeft,
          child: invalid
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, top: 7),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.error,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}


/// iOS-style search field.
///
/// Deliberately not an [OnboardingField] with a magnifier bolted on: a search
/// control is not a labelled form input. It carries no caption above it, sits
/// on a recessed fill rather than a raised glass rim, and gains a clear button
/// once there is something to clear — which is what makes it read as search
/// at a glance rather than as another box to fill in.
class OnboardingSearchField extends StatefulWidget {
  const OnboardingSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  State<OnboardingSearchField> createState() => _OnboardingSearchFieldState();
}

class _OnboardingSearchFieldState extends State<OnboardingSearchField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChanged);

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = widget.controller.text.isNotEmpty;
    final muted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        // Recessed rather than raised — search sits *in* the page, and a
        // second glass rim next to the option cards below made the screen
        // read as a stack of identical boxes.
        shape: onboardingShape(
          14,
          side: _focus.hasFocus
              ? _alpha(AppTheme.goldPrimary, 0.55)
              : Colors.transparent,
        ),
        color: _alpha(isDark ? Colors.white : Colors.black, isDark ? 0.07 : 0.05),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: _alpha(muted, 0.9)),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              cursorColor: AppTheme.goldPrimary,
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(value);
              },
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
              decoration: InputDecoration(
                // The app theme fills and outlines every TextField; both have
                // to go or they paint a second box inside this one.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _alpha(muted, 0.75),
                ),
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.controller.clear();
                widget.onChanged?.call('');
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 17,
                  color: _alpha(muted, 0.75),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Actions ─────────────────────────────────────────────────────────────────

/// The accented primary action. One per screen.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final live = enabled && !busy;

    return _Pressable(
      onTap: live ? onTap : () {},
      child: AnimatedOpacity(
        opacity: live ? 1 : 0.45,
        duration: const Duration(milliseconds: 180),
        child: Container(
          height: 56,
          decoration: ShapeDecoration(
            shape: onboardingShape(19),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.gold500, AppTheme.gold700],
            ),
            shadows: [
              BoxShadow(
                color: _alpha(AppTheme.goldPrimary, 0.35),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Labels vary a lot in length across sixteen locales,
                        // so the text shrinks to fit rather than overflowing
                        // or being clipped mid-word.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 18, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Low-emphasis text action — Skip, or "do this later".
class OnboardingTextButton extends StatelessWidget {
  const OnboardingTextButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}
