import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
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
  final VoidCallback onClearImage;
  final VoidCallback onClearFile;
  final ValueChanged<String>? onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.isDark,
    required this.onSend,
    required this.onAttach,
    required this.onClearImage,
    required this.onClearFile,
    this.pendingImage,
    this.pendingFile,
    this.pendingFileName,
    this.onChanged,
  });

  bool get _hasContent =>
      controller.text.isNotEmpty || pendingImage != null || pendingFile != null;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final canSend = _hasContent && !isTyping;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingImage != null) _buildImagePreview(),
          if (pendingFile != null) _buildFilePreview(context),
          ClipRRect(
            borderRadius: BorderRadius.circular(29),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252728).withOpacity(0.94)
                      : const Color(0xFFF0F2F3).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.11)
                        : Colors.white.withOpacity(0.98),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Attach',
                      child: IconButton(
                        onPressed: isTyping ? null : onAttach,
                        constraints: const BoxConstraints.tightFor(
                            width: 52, height: 54),
                        icon: Icon(
                          IOSIcons.add_rounded,
                          size: 25,
                          color: isTyping
                              ? foreground.withOpacity(0.25)
                              : foreground.withOpacity(0.82),
                        ),
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
                          height: 1.35,
                          color: foreground,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask SafeSpend AI',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: isDark
                                ? AppTheme.darkTextTertiary
                                : AppTheme.lightTextTertiary,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: canSend
                              ? AppTheme.goldPrimary
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06)),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: isTyping ? 'Thinking' : 'Send',
                          padding: EdgeInsets.zero,
                          onPressed: canSend ? onSend : null,
                          icon: isTyping
                              ? SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: foreground.withOpacity(0.45),
                                  ),
                                )
                              : Icon(
                                  IOSIcons.arrow_upward_rounded,
                                  size: 19,
                                  color: canSend
                                      ? Colors.white
                                      : foreground.withOpacity(0.28),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Image preview ─────────────────────────────────────────────
  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(pendingImage!),
              height: 90,
              width: 90,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onClearImage,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IOSIcons.close_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── File preview ──────────────────────────────────────────────
  Widget _buildFilePreview(BuildContext context) {
    final bg = isDark ? const Color(0xFF252728) : const Color(0xFFF0F2F3);
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.adaptiveIconSurface(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(IOSIcons.picture_as_pdf_rounded,
                  color: AppTheme.adaptiveIcon(context), size: 18),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                pendingFileName ?? 'Document',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onClearFile,
              child: Icon(
                IOSIcons.close_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
