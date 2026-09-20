import 'dart:io';

import 'package:flutter/material.dart';

import '../services/supabase_sync_service.dart';

/// Displays an image the app has stored, wherever it actually lives.
///
/// A stored reference is one of three things, and call sites should not have
/// to care which:
///
///  - a **storage object path** (`{uid}/{uuid}.jpg`) — what the app persists
///    now. Private buckets mean the URL must be signed on demand.
///  - a **local file path** — an image picked but not yet uploaded, or one
///    that failed to upload and is still only on this device.
///  - a **full URL** — rows written by older builds, before paths were stored.
///
/// The signed URL is fetched asynchronously and cached by the sync service,
/// so scrolling a list does not re-sign the same object every frame.
class StoredImage extends StatefulWidget {
  const StoredImage({
    super.key,
    required this.reference,
    this.bucket = SupabaseSyncService.receiptsBucket,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  /// The value persisted on the model: object path, local path, or URL.
  final String? reference;

  /// Which bucket an object path belongs to.
  final String bucket;

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Shown while the URL is being resolved.
  final Widget? placeholder;

  /// Shown when the image cannot be loaded at all.
  final Widget? errorWidget;

  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  /// Null while resolving; set once the reference has been turned into
  /// something loadable, or into a definitive failure.
  Future<String?>? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(StoredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve when the row's stored value changes, e.g. after an upload
    // swaps a local path for an object path.
    if (oldWidget.reference != widget.reference ||
        oldWidget.bucket != widget.bucket) {
      _resolve();
    }
  }

  void _resolve() {
    final ref = widget.reference;
    if (ref == null || ref.isEmpty) {
      _resolved = Future.value(null);
      return;
    }
    // A local file needs no round-trip; show it immediately.
    if (_isLocalPath(ref)) {
      _resolved = Future.value(ref);
      return;
    }
    _resolved = SupabaseSyncService.resolveImageUrl(ref, bucket: widget.bucket);
  }

  static bool _isLocalPath(String ref) =>
      !ref.startsWith('http') && (ref.startsWith('/') || ref.contains(':\\'));

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: radius,
      child: FutureBuilder<String?>(
        future: _resolved,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _box(widget.placeholder ?? const _Loading());
          }

          final value = snapshot.data;
          if (value == null || value.isEmpty) {
            return _box(widget.errorWidget ?? const _Broken());
          }

          if (_isLocalPath(value)) {
            return Image.file(
              File(value),
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: (_, __, ___) =>
                  _box(widget.errorWidget ?? const _Broken()),
            );
          }

          return Image.network(
            value,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, __, ___) =>
                _box(widget.errorWidget ?? const _Broken()),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : _box(widget.placeholder ?? const _Loading()),
          );
        },
      ),
    );
  }

  Widget _box(Widget child) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: child),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) => Icon(
        Icons.image_not_supported_outlined,
        size: 20,
        color: Theme.of(context).textTheme.bodySmall?.color,
      );
}
