import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles compression of all images before they are uploaded
/// to Supabase Storage (receipts, account logos, etc.).
class ImageService {
  // Max dimension (width or height) for a stored receipt
  static const int _maxEdge = 1200;

  // JPEG quality (0-100).  75 gives a good quality/size balance for receipts.
  static const int _quality = 75;

  /// Compresses a receipt image at [localPath] to a JPEG with at most
  /// [_maxEdge] px on each side and [_quality]% JPEG quality.
  ///
  /// Returns the compressed bytes.  If compression fails for any reason the
  /// original file bytes are returned as a fallback so the upload always
  /// succeeds.
  static Future<Uint8List> compressReceipt(String localPath) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        localPath,
        minWidth: _maxEdge,
        minHeight: _maxEdge,
        quality: _quality,
        format: CompressFormat.jpeg,
        keepExif: false, // strip EXIF for privacy + smaller size
      );
      if (result != null && result.isNotEmpty) {
        final original = await File(localPath).length();
        final saved = original - result.length;
        if (kDebugMode)
          debugPrint('[ImageService] Compressed receipt: '
              '${(original / 1024).toStringAsFixed(0)} KB → '
              '${(result.length / 1024).toStringAsFixed(0)} KB '
              '(saved ${(saved / 1024).toStringAsFixed(0)} KB)');
        return result;
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ImageService] Compression failed, uploading original: $e');
    }
    // Fallback — return original bytes unchanged
    return File(localPath).readAsBytes();
  }

  /// Copies a picked profile image out of the picker cache into app-owned
  /// storage. Android is free to clear picker/cache files at any time, so a
  /// local fallback must never point at the original [localPath].
  static Future<String?> persistProfilePicture(
    String localPath, {
    Directory? supportDirectory,
  }) async {
    try {
      final source = File(localPath);
      if (!await source.exists()) return null;

      final root = supportDirectory ?? await getApplicationSupportDirectory();
      final folder = Directory(p.join(root.path, 'profile_pictures'));
      await folder.create(recursive: true);

      final bytes = await compressReceipt(localPath);
      final target = File(p.join(
        folder.path,
        'avatar_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ));
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImageService] Could not persist profile picture: $e');
      }
      return null;
    }
  }

  /// Removes an app-owned local image. Storage object paths are deliberately
  /// ignored, because they are not filesystem paths.
  static Future<void> deleteLocalImage(String? reference) async {
    if (!isLocalImagePath(reference)) return;
    try {
      final file = File(reference!);
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[ImageService] Could not delete image: $e');
    }
  }

  static bool isLocalImagePath(String? reference) {
    if (reference == null || reference.isEmpty) return false;
    return reference.startsWith('/') ||
        reference.startsWith('file:') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(reference);
  }
}
