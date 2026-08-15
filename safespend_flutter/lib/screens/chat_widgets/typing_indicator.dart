import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

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
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 1, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.adaptiveIconSurface(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IOSIcons.auto_awesome_rounded,
              color: AppTheme.adaptiveIcon(context),
              size: 15,
            ),
          ),
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

class _ThinkingTextState extends State<_ThinkingText>
    with SingleTickerProviderStateMixin {
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
