import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

Color _alpha(Color color, double value) => color.withValues(alpha: value);

typedef AppPickerTriggerBuilder<T> = Widget Function(
  BuildContext context,
  AppPickerItem<T>? selected,
  VoidCallback open,
);

/// A tap-to-pick field with a compact, anchored glass popover.
/// Drop-in replacement for DropdownButtonFormField inside forms and modals.
class AppPickerField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<AppPickerItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? prefixIcon;
  final String? helperText;
  final AppPickerTriggerBuilder<T>? triggerBuilder;

  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.helperText,
    this.triggerBuilder,
  });

  AppPickerItem<T>? get _selected =>
      items.where((i) => i.value == value).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selected;

    if (triggerBuilder != null) {
      return triggerBuilder!(context, selected, () => _open(context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _open(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasSelectedVisual =
                  selected?.imagePath != null || selected?.leadingIcon != null;
              final isCompact = constraints.maxWidth < 210;
              final showPrefix =
                  prefixIcon != null && (!isCompact || !hasSelectedVisual);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minHeight: 64),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? _alpha(Colors.white, 0.052)
                      : _alpha(Colors.white, 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? _alpha(Colors.white, 0.10)
                        : _alpha(Colors.black, 0.065),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _alpha(Colors.black, isDark ? 0.18 : 0.07),
                      blurRadius: 18,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (showPrefix) ...[
                      AppIcon(
                        prefixIcon!,
                        size: 19,
                        color: AppTheme.adaptiveIcon(context),
                      ),
                      SizedBox(width: isCompact ? 8 : 12),
                    ],
                    if (selected?.imagePath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: selected!.imagePath!.startsWith('http')
                            ? Image.network(
                                selected.imagePath!,
                                width: 18,
                                height: 18,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    selected.leadingIcon != null
                                        ? AppIcon(
                                            selected.leadingIcon!,
                                            size: 18,
                                            color: selected.iconColor ??
                                                AppTheme.adaptiveIcon(context),
                                          )
                                        : const SizedBox(width: 18, height: 18),
                              )
                            : Image.file(
                                File(selected.imagePath!),
                                width: 18,
                                height: 18,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    selected.leadingIcon != null
                                        ? AppIcon(
                                            selected.leadingIcon!,
                                            size: 18,
                                            color: selected.iconColor ??
                                                AppTheme.adaptiveIcon(context),
                                          )
                                        : const SizedBox(width: 18, height: 18),
                              ),
                      ),
                      SizedBox(width: isCompact ? 8 : 10),
                    ] else if (selected?.leadingIcon != null) ...[
                      AppIcon(
                        selected!.leadingIcon!,
                        size: 18,
                        color: selected.iconColor,
                      ),
                      SizedBox(width: isCompact ? 8 : 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: double.infinity,
                            height: 20,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                selected?.label ?? 'Select…',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: selected == null
                                      ? (isDark
                                          ? Colors.white38
                                          : Colors.black38)
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppIcon(
                      AppIcons.caretDown,
                      size: 18,
                      color: AppTheme.adaptiveIcon(context, alpha: 0.72),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(helperText!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black45,
                )),
          ),
        ],
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final targetBox = context.findRenderObject() as RenderBox?;
    final targetRect = targetBox == null
        ? Rect.fromCenter(
            center: mediaQuery.size.center(Offset.zero),
            width: 280,
            height: 52,
          )
        : targetBox.localToGlobal(Offset.zero) & targetBox.size;
    final bottomInset = mediaQuery.viewInsets.bottom > mediaQuery.padding.bottom
        ? mediaQuery.viewInsets.bottom
        : mediaQuery.padding.bottom;
    final safeInsets = EdgeInsets.fromLTRB(
      mediaQuery.padding.left,
      mediaQuery.padding.top,
      mediaQuery.padding.right,
      bottomInset,
    );

    final picked = await showGeneralDialog<AppPickerItem<T>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: _alpha(Colors.black, isDark ? 0.28 : 0.08),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        final screenWidth = MediaQuery.sizeOf(dialogContext).width;
        final availableWidth = screenWidth - 32;
        var popoverWidth = targetRect.width < 280 ? 280.0 : targetRect.width;
        if (popoverWidth > 360) popoverWidth = 360;
        if (popoverWidth > availableWidth) popoverWidth = availableWidth;

        return CustomSingleChildLayout(
          delegate: _PickerPositionDelegate(
            targetRect: targetRect,
            safeInsets: safeInsets,
            width: popoverWidth,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? _alpha(const Color(0xFF171719), 0.88)
                      : _alpha(const Color(0xFFFDFDFD), 0.84),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? _alpha(Colors.white, 0.14)
                        : _alpha(Colors.white, 0.90),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _alpha(Colors.black, isDark ? 0.42 : 0.18),
                      blurRadius: 34,
                      spreadRadius: -8,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? _alpha(Colors.white, 0.94)
                                          : _alpha(Colors.black, 0.88),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _selected?.label ?? 'Select an option',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? _alpha(Colors.white, 0.48)
                                          : _alpha(Colors.black, 0.48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppIcon(
                              AppIcons.caretDown,
                              size: 19,
                              color: AppTheme.adaptiveIcon(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? _alpha(Colors.white, 0.08)
                            : _alpha(Colors.black, 0.07),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            final isSelected = item.value == value;
                            return _PickerOption<T>(
                              item: item,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () => Navigator.pop(dialogContext, item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (picked != null) onChanged(picked.value);
  }
}

class _PickerOption<T> extends StatelessWidget {
  final AppPickerItem<T> item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerOption({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.iconColor ?? AppTheme.adaptiveIcon(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minHeight: 52),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? _alpha(Colors.white, 0.13)
                  : _alpha(Colors.black, 0.075))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (item.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: item.imagePath!.startsWith('http')
                    ? Image.network(
                        item.imagePath!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallbackIcon(context, accent),
                      )
                    : Image.file(
                        File(item.imagePath!),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallbackIcon(context, accent),
                      ),
              ),
              const SizedBox(width: 12),
            ] else if (item.leadingIcon != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveIconSurface(context),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: AppIcon(item.leadingIcon!, size: 17, color: accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark
                          ? _alpha(Colors.white, 0.92)
                          : _alpha(Colors.black, 0.86),
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? _alpha(Colors.white, 0.46)
                            : _alpha(Colors.black, 0.48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Icon(IOSIcons.check_rounded,
                  size: 20, color: AppTheme.adaptiveIcon(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context, Color accent) {
    if (item.leadingIcon == null) return const SizedBox(width: 32, height: 32);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      color: AppTheme.adaptiveIconSurface(context),
      child: AppIcon(item.leadingIcon!, size: 17, color: accent),
    );
  }
}

class _PickerPositionDelegate extends SingleChildLayoutDelegate {
  final Rect targetRect;
  final EdgeInsets safeInsets;
  final double width;

  const _PickerPositionDelegate({
    required this.targetRect,
    required this.safeInsets,
    required this.width,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final availableHeight =
        constraints.maxHeight - safeInsets.top - safeInsets.bottom - 24;
    final maxHeight = availableHeight < 420 ? availableHeight : 420.0;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: maxHeight < 120 ? 120 : maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minLeft = safeInsets.left + 16;
    final maxLeft = size.width - safeInsets.right - childSize.width - 16;
    final idealLeft = targetRect.center.dx - (childSize.width / 2);
    final left = idealLeft.clamp(minLeft, maxLeft).toDouble();

    final minTop = safeInsets.top + 12;
    final maxBottom = size.height - safeInsets.bottom - 12;
    final below = targetRect.bottom + 8;
    final above = targetRect.top - childSize.height - 8;
    late final double top;

    if (below + childSize.height <= maxBottom) {
      top = below;
    } else if (above >= minTop) {
      top = above;
    } else {
      final centered = minTop +
          ((maxBottom - minTop - childSize.height).clamp(0, double.infinity) /
              2);
      top = centered.clamp(minTop, maxBottom - childSize.height).toDouble();
    }

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _PickerPositionDelegate oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        safeInsets != oldDelegate.safeInsets ||
        width != oldDelegate.width;
  }
}

class AppPickerItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String? leadingIcon;
  final Color? iconColor;
  final String? imagePath;

  const AppPickerItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.leadingIcon,
    this.iconColor,
    this.imagePath,
  });
}
