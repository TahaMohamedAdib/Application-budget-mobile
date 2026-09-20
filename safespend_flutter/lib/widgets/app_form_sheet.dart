import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/ios_icons.dart';

/// Shared add/edit presentation. The route handles swipe-to-dismiss;
/// scrolling fields never resize the sheet or move its close control away.
class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.header,
    required this.body,
    this.actions,
    this.headerIncludesCloseButton = false,
    this.surfaceKey = const ValueKey('app-form-sheet-surface'),
    this.fieldsKey = const ValueKey('app-form-sheet-fields'),
  });

  final Widget header;
  final Widget body;
  final Widget? actions;
  final bool headerIncludesCloseButton;
  final Key surfaceKey;
  final Key fieldsKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controlFill = isDark
        ? _sheetAlpha(Colors.white, 0.055)
        : _sheetAlpha(Colors.white, 0.76);
    final controlBorder = isDark
        ? _sheetAlpha(Colors.white, 0.10)
        : _sheetAlpha(Colors.black, 0.07);
    final inputTheme = theme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: controlFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: controlBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: controlBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
    );

    final media = MediaQuery.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 8
        : math.max(12.0, media.padding.bottom);

    return AnimatedPadding(
      duration: media.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(10, 12, 10, bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = math.min(
            constraints.maxHeight,
            math.min(680.0, media.size.height * 0.74),
          );
          // In landscape or at large text sizes, let actions scroll with the
          // fields so a keyboard cannot squeeze the form to an unusable strip.
          final inlineActions = height < 400 || media.textScaler.scale(1) > 1.4;
          final radius = BorderRadius.circular(32);

          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: Container(
              key: surfaceKey,
              height: height,
              constraints: const BoxConstraints(maxWidth: 560),
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.4 : 0.16),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: (dark
                              ? const Color(0xFF111214)
                              : const Color(0xFFF7F7F9))
                          .withValues(alpha: 0.94),
                      borderRadius: radius,
                      border: Border.all(
                        color:
                            Colors.white.withValues(alpha: dark ? 0.14 : 0.9),
                      ),
                    ),
                    child: Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: inputTheme,
                        elevatedButtonTheme: ElevatedButtonThemeData(
                          style: (theme.elevatedButtonTheme.style ??
                                  const ButtonStyle())
                              .copyWith(
                            textStyle: WidgetStatePropertyAll(
                                theme.textTheme.labelLarge),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 14, 8),
                            child: Column(
                              children: [
                                const AppFormSheetHandle(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: header),
                                    if (!headerIncludesCloseButton) ...[
                                      const SizedBox(width: 8),
                                      const AppFormSheetCloseButton(),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(
                              height: 1, color: Theme.of(context).dividerColor),
                          Expanded(
                            child: SingleChildScrollView(
                              key: fieldsKey,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  body,
                                  if (inlineActions && actions != null) ...[
                                    const SizedBox(height: 16),
                                    actions!
                                  ]
                                ],
                              ),
                            ),
                          ),
                          if (!inlineActions && actions != null) ...[
                            Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 14),
                              child: actions,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One modal route for every add/edit form, including transaction entry.
Future<T?> showAppFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    requestFocus: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    constraints: const BoxConstraints(maxWidth: 580),
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 340),
            reverseDuration: Duration(milliseconds: 240),
          ),
    builder: (context) => AppFormSheetScope(
      child: Builder(builder: builder),
    ),
  );
}

/// Lets full-page settings widgets use the same chrome when opened as editors.
class AppFormSheetScope extends InheritedWidget {
  const AppFormSheetScope({super.key, required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppFormSheetScope>() != null;

  @override
  bool updateShouldNotify(AppFormSheetScope oldWidget) => false;
}

Color _sheetAlpha(Color color, double value) => color.withValues(alpha: value);

class AppFormSheetCloseButton extends StatelessWidget {
  const AppFormSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        key: const ValueKey('app-form-sheet-close'),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: S.of(context).close,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          maximumSize: const Size.square(44),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          foregroundColor: Theme.of(context).textTheme.titleMedium?.color,
        ),
        icon: const Icon(IOSIcons.close_rounded, size: 20),
      );
}

class AppFormSheetHandle extends StatelessWidget {
  const AppFormSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: isDark
              ? _sheetAlpha(Colors.white, 0.16)
              : _sheetAlpha(Colors.black, 0.14),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class AppFormSheetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;

  const AppFormSheetHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _sheetAlpha(accent, isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _sheetAlpha(accent, 0.28)),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
