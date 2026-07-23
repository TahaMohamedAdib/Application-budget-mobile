import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/services/file_validation.dart';

void main() {
  group('FileValidator.extensionOf', () {
    test('lowercases and strips the leading dot', () {
      expect(FileValidator.extensionOf('/tmp/a/photo.JPG'), 'jpg');
      expect(FileValidator.extensionOf(r'C:\docs\report.PDF'), 'pdf');
    });

    test('returns empty for no extension or trailing dot', () {
      expect(FileValidator.extensionOf('/tmp/noext'), '');
      expect(FileValidator.extensionOf('/tmp/trailing.'), '');
    });
  });

  group('type checks (no filesystem)', () {
    test('unsupported image extension is rejected before size', () {
      final result = FileValidator.validateImage('/tmp/malware.exe');
      expect(result.status, FileValidationStatus.unsupportedType);
    });

    test('a non-pdf document is rejected', () {
      final result = FileValidator.validateDocument('/tmp/sheet.xlsx');
      expect(result.status, FileValidationStatus.unsupportedType);
    });

    test('accepted extensions on a missing file pass (size unknown)', () {
      expect(
        FileValidator.validateImage('/tmp/missing.png').status,
        FileValidationStatus.ok,
      );
      expect(
        FileValidator.validateDocument('/tmp/missing.pdf').status,
        FileValidationStatus.ok,
      );
    });
  });

  group('size checks (real temp files)', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('filevalid');
    });

    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    File writeFile(String name, int bytes) {
      final f = File('${dir.path}/$name');
      f.writeAsBytesSync(List<int>.filled(bytes, 0));
      return f;
    }

    test('a small valid image is ok', () {
      final f = writeFile('ok.jpg', 1024);
      expect(FileValidator.validateImage(f.path).status,
          FileValidationStatus.ok);
    });

    test('an image over 10 MB is too large', () {
      final f = writeFile('big.jpg', FileValidator.maxFileSizeBytes + 1);
      expect(FileValidator.validateImage(f.path).status,
          FileValidationStatus.tooLarge);
    });

    test('exactly 10 MB is accepted (boundary)', () {
      final f = writeFile('edge.png', FileValidator.maxFileSizeBytes);
      expect(FileValidator.validateImage(f.path).status,
          FileValidationStatus.ok);
    });

    test('an oversized pdf is too large', () {
      final f = writeFile('big.pdf', FileValidator.maxFileSizeBytes + 1);
      expect(FileValidator.validateDocument(f.path).status,
          FileValidationStatus.tooLarge);
    });

    test('unsupported type wins even when oversized', () {
      final f = writeFile('big.exe', FileValidator.maxFileSizeBytes + 1);
      expect(FileValidator.validateImage(f.path).status,
          FileValidationStatus.unsupportedType);
    });
  });
}
