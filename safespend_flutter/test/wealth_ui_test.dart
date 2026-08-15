import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:safespend_flutter/widgets/wealth_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('wealth UI fits a compact screen in ${brightness.name} mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var backPressed = false;
      var addPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    WealthPageHeader(
                      title: 'Personal Debts',
                      subtitle: 'Money other people owe you',
                      onBack: () => backPressed = true,
                      onAdd: () => addPressed = true,
                      addTooltip: 'Add personal debt',
                    ),
                    const SizedBox(height: 16),
                    const WealthOverviewCard(
                      icon: IOSIcons.wealthPersonalDebts,
                      label: 'Still owed to you',
                      amount: '2,500,815.00 MAD',
                      firstLabel: 'Total lent',
                      firstValue: '3,000,000.00 MAD',
                      secondLabel: 'Received',
                      secondValue: '499,185.00 MAD',
                      progress: 0.42,
                      progressLabel: '42% received',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Back'));
      await tester.tap(find.byTooltip('Add personal debt'));
      expect(backPressed, isTrue);
      expect(addPressed, isTrue);
    });
  }
}
