import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';
import '../l10n/app_localizations.dart';
import 'feature_help_button.dart';
import 'app_form_sheet.dart';

/// Building blocks for VVollet's iOS-inspired settings surfaces.
///
/// The layout follows the familiar inset-grouped Settings pattern while the
/// teal accent, Inter typography, dark charcoal and warm light surfaces keep
/// it recognisably part of VVollet.

Color _alpha(Color color, double value) => color.withValues(alpha: value);

/// Fill + rim for any glass surface in the settings tree.
class _GlassSkin {
  const _GlassSkin({
    required this.gradient,
    required this.border,
    required this.shadows,
    required this.sheen,
  });

  final Gradient gradient;
  final Color border;
  final List<BoxShadow> shadows;
  final Color sheen;

  factory _GlassSkin.of(BuildContext context, {bool elevated = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GlassSkin(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF252829), Color(0xFF222526)]
            : const [Color(0xFFFFFFFF), Color(0xFFF8F9F8)],
      ),
      border:
          isDark ? _alpha(Colors.white, 0.075) : _alpha(Colors.black, 0.055),
      shadows: [
        BoxShadow(
          color: _alpha(Colors.black, isDark ? 0.24 : 0.055),
          blurRadius: elevated ? 22 : 12,
          spreadRadius: -7,
          offset: Offset(0, elevated ? 9 : 5),
        ),
      ],
      sheen: Colors.transparent,
    );
  }
}

/// An inset grouped surface. The legacy name is retained because settings
/// controls outside groups also share this component.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 22,
    this.elevated = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final bool elevated;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final skin = _GlassSkin.of(context, elevated: elevated);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      // Shadows must sit outside the clip or they get cut away.
      decoration:
          BoxDecoration(borderRadius: borderRadius, boxShadow: skin.shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: skin.gradient,
              border: Border.all(color: skin.border),
            ),
            child: Stack(
              children: [
                // Specular highlight across the top edge — this is what makes
                // the surface read as curved glass rather than flat tint.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 46,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [skin.sheen, _alpha(Colors.white, 0)],
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
      ),
    );
  }
}

