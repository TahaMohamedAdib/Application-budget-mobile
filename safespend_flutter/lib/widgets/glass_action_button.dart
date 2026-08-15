import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Full-width action button in the same translucent "liquid glass" language as
/// the floating nav pill: a blurred capsule with a layered fill, a specular
/// sheen along the top edge, a hairline neutral rim and a soft drop shadow.
/// The only coloured element is the label.
///
/// Tapping scales it down slightly and fires a light haptic, so the press reads
/// as a physical response rather than a colour flash.
class GlassActionButton extends StatefulWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent,
    this.height = 58,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  /// Colours the label only — the rim and shadows stay neutral grey so the
  /// button doesn't read as tinted, particularly in dark mode. Defaults to the
  /// app's primary.
  final Color? accent;
  final double height;

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent ?? AppTheme.goldPrimary;
    final radius = BorderRadius.circular(widget.height / 2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: DecoratedBox(
          // Shadows sit outside the clip, so they live on an outer box.
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.09),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: _pressed ? 0.14 : 0.07),
                blurRadius: 20,
                spreadRadius: -8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: AppTheme.adaptiveIcon(context,
                        alpha: isDark ? 0.26 : 0.30),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.07),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.60),
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Specular sheen — a soft highlight over the top half that
                    // gives the surface its curved, glassy read.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: widget.height * 0.55,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white
                                    .withValues(alpha: isDark ? 0.10 : 0.55),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.icon,
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                  letterSpacing: -0.2,
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
    );
  }
}
