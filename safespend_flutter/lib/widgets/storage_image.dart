import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_url_resolver.dart';
import '../services/supabase_config.dart';
import '../services/supabase_sync_service.dart';

class StorageImage extends StatefulWidget {
  const StorageImage({
    required this.stored,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholder,
    super.key,
  });

  final String stored;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Widget? placeholder;

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  Future<String?>? _signedUrlFuture;
  StreamSubscription<AuthState>? _authSubscription;
  String? _resolvedForUserId;

  @override
  void initState() {
    super.initState();
    _prepareResolution();
    _authSubscription =
        SupabaseConfig.client?.auth.onAuthStateChange.listen((_) {
      final userId = SupabaseSyncService.currentUserId;
      if (!mounted || userId == _resolvedForUserId) return;
      setState(_prepareResolution);
    });
  }

  @override
  void didUpdateWidget(StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stored != widget.stored) {
      _prepareResolution();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _prepareResolution() {
    _resolvedForUserId = SupabaseSyncService.currentUserId;
    _signedUrlFuture =
        SupabaseSyncService.isFinancialStorageReference(widget.stored)
            ? SupabaseSyncService.getSignedUrl(widget.stored)
            : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedForUserId != SupabaseSyncService.currentUserId) {
      _prepareResolution();
    }

    final signedUrlFuture = _signedUrlFuture;
    if (signedUrlFuture == null) {
      return _buildResolvedImage(context, widget.stored);
    }

    return FutureBuilder<String?>(
      future: signedUrlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              SizedBox(width: widget.width, height: widget.height);
        }

        final resolved = snapshot.data;
        if (snapshot.hasError || resolved == null || resolved.isEmpty) {
          return _buildError(
            context,
            snapshot.error ??
                StateError('Unable to resolve the private Storage image.'),
            snapshot.stackTrace,
          );
        }
        return _buildResolvedImage(context, resolved);
      },
    );
  }

  Widget _buildResolvedImage(BuildContext context, String resolved) {
    if (StorageReferenceParser.isHttpUrl(resolved)) {
      return Image.network(
        resolved,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: widget.placeholder == null
            ? null
            : (context, child, loadingProgress) {
                return loadingProgress == null ? child : widget.placeholder!;
              },
        errorBuilder: _buildError,
      );
    }

    final uri = Uri.tryParse(resolved);
    final file = uri != null && uri.scheme == 'file'
        ? File.fromUri(uri)
        : File(resolved);
    return Image.file(
      file,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: _buildError,
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return widget.errorBuilder?.call(context, error, stackTrace) ??
        SizedBox(width: widget.width, height: widget.height);
  }
}
