import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/widgets/storage_image.dart';

void main() {
  testWidgets('renders an external URL directly as a network image',
      (tester) async {
    const stored = 'https://cdn.example.com/logo.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: StorageImage(
          stored: stored,
          width: 48,
          height: 32,
          fit: BoxFit.contain,
          placeholder: Text('loading'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, stored);
    expect(image.width, 48);
    expect(image.height, 32);
    expect(image.fit, BoxFit.contain);
    expect(image.loadingBuilder, isNotNull);
  });

  testWidgets('shows a placeholder while a private path is being resolved',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StorageImage(
          stored: 'receipts/user-1/receipt.jpg',
          placeholder: const Text('resolving'),
          errorBuilder: (context, error, stackTrace) {
            return const Text('unavailable');
          },
        ),
      ),
    );

    expect(find.text('resolving'), findsOneWidget);
    await tester.pump();
    expect(find.text('unavailable'), findsOneWidget);
  });
}
