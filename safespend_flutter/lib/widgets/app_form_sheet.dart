import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

Color _sheetAlpha(Color color, double value) => color.withValues(alpha: value);

typedef AppFormSheetBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
);

class AppFormSheet extends StatelessWidget {
  final AppFormSheetBuilder builder;
  final double initialChildSize;
  final double minChildSize;

  const AppFormSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.92,
    this.minChildSize = 0.42,
  });

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

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: initialChildSize,
      expand: false,
      snap: true,
      snapSizes: [minChildSize, initialChildSize],
      snapAnimationDuration: const Duration(milliseconds: 260),
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? _sheetAlpha(const Color(0xFF111214), 0.92)
                  : _sheetAlpha(const Color(0xFFF7F7F9), 0.90),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(34)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? _sheetAlpha(Colors.white, 0.14)
                      : _sheetAlpha(Colors.white, 0.92),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: _sheetAlpha(Colors.black, isDark ? 0.56 : 0.18),
                  blurRadius: 38,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Theme(
              data: theme.copyWith(inputDecorationTheme: inputTheme),
              child: builder(context, scrollController),
            ),
          ),
        ),
      ),
    );
  }
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 50),
      ],
    );
  }
}
