import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SuggestionCard extends StatelessWidget {
  final String text;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDark;

  const SuggestionCard({
    super.key,
    required this.text,
    required this.onTap,
    required this.isDark,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: isDark
              ? Colors.white.withOpacity(0.055)
              : const Color(0xFFF2F3F4).withOpacity(0.88),
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 96),
              padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.95),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.adaptiveIconSurface(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          size: 16, color: AppTheme.adaptiveIcon(context)),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
