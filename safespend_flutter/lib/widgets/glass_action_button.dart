import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A full-width, neutral capsule action with the app's existing dimensions,
/// press feedback and haptic response.
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

  /// Optional label colour; otherwise uses the theme's normal text colour.
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
    final accent =
        widget.accent ?? Theme.of(context).textTheme.titleMedium?.color;
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
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isDark ? const Color(0xFF242626) : const Color(0xFFF1F2F3),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.icon,
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                        letterSpacing: -0.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
