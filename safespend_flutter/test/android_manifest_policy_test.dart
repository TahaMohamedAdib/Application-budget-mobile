import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('does not request broad photo-library read permissions', () {
    final source = manifest.readAsStringSync();
    expect(source, isNot(contains('READ_MEDIA_IMAGES')));
    expect(source, isNot(contains('READ_EXTERNAL_STORAGE')));
  });

  test('disables cleartext network traffic', () {
    final source =
        File('android/app/src/main/res/xml/network_security_config.xml')
            .readAsStringSync();
    expect(source, contains('cleartextTrafficPermitted="false"'));
  });

  test('uses VVollet for the iOS bundle name and display name', () {
    final source = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      source,
      matches(
          RegExp(r'<key>CFBundleDisplayName</key>\s*<string>VVollet</string>')),
    );
    expect(
      source,
      matches(RegExp(r'<key>CFBundleName</key>\s*<string>VVollet</string>')),
    );
  });
}
