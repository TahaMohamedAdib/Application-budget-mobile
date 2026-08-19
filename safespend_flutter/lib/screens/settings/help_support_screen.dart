import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/settings_ui.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const supportEmail = 'support@safespend.app';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SettingsScaffold(
      title: s.helpAndSupport,
      subtitle: s.helpAndSupportSubtitle,
      children: [
        SettingsGroup(
          header: s.frequentlyAsked,
          children: [
            _Faq(q: s.helpQ1, a: s.helpA1),
            _Faq(q: s.helpQ2, a: s.helpA2),
            _Faq(q: s.helpQ3, a: s.helpA3),
            _Faq(q: s.helpQ4, a: s.helpA4),
            _Faq(q: s.helpQ5, a: s.helpA5),
          ],
        ),
        SettingsGroup(
          header: s.contact,
          footer: s.contactFooter,
          children: [
            SettingsRow(
              icon: IOSIcons.email_rounded,
              label: s.emailSupport,
              detail: supportEmail,
              onTap: () async {
                await Clipboard.setData(
                    const ClipboardData(text: supportEmail));
                if (context.mounted) {
                  showSettingsToast(context, S.of(context).emailCopied);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Expandable FAQ row. Collapsed by default so the list stays scannable.
class _Faq extends StatefulWidget {
  const _Faq({required this.q, required this.a});

  final String q;
  final String a;

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> with SingleTickerProviderStateMixin {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _open = !_open);
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.q,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(IOSIcons.expand_more_rounded,
                        size: 20, color: AppTheme.adaptiveIcon(context)),
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 8),
                Text(
                  widget.a,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
