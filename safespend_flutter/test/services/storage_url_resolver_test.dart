import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/services/storage_url_resolver.dart';

void main() {
  const supabaseUrl = 'https://safe-spend.supabase.co';

  group('StorageReferenceParser', () {
    test('parses private bucket/object paths', () {
      final receipt = StorageReferenceParser.parse(
        'receipts/user-1/receipt.jpg',
        supabaseUrl: supabaseUrl,
      );
      final logo = StorageReferenceParser.parse(
        'logos/user-2/logo.jpg',
        supabaseUrl: supabaseUrl,
      );

      expect(receipt?.bucket, 'receipts');
      expect(receipt?.objectPath, 'user-1/receipt.jpg');
      expect(logo?.bucket, 'logos');
      expect(logo?.objectPath, 'user-2/logo.jpg');
    });

    test('parses legacy Supabase public, signed, and authenticated URLs', () {
      final publicReference = StorageReferenceParser.parse(
        '$supabaseUrl/storage/v1/object/public/logos/'
        'user-1/brand%20logo.jpg',
        supabaseUrl: supabaseUrl,
      );
      final signedReference = StorageReferenceParser.parse(
        '$supabaseUrl/storage/v1/object/sign/receipts/'
        'user-1/receipt.jpg?token=legacy-token',
        supabaseUrl: supabaseUrl,
      );
      final authenticatedReference = StorageReferenceParser.parse(
        '$supabaseUrl/storage/v1/object/authenticated/receipts/'
        'user-1/receipt.jpg',
        supabaseUrl: supabaseUrl,
      );
      final renderedReference = StorageReferenceParser.parse(
        '$supabaseUrl/storage/v1/render/image/public/logos/'
        'user-1/logo.jpg?width=120',
        supabaseUrl: supabaseUrl,
      );

      expect(publicReference?.bucket, 'logos');
      expect(publicReference?.objectPath, 'user-1/brand logo.jpg');
      expect(signedReference?.bucket, 'receipts');
      expect(signedReference?.objectPath, 'user-1/receipt.jpg');
      expect(authenticatedReference?.bucket, 'receipts');
      expect(authenticatedReference?.objectPath, 'user-1/receipt.jpg');
      expect(renderedReference?.bucket, 'logos');
      expect(renderedReference?.objectPath, 'user-1/logo.jpg');
    });

    test('leaves external URLs and local paths unclassified', () {
      expect(
        StorageReferenceParser.parse(
          'https://cdn.example.com/receipts/user-1/receipt.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
      expect(
        StorageReferenceParser.parse(
          'https://another-project.supabase.co/storage/v1/object/public/'
          'receipts/user-1/receipt.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
      expect(
        StorageReferenceParser.parse(
          r'C:\Users\tester\Pictures\receipt.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
      expect(
        StorageReferenceParser.parse(
          '/receipts/user-1/receipt.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
    });

    test('rejects unsupported buckets and unsafe object paths', () {
      expect(
        StorageReferenceParser.parse(
          'avatars/user-1/avatar.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
      expect(
        StorageReferenceParser.parse(
          'receipts/user-1/../other-user/receipt.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
      expect(
        StorageReferenceParser.parse(
          '$supabaseUrl/storage/v1/object/public/receipts/'
          'user-1/%2E%2E/other-user/receipt.jpg',
          supabaseUrl: supabaseUrl,
        ),
        isNull,
      );
    });
  });

  group('StorageUrlResolver', () {
    test('passes external URLs and local paths through without signing',
        () async {
      var signerCalls = 0;
      final resolver = StorageUrlResolver(
        createSignedUrl: (bucket, objectPath, expiresInSeconds) async {
          signerCalls++;
          return 'unexpected';
        },
        currentUserId: () => 'user-1',
        supabaseUrl: () => supabaseUrl,
      );

      const external = 'https://cdn.example.com/image.jpg';
      const local = r'C:\Users\tester\Pictures\receipt.jpg';
      expect(await resolver.resolve(external), external);
      expect(await resolver.resolve(local), local);
      expect(signerCalls, 0);
    });

    test('re-signs a legacy public URL from its bucket and object path',
        () async {
      final signedCalls = <({String bucket, String path, int expiry})>[];
      final resolver = StorageUrlResolver(
        createSignedUrl: (bucket, objectPath, expiresInSeconds) async {
          signedCalls.add((
            bucket: bucket,
            path: objectPath,
            expiry: expiresInSeconds,
          ));
          return 'https://signed.example/$bucket/$objectPath';
        },
        currentUserId: () => 'user-1',
        supabaseUrl: () => supabaseUrl,
      );

      final resolved = await resolver.resolve(
        '$supabaseUrl/storage/v1/object/public/receipts/'
        'user-1/receipt.jpg',
        expiresInSeconds: 900,
      );

      expect(
        signedCalls,
        [
          (
            bucket: 'receipts',
            path: 'user-1/receipt.jpg',
            expiry: 900,
          ),
        ],
      );
      expect(
        resolved,
        'https://signed.example/receipts/user-1/receipt.jpg',
      );
    });

    test('caches until the refresh margin and then signs again', () async {
      var now = DateTime.utc(2026, 7, 23, 12);
      var signerCalls = 0;
      final resolver = StorageUrlResolver(
        createSignedUrl: (bucket, objectPath, expiresInSeconds) async {
          signerCalls++;
          return 'https://signed.example/$signerCalls';
        },
        currentUserId: () => 'user-1',
        supabaseUrl: () => supabaseUrl,
        now: () => now,
        refreshMargin: const Duration(seconds: 30),
      );

      expect(
        await resolver.resolve(
          'receipts/user-1/receipt.jpg',
          expiresInSeconds: 600,
        ),
        'https://signed.example/1',
      );
      now = now.add(const Duration(seconds: 569));
      expect(
        await resolver.resolve(
          'receipts/user-1/receipt.jpg',
          expiresInSeconds: 600,
        ),
        'https://signed.example/1',
      );
      now = now.add(const Duration(seconds: 2));
      expect(
        await resolver.resolve(
          'receipts/user-1/receipt.jpg',
          expiresInSeconds: 600,
        ),
        'https://signed.example/2',
      );
      expect(signerCalls, 2);
    });

    test('deduplicates concurrent signing for one user and object', () async {
      final completion = Completer<String>();
      var signerCalls = 0;
      final resolver = StorageUrlResolver(
        createSignedUrl: (bucket, objectPath, expiresInSeconds) {
          signerCalls++;
          return completion.future;
        },
        currentUserId: () => 'user-1',
        supabaseUrl: () => supabaseUrl,
      );

      final first = resolver.resolve('logos/user-1/logo.jpg');
      final second = resolver.resolve('logos/user-1/logo.jpg');
      expect(signerCalls, 1);

      completion.complete('https://signed.example/logo');
      expect(await first, 'https://signed.example/logo');
      expect(await second, 'https://signed.example/logo');
    });

    test('isolates users and ignores an old signature completing in flight',
        () async {
      var userId = 'user-a';
      final completions = <Completer<String>>[];
      var signerCalls = 0;
      final resolver = StorageUrlResolver(
        createSignedUrl: (bucket, objectPath, expiresInSeconds) {
          signerCalls++;
          final completion = Completer<String>();
          completions.add(completion);
          return completion.future;
        },
        currentUserId: () => userId,
        supabaseUrl: () => supabaseUrl,
      );

      final oldUserA = resolver.resolve('receipts/shared-name/file.jpg');
      userId = 'user-b';
      final userB = resolver.resolve('receipts/shared-name/file.jpg');
      userId = 'user-a';
      final newUserA = resolver.resolve('receipts/shared-name/file.jpg');
      expect(signerCalls, 3);

      completions[0].complete('https://signed.example/old-user-a');
      expect(await oldUserA, 'https://signed.example/old-user-a');

      final deduplicatedNewUserA =
          resolver.resolve('receipts/shared-name/file.jpg');
      expect(signerCalls, 3);

      completions[2].complete('https://signed.example/new-user-a');
      completions[1].complete('https://signed.example/user-b');
      expect(await newUserA, 'https://signed.example/new-user-a');
      expect(await deduplicatedNewUserA, 'https://signed.example/new-user-a');
      expect(await userB, 'https://signed.example/user-b');

      expect(
        await resolver.resolve('receipts/shared-name/file.jpg'),
        'https://signed.example/new-user-a',
      );
      expect(signerCalls, 3);
    });

    test('rejects non-positive expirations', () {
      final resolver = StorageUrlResolver(
        createSignedUrl: (bucket, objectPath, expiresInSeconds) async => '',
        currentUserId: () => 'user-1',
      );

      expect(
        () => resolver.resolve(
          'receipts/user-1/receipt.jpg',
          expiresInSeconds: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
