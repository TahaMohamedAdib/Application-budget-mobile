import 'dart:io';

/// Outcome of validating a user-selected file before upload or AI attachment.
enum FileValidationStatus { ok, tooLarge, unsupportedType }

class FileValidationResult {
  const FileValidationResult(this.status);

  final FileValidationStatus status;

  bool get isOk => status == FileValidationStatus.ok;
}

/// Shared size/type guard for user-provided files (receipts + AI attachments).
///
/// The rule is additive: it only rejects oversized files and extensions the
/// app never accepted. It does not narrow any format the app already allowed.
class FileValidator {
  /// 10 MB, matching the `fileTooLargeError` copy and the Storage bucket limit.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Image extensions already accepted for receipts/AI images.
  static const Set<String> imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'heic',
    'heif',
  };

  /// Document extensions accepted as AI attachments.
  static const Set<String> documentExtensions = {'pdf'};

  /// Validates a picked image file (receipts, AI image attachments).
  static FileValidationResult validateImage(String path) =>
      _validate(path, imageExtensions);

  /// Validates a picked document file (AI PDF attachments).
  static FileValidationResult validateDocument(String path) =>
      _validate(path, documentExtensions);

  static FileValidationResult _validate(
    String path,
    Set<String> allowedExtensions,
  ) {
    if (!_hasAllowedExtension(path, allowedExtensions)) {
      return const FileValidationResult(FileValidationStatus.unsupportedType);
    }
    if (exceedsMaxSize(path)) {
      return const FileValidationResult(FileValidationStatus.tooLarge);
    }
    return const FileValidationResult(FileValidationStatus.ok);
  }

  /// Returns the lowercase extension without the leading dot, or '' if none.
  static String extensionOf(String path) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static bool _hasAllowedExtension(String path, Set<String> allowed) =>
      allowed.contains(extensionOf(path));

  /// True when the file exists on disk and exceeds [maxFileSizeBytes].
  ///
  /// A missing/unreadable file is treated as not-too-large so the existing
  /// upload path (which already tolerates read failures) stays in control.
  static bool exceedsMaxSize(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      return file.lengthSync() > maxFileSizeBytes;
    } on FileSystemException {
      return false;
    }
  }
}
