import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/widgets/app_form_sheet.dart';

void main() {
  testWidgets('form sheet collapses but cannot expand above its opening height',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormSheet(
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              children: const [
                AppFormSheetHandle(),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find.byType(ClipRRect).first;
    final openingHeight = tester.getSize(surface).height;
    expect(openingHeight, closeTo(736, 1));

    await tester.drag(find.byType(AppFormSheetHandle), const Offset(0, 320));
    await tester.pumpAndSettle();
    expect(tester.getSize(surface).height, lessThan(openingHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormSheet(
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              children: const [
                AppFormSheetHandle(),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(AppFormSheetHandle), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getSize(surface).height, closeTo(openingHeight, 1));
  });
}
