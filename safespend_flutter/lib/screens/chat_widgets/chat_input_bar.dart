import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final bool isDark;
  final String? pendingImage;
  final String? pendingFile;
  final String? pendingFileName;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final VoidCallback onClearImage;
  final VoidCallback onClearFile;
  final ValueChanged<String>? onChanged;
  final bool isListening;
  final bool isVoiceCallActive;
  final bool isSpeaking;
  final VoidCallback? onEndVoiceCall;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.isDark,
    required this.onSend,
    required this.onAttach,
    required this.onVoice,
    required this.onClearImage,
    required this.onClearFile,
    this.isListening = false,
    this.isVoiceCallActive = false,
    this.isSpeaking = false,
    this.onEndVoiceCall,
    this.pendingImage,
    this.pendingFile,
    this.pendingFileName,
    this.onChanged,
  });

  bool get _hasText => controller.text.trim().isNotEmpty;
  bool get _hasContent =>
      _hasText || pendingImage != null || pendingFile != null;

  @override
  Widget build(BuildContext context) {
    final shellColor = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: shellColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVoiceCallActive) ...[
            _VoiceCallStatus(
              isDark: isDark,
              isListening: isListening,
              isSpeaking: isSpeaking,
              onEnd: onEndVoiceCall,
            ),
            const SizedBox(height: 8),
          ],
          if (pendingImage != null || pendingFile != null) ...[
            _buildAttachmentTray(),
            const SizedBox(height: 8),
          ],
          _buildComposer(context),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final fillColor =
        isDark ? const Color(0xFF191919) : const Color(0xFFF5F6F7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: _ActionIconButton(
              tooltip: 'Attach',
              icon: Icons.add_rounded,
              isDark: isDark,
              onTap: isTyping ? null : onAttach,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isTyping,
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF161616),
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText: isVoiceCallActive
                    ? isListening
                        ? 'Listening...'
                        : isSpeaking
                            ? 'SafeSpend AI is speaking...'
                            : 'Voice call is active'
                    : 'Ask SafeSpend AI',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.34)
                      : Colors.black.withValues(alpha: 0.34),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIconButton(
                  tooltip: isListening ? 'Stop listening' : 'Voice input',
                  icon: isVoiceCallActive && isListening
                      ? Icons.stop_rounded
                      : Icons.call_rounded,
                  isDark: isDark,
                  isActive: isVoiceCallActive,
                  activeColor: const Color(0xFFE11D48),
                  onTap: isTyping ? null : onVoice,
                ),
                const SizedBox(width: 4),
                _ActionIconButton(
                  tooltip: 'Send',
                  icon: isTyping
                      ? Icons.hourglass_top_rounded
                      : Icons.arrow_upward_rounded,
                  isDark: isDark,
                  isPrimary: _hasContent && !isTyping,
                  onTap: _hasContent && !isTyping ? onSend : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTray() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (pendingImage != null)
            _ImageAttachment(path: pendingImage!, onClear: onClearImage),
          if (pendingImage != null && pendingFile != null)
            const SizedBox(width: 8),
          if (pendingFile != null)
            _FileAttachment(
              name: pendingFileName ?? 'Document',
              isDark: isDark,
              onClear: onClearFile,
            ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isDark;
  final bool isPrimary;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.isDark,
    this.isPrimary = false,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = isPrimary
        ? AppTheme.brandPrimary
        : isActive
            ? (activeColor ?? AppTheme.brandPrimary)
            : Colors.transparent;
    final fg = isPrimary || isActive
        ? Colors.white
        : enabled
            ? (isDark ? Colors.white70 : Colors.black54)
            : (isDark ? Colors.white24 : Colors.black26);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}

class _VoiceCallStatus extends StatelessWidget {
  final bool isDark;
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback? onEnd;

  const _VoiceCallStatus({
    required this.isDark,
    required this.isListening,
    required this.isSpeaking,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final label = isListening
        ? 'Listening'
        : isSpeaking
            ? 'Speaking'
            : 'Thinking';
    final bg = isDark
        ? const Color(0xFFE11D48).withValues(alpha: 0.14)
        : const Color(0xFFE11D48).withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDot(),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE11D48),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEnd,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFE11D48),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFE11D48),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  final String path;
  final VoidCallback onClear;

  const _ImageAttachment({required this.path, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _ClearButton(onTap: onClear),
          ),
        ],
      ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  final String name;
  final bool isDark;
  final VoidCallback onClear;

  const _FileAttachment({
    required this.name,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF191919) : const Color(0xFFF5F6F7);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      height: 48,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 16,
              color: Color(0xFFE11D48),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF171717),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ClearButton(onTap: onClear),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.66),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      ),
    );
  }
}
