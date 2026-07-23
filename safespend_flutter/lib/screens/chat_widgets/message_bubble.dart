import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;
  final bool isDark;
  final String? imagePath;
  final String? filePath;
  final String? fileName;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.isDark,
    this.isError = false,
    this.imagePath,
    this.filePath,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return isUser ? _buildUserBubble(context) : _buildAssistantMessage(context);
  }

  // ── User message — dark gray bubble, right-aligned ─────────
  Widget _buildUserBubble(BuildContext context) {
    final bubbleColor = isDark ? const Color(0xFF303030) : const Color(0xFFEFEFEF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 52),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath!),
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 220, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.broken_image_rounded, size: 36, color: Colors.white30),
                    ),
                  ),
                ),
                if (text.isNotEmpty && text != '📷 Image') const SizedBox(height: 10),
              ],
              if (filePath != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          fileName ?? 'Document',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (text.isNotEmpty && !text.startsWith('📄')) const SizedBox(height: 10),
              ],
              if (text.isNotEmpty && text != '📷 Image' && !text.startsWith('📄'))
                Text(
                  text,
                  style: GoogleFonts.inter(fontSize: 15, color: textColor, height: 1.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Assistant message — NO bubble, plain text like ChatGPT ─
  Widget _buildAssistantMessage(BuildContext context) {
    final textColor = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small avatar
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
          // Content — no bubble, just text
          Flexible(
            child: isError ? _buildErrorContent() : _buildMarkdownContent(textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.redAccent, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(Color textColor) {
    final strongColor = isDark ? Colors.white : const Color(0xFF0D0D0D);

    // No container/bubble — just raw markdown text
    return MarkdownBody(
      data: text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(fontSize: 15, color: textColor, height: 1.6),
        strong: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: strongColor, height: 1.6),
        em: GoogleFonts.inter(fontSize: 15, fontStyle: FontStyle.italic, color: textColor, height: 1.6),
        listBullet: GoogleFonts.inter(fontSize: 15, color: textColor, height: 1.6),
        h1: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: strongColor, height: 1.4),
        h2: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: strongColor, height: 1.4),
        h3: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: strongColor, height: 1.4),
        code: GoogleFonts.firaCode(
          fontSize: 13,
          color: AppTheme.brandPrimary,
          backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(10),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        blockSpacing: 12,
        listIndent: 18,
        listBulletPadding: const EdgeInsets.only(right: 8),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.15), width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
          ),
        ),
      ),
    );
  }
}
