import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
        minWidth:  _maxEdge,
        minHeight: _maxEdge,
        quality:   _quality,
        format:    CompressFormat.jpeg,
        keepExif:  false, // strip EXIF for privacy + smaller size
      );
      if (result != null && result.isNotEmpty) {
        final original = await File(localPath).length();
        final saved = original - result.length;
        // ignore: avoid_print
        print('[ImageService] Compressed receipt: '
            '${(original / 1024).toStringAsFixed(0)} KB → '
            '${(result.length / 1024).toStringAsFixed(0)} KB '
            '(saved ${(saved / 1024).toStringAsFixed(0)} KB)');
        return result;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ImageService] Compression failed, uploading original: $e');
    }
    // Fallback — return original bytes unchanged
    return File(localPath).readAsBytes();
  }
}