/// Scroll-aware page chrome: an iOS-style large title that collapses into a
/// compact blurred bar, with content scrolling underneath the glass.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (AppFormSheetScope.isActive(context)) {
      return AppFormSheet(
        header: Row(
          children: [
            Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            FeatureHelpButton(
              title: title,
              description: subtitle ?? S.of(context).helpAndSupportSubtitle,
              size: 36,
            ),
            if (trailing != null) trailing!,
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (subtitle != null) ...[
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
            ],
            ...children,
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The header blurs whatever scrolls beneath it, so the body must extend
      // behind it rather than start below it.
      body: Stack(
        children: [
          const Positioned.fill(child: SettingsBackdrop()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SettingsHeaderDelegate(
                  title: title,
                  subtitle: subtitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FeatureHelpButton(
                        title: title,
                        description:
                            subtitle ?? S.of(context).helpAndSupportSubtitle,
                        size: 36,
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 6),
                        trailing!,
                      ],
                    ],
                  ),
                  topPadding: MediaQuery.paddingOf(context).top,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  36 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList(delegate: SliverChildListDelegate(children)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsBackdrop extends StatelessWidget {
  const SettingsBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF111415), Color(0xFF0D1010)]
                : const [Color(0xFFF4F6F5), Color(0xFFEEF2F0)],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -110,
              end: -95,
              child: _AmbientOrb(
                size: 280,
                color: _alpha(AppTheme.goldPrimary, isDark ? 0.075 : 0.09),
              ),
            ),
            PositionedDirectional(
              top: 330,
              start: -130,
              child: _AmbientOrb(
                size: 250,
                color: _alpha(AppTheme.success, isDark ? 0.035 : 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
}

class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SettingsHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.topPadding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double topPadding;

  static const _barHeight = 50.0;
  double get _largeBlock => subtitle == null ? 70.0 : 88.0;

  @override
  double get minExtent => topPadding + _barHeight;

  @override
  double get maxExtent => topPadding + _barHeight + _largeBlock;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    final textColor = Theme.of(context).textTheme.titleLarge?.color;

    return ClipRect(
      child: BackdropFilter(
        // Only actually blurs once the bar has something behind it; running it
        // the whole time keeps the transition from popping.
        filter: ImageFilter.blur(sigmaX: 26 * t, sigmaY: 26 * t),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _alpha(
              isDark ? const Color(0xFF0E0F11) : Colors.white,
              0.72 * t,
            ),
            border: Border(
              bottom: BorderSide(
                color: _alpha(
                  isDark ? Colors.white : Colors.black,
                  (isDark ? 0.12 : 0.08) * t,
                ),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Stack(
              children: [
                // Compact centred title — fades in over the back half of the
                // collapse so it doesn't fight the large title.
                PositionedDirectional(
                  top: 0,
                  start: 56,
                  end: 56,
                  height: _barHeight,
                  child: Opacity(
                    opacity: ((t - 0.45) / 0.55).clamp(0.0, 1.0),
                    child: Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                      ),
                    ),
                  ),
                ),

                // Large title, sliding up and fading as it collapses.
                PositionedDirectional(
                  top: _barHeight + 4,
                  start: 20,
                  end: 20,
                  child: Opacity(
                    opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -10 * t),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontSize: 32,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Back affordance sits above both titles at all times.
                PositionedDirectional(
                  top: 0,
                  start: 6,
                  height: _barHeight,
                  child: _HeaderIconButton(
                    icon: IOSIcons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                if (trailing != null)
                  PositionedDirectional(
                    top: 0,
                    end: 10,
                    height: _barHeight,
                    child: Center(child: trailing!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SettingsHeaderDelegate old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.topPadding != topPadding ||
      old.trailing != trailing;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 46,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? _alpha(Colors.white, 0.07)
                  : _alpha(Colors.white, 0.78),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? _alpha(Colors.white, 0.10)
                    : _alpha(Colors.black, 0.06),
              ),
            ),
            child: Icon(icon, size: 17, color: AppTheme.adaptiveIcon(context)),
          ),
        ),
      ),
    );
  }
}

/// A titled group of rows on one inset panel, with an optional explanatory
/// footer underneath — the iOS inset-grouped pattern.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        // The 58px inset exists to clear a row's leading icon tile. A confirm
        // button has none, so its divider runs the full width instead.
        final fullBleed = children[i] is SettingsConfirmRow ||
            children[i - 1] is SettingsConfirmRow;
        rows.add(Padding(
          padding: EdgeInsetsDirectional.only(start: fullBleed ? 0 : 60),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ));
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 8),
              child: Text(
                header!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          GlassPanel(child: Column(children: rows)),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),
              child: Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Neutral glass icon tile that leads a settings row.
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({super.key, required this.icon, this.tint});

  final IconData icon;

  /// Reserved for destructive rows. Left null everywhere else so rows stay
  /// neutral, matching the rest of the app.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = tint ?? AppTheme.goldPrimary;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _alpha(Colors.white, isDark ? 0.10 : 0.22),
        ),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// Standard tappable row: icon, label, optional detail line, optional
/// right-aligned value, chevron.
class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    this.value,
    this.onTap,
    this.trailing,
    this.tint,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tint;
  final bool showChevron;

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && widget.onTap != null) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: widget.onTap == null ? null : () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        color: _pressed
            ? (isDark
                ? _alpha(Colors.white, 0.05)
                : _alpha(Colors.black, 0.035))
            : Colors.transparent,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            SettingsIconTile(icon: widget.icon, tint: widget.tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: widget.tint ??
                              Theme.of(context).textTheme.titleMedium?.color,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                  if (widget.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.detail!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.value != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(
                    widget.value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 15,
                        ),
                  ),
                ),
              ),
            if (widget.trailing != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: widget.trailing!,
              ),
            if (widget.showChevron && widget.onTap != null)
              SizedBox(
                width: 20,
                height: 28,
                child: Center(
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      IOSIcons.chevron_right_rounded,
                      size: 18,
                      color: AppTheme.adaptiveIcon(context, alpha: 0.62),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Row whose trailing control is a switch. Tapping anywhere toggles it.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: SettingsRow(
        icon: icon,
        label: label,
        detail: detail,
        showChevron: false,
        onTap: enabled ? () => onChanged(!value) : null,
        trailing: IgnorePointer(
          child: Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppTheme.goldPrimary,
          ),
        ),
      ),
    );
  }
}

