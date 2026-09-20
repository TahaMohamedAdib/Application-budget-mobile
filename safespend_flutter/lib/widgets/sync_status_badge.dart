import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sync_engine.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../theme/ios_icons.dart';

/// What the sync state looks like to the user, in one place.
///
/// The phase alone is not enough to describe the state honestly: an idle
/// engine with queued work is waiting, not synced, and that distinction is
/// the whole point of showing this at all.
@immutable
class SyncPresentation {
  const SyncPresentation({
    required this.icon,
    required this.color,
    required this.label,
    this.detail,
    this.spins = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? detail;

  /// Whether the icon should animate — true only while work is in flight.
  final bool spins;

  /// Maps a snapshot onto its user-facing description.
  ///
  /// Order matters. Failures outrank everything because they need action;
  /// pending work outranks "idle" because an idle engine holding unsent
  /// edits must never claim to be synced.
  factory SyncPresentation.of(S s, SyncStatusSnapshot status) {
    if (status.failedCount > 0) {
      return SyncPresentation(
        icon: IOSIcons.error_outline_rounded,
        color: AppTheme.error,
        label: s.syncFailed,
        detail: s.tr('syncFailedDetail', {'count': status.failedCount}),
      );
    }

    if (status.phase == SyncPhase.syncing) {
      return SyncPresentation(
        icon: IOSIcons.autorenew_rounded,
        color: AppTheme.info,
        label: s.syncing,
        detail: status.hasPendingWork
            ? s.tr('syncPendingDetail', {'count': status.pendingCount})
            : null,
        spins: true,
      );
    }

    if (status.phase == SyncPhase.offline) {
      return SyncPresentation(
        icon: IOSIcons.warning_amber_rounded,
        color: AppTheme.warning,
        label: s.syncOffline,
        detail: status.hasPendingWork
            ? s.tr('syncPendingDetail', {'count': status.pendingCount})
            : s.syncOfflineDetail,
      );
    }

    // Idle or recovered-from-error, but still holding unsent work.
    if (status.hasPendingWork) {
      return SyncPresentation(
        icon: IOSIcons.autorenew_rounded,
        color: AppTheme.warning,
        label: s.syncPending,
        detail: s.tr('syncPendingDetail', {'count': status.pendingCount}),
      );
    }

    return SyncPresentation(
      icon: IOSIcons.check_circle_rounded,
      color: AppTheme.success,
      label: s.syncedToCloud,
      detail: null,
    );
  }
}

/// Live sync state, rebuilt from the engine rather than assumed.
///
/// Listens to the engine's [ValueListenable] directly instead of going
/// through `notifyListeners`, so a sync tick repaints this row alone and not
/// every screen watching the provider.
class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key, this.compact = false});

  /// Icon and label only — for a screen header, where there is no room for
  /// the explanatory second line.
  final bool compact;

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge> {
  ValueListenable<SyncStatusSnapshot>? _status;
  SyncStatusSnapshot _snapshot = const SyncStatusSnapshot();

  // Subscribed to by hand rather than through ValueListenableBuilder.
  //
  // The notifier belongs to the provider, which can be disposed before this
  // widget is unmounted — a teardown order that is normal in tests and
  // reachable in the app when a sign-out tears down the provider under an
  // open settings sheet. ValueListenableBuilder would then try to detach from
  // a disposed notifier and throw, so the listener is added and removed
  // explicitly and every interaction with the notifier tolerates failure.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_status != null) return;
    try {
      final status = context.read<AppProvider>().syncStatus;
      _status = status;
      _snapshot = status.value;
      status.addListener(_onStatusChanged);
    } on Object {
      _status = null;
    }
  }

  void _onStatusChanged() {
    final status = _status;
    if (status == null || !mounted) return;
    setState(() => _snapshot = status.value);
  }

  @override
  void dispose() {
    try {
      _status?.removeListener(_onStatusChanged);
    } on Object {
      // The provider was disposed first; the listener went with it.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) return const SizedBox.shrink();
    final s = S.of(context);
    final view = SyncPresentation.of(s, _snapshot);

    return Row(
      key: const Key('sync-status-badge'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SyncIcon(view: view),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                view.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: view.color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (!widget.compact && view.detail != null)
                Text(
                  view.detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Spins only while syncing, so the motion means something.
class _SyncIcon extends StatefulWidget {
  const _SyncIcon({required this.view});

  final SyncPresentation view;

  @override
  State<_SyncIcon> createState() => _SyncIconState();
}

class _SyncIconState extends State<_SyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Built here, not as a `late final` initializer. A lazily-created controller
  // is constructed on first use, which can be from dispose() for a widget
  // that never painted; `vsync: this` then resolves TickerMode against a
  // deactivated element, which throws.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.view.spins) _controller.repeat();
  }

  @override
  void didUpdateWidget(_SyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view.spins == oldWidget.view.spins) return;
    if (widget.view.spins) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.view.icon, size: 17, color: widget.view.color);
    if (!widget.view.spins) return icon;
    return RotationTransition(turns: _controller, child: icon);
  }
}
