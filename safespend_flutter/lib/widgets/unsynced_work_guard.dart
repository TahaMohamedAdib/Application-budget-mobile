import 'package:flutter/material.dart';

import '../data/sync_engine.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import 'settings_ui.dart';

/// Asks before an action that would discard work the server has never seen.
///
/// Signing out and clearing local data both wipe the local database. Anything
/// still sitting in the sync queue at that moment is gone for good — it exists
/// nowhere else. The user is entitled to know that before they confirm, and to
/// a chance to get the work uploaded first.
///
/// Returns true when the caller should proceed.
class UnsyncedWorkGuard {
  const UnsyncedWorkGuard._();

  /// Shows the warning only when there is genuinely unsynced work.
  ///
  /// A user with nothing pending sees no extra dialog; adding a second
  /// confirmation to every sign-out would train people to tap through it, and
  /// then it would not be read on the one occasion it matters.
  static Future<bool> confirm(
    BuildContext context,
    AppProvider provider,
  ) async {
    final SyncStatusSnapshot status = provider.syncStatus.value;
    final pending = status.pendingCount + status.failedCount;

    // Fall back to the database when the engine has not reported counts yet
    // (it starts at zero), so a cold start does not skip the warning.
    final hasWork = pending > 0 || await provider.hasUnsyncedChanges();
    if (!hasWork) return true;
    if (!context.mounted) return false;

    final s = S.of(context);
    return showSettingsConfirm(
      context,
      title: s.unsyncedWarningTitle,
      message: s.tr('unsyncedWarningMessage', {
        'count': pending > 0 ? pending : 1,
      }),
      confirmLabel: s.unsyncedWarningContinue,
      cancelLabel: s.cancel,
      destructive: true,
    );
  }
}
