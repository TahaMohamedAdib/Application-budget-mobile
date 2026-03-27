import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Attachment previews ──────────────────────────────
          if (pendingImage != null) _buildImagePreview(),
          if (pendingFile != null) _buildFilePreview(),

          // ── Input row ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach [+] button — dark circle
              GestureDetector(
                onTap: onAttach,
                child: Container(
                  width: 38, height: 38,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Text field — separate pill
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
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
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask SafeSpend AI...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Send button — white circle when active, dark when inactive
              GestureDetector(
                onTap: _hasContent && !isTyping ? onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38, height: 38,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: _hasContent && !isTyping
                        ? Colors.white
                        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTyping ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                    size: 20,
                    color: _hasContent && !isTyping
                        ? Colors.black
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Image preview ─────────────────────────────────────────────
  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 48),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(pendingImage!),
              height: 90, width: 90,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onClearImage,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── File preview ──────────────────────────────────────────────
  Widget _buildFilePreview() {
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
    final border = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 48),
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 18),
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
                Icons.close_rounded, size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
