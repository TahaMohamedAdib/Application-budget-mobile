import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';

/// Building blocks for the settings surfaces, in the same translucent
/// "liquid glass" language as the floating nav pill and [GlassActionButton]:
/// blurred surfaces, a specular sheen along the top edge, hairline neutral
/// rims and soft drop shadows.
///
/// Two deliberate departures from stock iOS Settings:
///
/// * **Icon tiles stay neutral.** iOS tints each row's tile with a per-feature
///   colour; this app removed decorative colour from rows on purpose, so tiles
///   are glass and the icon takes the adaptive neutral. Colour is reserved for
///   financial meaning and destructive actions.
/// * **Groups are inset cards, not full-bleed.** They match the radius and
///   shadow of the app's existing cards so settings doesn't read as a
///   different app.

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
            ? [_alpha(Colors.white, 0.10), _alpha(Colors.white, 0.045)]
            : [_alpha(Colors.white, 0.94), _alpha(Colors.white, 0.72)],
      ),
      border: isDark ? _alpha(Colors.white, 0.13) : const Color(0xFFDDE0E4),
      shadows: [
        BoxShadow(
          color: _alpha(Colors.black, isDark ? 0.40 : 0.07),
          blurRadius: elevated ? 26 : 18,
          spreadRadius: -8,
          offset: Offset(0, elevated ? 12 : 8),
        ),
      ],
      sheen: _alpha(Colors.white, isDark ? 0.08 : 0.55),
    );
  }
}

/// A blurred, sheened glass panel. Everything grouped in settings sits on one.
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The header blurs whatever scrolls beneath it, so the body must extend
      // behind it rather than start below it.
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SettingsHeaderDelegate(
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              topPadding: MediaQuery.paddingOf(context).top,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              18,
              8,
              18,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList(delegate: SliverChildListDelegate(children)),
          ),
        ],
      ),
    );
  }
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
  double get _largeBlock => subtitle == null ? 52.0 : 72.0;

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
                Positioned(
                  top: 0,
                  left: 56,
                  right: 56,
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
                Positioned(
                  top: _barHeight - 4,
                  left: 20,
                  right: 20,
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
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: textColor,
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
                Positioned(
                  top: 0,
                  left: 6,
                  height: _barHeight,
                  child: _HeaderIconButton(
                    icon: IOSIcons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                if (trailing != null)
                  Positioned(
                    top: 0,
                    right: 10,
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
        width: 44,
        child: Center(
          child: Icon(icon, size: 20, color: AppTheme.adaptiveIcon(context)),
        ),
      ),
    );
  }
}

/// A titled group of rows on one glass panel, with an optional explanatory
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
          padding: EdgeInsetsDirectional.only(start: fullBleed ? 0 : 58),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ));
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                header!.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 0.6,
                    ),
              ),
            ),
          GlassPanel(child: Column(children: rows)),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),
              child: Text(
                footer!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.42, fontSize: 12),
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
    final color = tint ?? AppTheme.adaptiveIcon(context);

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint == null
            ? (isDark
                ? _alpha(Colors.white, 0.09)
                : _alpha(Colors.black, 0.045))
            : _alpha(tint!, isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: tint == null
              ? (isDark
                  ? _alpha(Colors.white, 0.10)
                  : _alpha(Colors.black, 0.05))
              : _alpha(tint!, 0.26),
        ),
      ),
      child: Icon(icon, size: 16.5, color: color),
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
        duration: const Duration(milliseconds: 110),
        color: _pressed
            ? (isDark
                ? _alpha(Colors.white, 0.05)
                : _alpha(Colors.black, 0.035))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SettingsIconTile(icon: widget.icon, tint: widget.tint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: widget.tint,
                        ),
                  ),
                  if (widget.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.detail!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.value != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  widget.value!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 14),
                ),
              ),
            if (widget.trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: widget.trailing!,
              ),
            if (widget.showChevron && widget.onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  IOSIcons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.adaptiveIcon(context, alpha: 0.7),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 15,
                        ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(IOSIcons.check_rounded,
                  size: 19, color: Theme.of(context).colorScheme.primary),
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
                  left: segWidth * index,
                  width: segWidth,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: isDark ? _alpha(Colors.white, 0.13) : Colors.white,
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
                                    ? Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color
                                    : AppTheme.adaptiveIcon(context),
                              ),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              seg.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    active ? FontWeight.w600 : FontWeight.w500,
                                color: active
                                    ? Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color
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
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 14),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
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
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w500, fontSize: 15),
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
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 15,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
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
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: widget.emphasised ? FontWeight.w600 : FontWeight.w400,
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
