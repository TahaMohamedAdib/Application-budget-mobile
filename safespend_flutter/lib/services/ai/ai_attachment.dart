import 'dart:convert';
import 'dart:typed_data';

/// What an attachment represents, so the backend can pick a strategy without
/// re-sniffing the MIME type.
enum AIAttachmentKind { image, document, audio }

/// A provider-neutral attachment.
///
/// The UI builds these from the image/file pickers; no part of the app outside
/// a concrete [AIService] implementation should know how a given backend wants
/// binary data encoded.
class AIAttachment {
  final AIAttachmentKind kind;
  final String mimeType;

  /// Raw bytes. Kept as bytes rather than base64 so implementations can choose
  /// multipart upload, base64 inlining, or a signed-URL handoff.
  final Uint8List bytes;

  /// Original file name, when one exists. Useful for documents.
  final String? fileName;

  /// Largest attachment the app will send upstream.
  ///
  /// Providers bill by token and reject oversized payloads anyway, so an
  /// unbounded read is a way to waste the user's quota and, on a large PDF,
  /// exhaust memory on the device before the request is even attempted.
  static const maxBytes = 8 * 1024 * 1024;

  /// MIME types the app is willing to forward. An attachment is described by
  /// the picker, not sniffed, so this list is what keeps an unexpected type
  /// from being relayed to a provider on the user's behalf.
  static const allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/gif',
    'application/pdf',
  };

  /// True when the attachment is within limits and of an expected type.
  bool get isAcceptable =>
      bytes.isNotEmpty &&
      bytes.length <= maxBytes &&
      allowedMimeTypes.contains(mimeType.toLowerCase());

  const AIAttachment({
    required this.kind,
    required this.mimeType,
    required this.bytes,
    this.fileName,
  });

  factory AIAttachment.image({
    required Uint8List bytes,
    required String mimeType,
    String? fileName,
  }) =>
      AIAttachment(
        kind: AIAttachmentKind.image,
        mimeType: mimeType,
        bytes: bytes,
        fileName: fileName,
      );

  factory AIAttachment.document({
    required Uint8List bytes,
    required String mimeType,
    String? fileName,
  }) =>
      AIAttachment(
        kind: AIAttachmentKind.document,
        mimeType: mimeType,
        bytes: bytes,
        fileName: fileName,
      );

  factory AIAttachment.audio({
    required Uint8List bytes,
    required String mimeType,
    String? fileName,
  }) =>
      AIAttachment(
        kind: AIAttachmentKind.audio,
        mimeType: mimeType,
        bytes: bytes,
        fileName: fileName,
      );

  int get sizeBytes => bytes.length;

  /// Base64 payload. Only implementations that inline binary data should call
  /// this — it doubles the memory held for the attachment.
  String toBase64() => base64Encode(bytes);

  /// Wire form for the VVollet backend contract.
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'mime_type': mimeType,
        if (fileName != null) 'file_name': fileName,
        'data': toBase64(),
      };
}
