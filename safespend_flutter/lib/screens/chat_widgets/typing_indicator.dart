import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChatGPT-style "Thinking..." indicator with subtle dots.
class TypingIndicator extends StatelessWidget {
  final bool isDark;
  const TypingIndicator({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (matches assistant avatar)
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(top: 2, right: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 14,
            ),
          ),
          // "Thinking..." text with animated dots
          _ThinkingText(isDark: isDark),
        ],
      ),
    );
  }
}

class _ThinkingText extends StatefulWidget {
  final bool isDark;
  const _ThinkingText({required this.isDark});
  @override
  State<_ThinkingText> createState() => _ThinkingTextState();
}

class _ThinkingTextState extends State<_ThinkingText> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final dots = '.' * ((_ctrl.value * 4).floor() % 4);
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Thinking$dots',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: widget.isDark ? Colors.white38 : Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
    );
  }
}