/// Row used inside pickers: a checkmark marks the active choice.
class SettingsChoiceRow extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.leading,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: selected
            ? _alpha(AppTheme.goldPrimary,
                Theme.of(context).brightness == Brightness.dark ? 0.09 : 0.07)
            : Colors.transparent,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.goldPrimary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppTheme.goldPrimary
                      : AppTheme.adaptiveIcon(context, alpha: 0.28),
                ),
              ),
              child: selected
                  ? const Icon(IOSIcons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style segmented control with a sliding glass thumb.
class SettingsSegmented<T> extends StatelessWidget {
  const SettingsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final Map<T, ({IconData? icon, String label})> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = segments.keys.toList();
    final index = keys.indexOf(value).clamp(0, keys.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:
              isDark ? _alpha(Colors.black, 0.28) : _alpha(Colors.black, 0.045),
          borderRadius: BorderRadius.circular(17),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segWidth = constraints.maxWidth / keys.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: segWidth *
                      (Directionality.of(context) == TextDirection.rtl
                          ? keys.length - 1 - index
                          : index),
                  width: segWidth,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                _alpha(AppTheme.goldPrimary, 0.34),
                                _alpha(AppTheme.gold700, 0.24),
                              ]
                            : [
                                _alpha(AppTheme.goldPrimary, 0.22),
                                _alpha(AppTheme.gold50, 0.92),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? _alpha(Colors.white, 0.16)
                            : _alpha(Colors.black, 0.06),
                      ),
                      boxShadow: [
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
                    final seg = segments[key]!;
                    final active = key == value;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(key);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (seg.icon != null) ...[
                              Icon(
                                seg.icon,
                                size: 19,
                                color: active
                                    ? (isDark
                                        ? AppTheme.gold300
                                        : AppTheme.gold700)
                                    : AppTheme.adaptiveIcon(context),
                              ),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              seg.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: active
                                        ? (isDark
                                            ? AppTheme.gold300
                                            : AppTheme.gold700)
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Labelled slider row for continuous preferences.
class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (valueLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _alpha(AppTheme.goldPrimary, 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    valueLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.gold300
                              : AppTheme.gold700,
                        ),
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: AppTheme.goldPrimary,
              thumbColor: AppTheme.goldPrimary,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text entry that reads as a settings row: leading icon tile, label on the
/// left, the field itself right-aligned where a value would normally sit.
///
/// Forms in this app used boxed Material [TextField]s, which put a heavy
/// outlined rectangle around every input and looked nothing like the grouped
/// rows the rest of the app is built from. This keeps entry inside the same
/// glass panel as everything else.
class SettingsTextFieldRow extends StatelessWidget {
  const SettingsTextFieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.prefix,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  /// Sits immediately before the entered text — a currency symbol, usually.
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          SettingsIconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: Text(
              label,
              // Long labels in other languages must shorten rather than wrap;
              // a two-line label pushes the row out of step with its
              // neighbours in the same panel.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(width: 5)],
                Flexible(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textCapitalization: textCapitalization,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: _alpha(
                              theme.textTheme.bodySmall?.color ?? Colors.grey,
                              0.55)),
                      // The panel is the container; the field must not draw a
                      // second one inside it.
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
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

/// Confirm button for a staged control — one whose change is previewed first
/// and only written when the user commits it.
///
/// Stays disabled while the staged value matches what is already saved, so the
/// button doubles as the indicator of whether anything is pending.
class SettingsConfirmRow extends StatefulWidget {
  const SettingsConfirmRow({
    super.key,
    required this.label,
    required this.onConfirm,
  });

  final String label;

  /// Null disables the button (nothing staged to apply).
  final VoidCallback? onConfirm;

  @override
  State<SettingsConfirmRow> createState() => _SettingsConfirmRowState();
}

class _SettingsConfirmRowState extends State<SettingsConfirmRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onConfirm != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onConfirm!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? _alpha(AppTheme.goldPrimary, _down ? 0.72 : 1)
                : _alpha(isDark ? Colors.white : Colors.black, 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? Colors.white
                      : _alpha(isDark ? Colors.white : Colors.black, 0.32),
                ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed destructive/primary action row on its own panel.
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.detail,
  });

  final String label;
  final String? detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.error : null;
    return SettingsRow(
      icon: icon,
      label: label,
      detail: detail,
      onTap: onTap,
      tint: color,
      showChevron: !destructive,
    );
  }
}

/// Confirmation alert in the iOS style. Returns true on confirm.
///
/// Replaces the stock Material [AlertDialog], which put a left-aligned title
/// and a right-aligned button row into an app whose every other surface is
/// centred glass — it read as a system popup that had wandered in from
/// another app.
///
/// The layout follows UIAlertController: a narrow centred card, hairline
/// dividers, and two equal buttons split down the middle, with the
/// destructive choice on the right in red.
Future<bool> showSettingsConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: _alpha(Colors.black, 0.34),
    builder: (ctx) => _IOSAlert(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class _IOSAlert extends StatelessWidget {
  const _IOSAlert({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider =
        isDark ? _alpha(Colors.white, 0.14) : _alpha(Colors.black, 0.12);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(26),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 288),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              shadows: [
                BoxShadow(
                  color: _alpha(Colors.black, isDark ? 0.5 : 0.18),
                  blurRadius: 40,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: shape,
                    color: isDark
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.94),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        child: Column(
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(height: 0.5, color: divider),
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              child: _AlertButton(
                                label: cancelLabel,
                                onTap: () => Navigator.pop(context, false),
                              ),
                            ),
                            Container(width: 0.5, color: divider),
                            Expanded(
                              child: _AlertButton(
                                label: confirmLabel,
                                emphasised: true,
                                color: destructive ? AppTheme.error : null,
                                onTap: () => Navigator.pop(context, true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertButton extends StatefulWidget {
  const _AlertButton({
    required this.label,
    required this.onTap,
    this.emphasised = false,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasised;
  final Color? color;

  @override
  State<_AlertButton> createState() => _AlertButtonState();
}

class _AlertButtonState extends State<_AlertButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: ColoredBox(
        // iOS highlights the whole button cell on press rather than drawing a
        // ripple, which would fight the hairline dividers.
        color: _down
            ? _alpha(isDark ? Colors.white : Colors.black, 0.07)
            : Colors.transparent,
        child: Center(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight:
                      widget.emphasised ? FontWeight.w600 : FontWeight.w400,
                  color: widget.color ?? AppTheme.goldPrimary,
                ),
          ),
        ),
      ),
    );
  }
}

/// Brief confirmation toast in the app's snackbar style.
void showSettingsToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
    );
}
