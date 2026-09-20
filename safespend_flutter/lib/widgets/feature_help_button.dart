import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';

/// A reusable, always-available explanation for the screen the user is on.
class FeatureHelpButton extends StatelessWidget {
  const FeatureHelpButton({
    super.key,
    required this.title,
    required this.description,
    this.icon = IOSIcons.help_outline_rounded,
    this.points = const [],
    this.size = 40,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> points;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: S.of(context).helpAndSupport,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('feature-help-button'),
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            showFeatureHelpSheet(
              context,
              title: title,
              description: description,
              icon: icon,
              points: points,
            );
          },
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.82),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.11)
                    : Colors.black.withValues(alpha: 0.07),
              ),
            ),
            child: Icon(IOSIcons.help_outline_rounded,
                size: size * 0.48, color: AppTheme.adaptiveIcon(context)),
          ),
        ),
      ),
    );
  }
}

Future<void> showFeatureHelpSheet(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  List<String> points = const [],
}) {
  final s = S.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: (sheetContext) {
      final dark = Theme.of(sheetContext).brightness == Brightness.dark;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            color: dark
                ? const Color(0xFF1C1E1F).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.97),
            padding: EdgeInsets.fromLTRB(
              24,
              14,
              24,
              18 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).dividerColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: AppTheme.goldPrimary, size: 27),
                  ),
                  const SizedBox(height: 16),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: Theme.of(sheetContext).textTheme.headlineSmall),
                  const SizedBox(height: 9),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.45),
                  ),
                  if (points.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...points.where((point) => point.trim().isNotEmpty).map(
                          (point) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(IOSIcons.check_circle_rounded,
                                    size: 19, color: AppTheme.goldPrimary),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(point,
                                      style: Theme.of(sheetContext)
                                          .textTheme
                                          .bodyMedium),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(s.gotIt),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
