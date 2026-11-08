import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/settings_ui.dart';
import '../../widgets/sync_status_badge.dart';
import '../../widgets/unsynced_work_guard.dart';

class DataStorageScreen extends StatelessWidget {
  const DataStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<AppProvider>();
    final auth = context.watch<AuthService>();

    return SettingsScaffold(
      title: s.dataAndStorage,
      subtitle: s.dataAndStorageSubtitle,
      children: [
        _StorageOverview(provider: provider),
        SettingsGroup(
          header: s.sync,
          footer: auth.localMode ? s.syncLocalModeFooter : s.syncFooter,
          children: [
            // Local mode has no server to sync with, so the badge would have
            // nothing truthful to say; the static label is correct there.
            if (auth.localMode)
              SettingsRow(
                icon: IOSIcons.autorenew_rounded,
                label: s.syncStatus,
                value: s.localMode,
                showChevron: false,
              )
            else
              SettingsRow(
                icon: IOSIcons.autorenew_rounded,
                label: s.syncStatus,
                trailing: const SyncStatusBadge(compact: true),
                showChevron: false,
                onTap: () => provider.syncNow(),
              ),
            if (!auth.localMode)
              SettingsRow(
                icon: IOSIcons.email_outlined,
                label: s.signedInAs,
                value: auth.user?.email ?? '—',
                showChevron: false,
              ),
          ],
        ),
        SettingsGroup(
          header: s.exportData,
          footer: s.exportFooter,
          children: [
            SettingsRow(
              icon: IOSIcons.picture_as_pdf_rounded,
              label: s.exportAsJson,
              detail: s.exportAsJsonDetail,
              onTap: () => _export(context, provider),
            ),
            SettingsRow(
              icon: IOSIcons.notes_rounded,
              label: s.copyToClipboard,
              detail: s.copyToClipboardDetail,
              onTap: () => _copy(context, provider),
            ),
          ],
        ),
        SettingsGroup(
          header: s.dangerZone,
          footer: s.dangerZoneFooter,
          children: [
            SettingsActionRow(
              icon: IOSIcons.delete_outline_rounded,
              label: s.clearLocalData,
              detail: s.clearLocalDataDetail,
              destructive: true,
              onTap: () => _clear(context, provider),
            ),
          ],
        ),
      ],
    );
  }

  static Map<String, dynamic> _buildExport(AppProvider p) => {
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': 1,
        'settings': p.settings.toJson(),
        'accounts': p.accounts.map((e) => e.toJson()).toList(),
        'transactions': p.transactions.map((e) => e.toJson()).toList(),
        'categories': p.categories.map((e) => e.toJson()).toList(),
        'recurringRules': p.recurringRules.map((e) => e.toJson()).toList(),
        'holdings': p.holdings.map((e) => e.toJson()).toList(),
        'goals': p.goals.map((e) => e.toJson()).toList(),
        'darets': p.darets.map((e) => e.toJson()).toList(),
      };

  static Future<void> _export(BuildContext context, AppProvider p) async {
    final s = S.of(context);
    final json = const JsonEncoder.withIndent('  ').convert(_buildExport(p));
    final bytes = Uint8List.fromList(utf8.encode(json));
    final name =
        'safespend-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: s.exportData,
        fileName: name,
        bytes: bytes,
      );
      if (!context.mounted) return;
      showSettingsToast(
        context,
        path == null ? s.exportCancelled : s.exportSaved,
      );
    } catch (e) {
      // saveFile is not implemented on every platform/version; the clipboard
      // route below always works, so point the user at it rather than failing.
      if (kDebugMode) debugPrint('[Export] saveFile failed: $e');
      if (!context.mounted) return;
      showSettingsToast(context, s.exportUseClipboard);
    }
  }

  static Future<void> _copy(BuildContext context, AppProvider p) async {
    final s = S.of(context);
    final json = const JsonEncoder.withIndent('  ').convert(_buildExport(p));
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    showSettingsToast(context, s.copiedToClipboard);
  }

  static Future<void> _clear(BuildContext context, AppProvider p) async {
    final s = S.of(context);
    final ok = await showSettingsConfirm(
      context,
      title: s.clearLocalData,
      message: s.clearLocalDataConfirm,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    // Clearing local data destroys the sync queue along with it.
    if (!await UnsyncedWorkGuard.confirm(context, p)) return;
    if (!context.mounted) return;

    await p.clearData();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _StorageOverview extends StatelessWidget {
  const _StorageOverview({required this.provider});

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = <({String label, int count})>[
      (label: s.accounts, count: provider.accounts.length),
      (label: s.transactions, count: provider.transactions.length),
      (label: s.goals, count: provider.goals.length),
      (label: s.holdings, count: provider.holdings.length),
      (label: s.budgets, count: provider.categories.length),
      (label: s.daret, count: provider.darets.length),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: GlassPanel(
        elevated: true,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.storedOnThisDevice,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              children: items.map((item) {
                return SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 36 - 36) / 3,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.count}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            Row(
              children: [
                Icon(IOSIcons.info_outline_rounded,
                    size: 13, color: AppTheme.adaptiveIcon(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.storageOverviewNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
