import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
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
    final bubbleColor =
        isDark ? const Color(0xFF2A2D2E) : const Color(0xFFEFF1F2);
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 56),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.white.withOpacity(0.95),
            ),
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
                      width: 220,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(IOSIcons.broken_image_rounded,
                          size: 36, color: Colors.white30),
                    ),
                  ),
                ),
                if (text.isNotEmpty && text != '📷 Image')
                  const SizedBox(height: 10),
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
                          color: AppTheme.adaptiveIconSurface(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(IOSIcons.picture_as_pdf_rounded,
                            color: AppTheme.adaptiveIcon(context), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          fileName ?? 'Document',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (text.isNotEmpty && !text.startsWith('📄'))
                  const SizedBox(height: 10),
              ],
              if (text.isNotEmpty &&
                  text != '📷 Image' &&
                  !text.startsWith('📄'))
                Text(
                  text,
                  style: GoogleFonts.inter(
                      fontSize: 15, color: textColor, height: 1.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Assistant message — NO bubble, plain text like ChatGPT ─
  Widget _buildAssistantMessage(BuildContext context) {
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28, right: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small avatar
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
          // Content — no bubble, just text
          Flexible(
            child: isError
                ? _buildErrorContent(context)
                : _buildMarkdownContent(textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
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
          Icon(IOSIcons.error_outline_rounded,
              size: 18, color: AppTheme.adaptiveIcon(context)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 14, color: Colors.redAccent, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(Color textColor) {
    final strongColor = isDark ? Colors.white : AppTheme.lightTextPrimary;

    // No container/bubble — just raw markdown text
    return MarkdownBody(
      data: text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(fontSize: 15, color: textColor, height: 1.6),
        strong: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: strongColor,
            height: 1.6),
        em: GoogleFonts.inter(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: textColor,
            height: 1.6),
        listBullet:
            GoogleFonts.inter(fontSize: 15, color: textColor, height: 1.6),
        h1: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: strongColor,
            height: 1.4),
        h2: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: strongColor,
            height: 1.4),
        h3: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: strongColor,
            height: 1.4),
        code: GoogleFonts.firaCode(
          fontSize: 13,
          color: AppTheme.goldPrimary,
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF242627) : const Color(0xFFEFF1F2),
          borderRadius: BorderRadius.circular(10),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        blockSpacing: 12,
        listIndent: 18,
        listBulletPadding: const EdgeInsets.only(right: 8),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: AppTheme.goldPrimary.withOpacity(0.7), width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08)),
          ),
        ),
      ),
    );
  }
}
