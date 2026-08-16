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

  /// Wire form for the SafeSpend backend contract.
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'mime_type': mimeType,
        if (fileName != null) 'file_name': fileName,
        'data': toBase64(),
      };
}
