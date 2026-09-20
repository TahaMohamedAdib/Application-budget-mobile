import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safespend_flutter/theme/app_text_styles.dart';
import 'package:safespend_flutter/theme/app_theme.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:safespend_flutter/widgets/settings_ui.dart';

void main() {
  testWidgets('Inter is bundled for reliable offline typography',
      (tester) async {
    final font = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    expect(font.lengthInBytes, greaterThan(800000));
  });

  test('UI source does not introduce fractional font sizes', () {
    final fractionalSize = RegExp(r'fontSize:\s*\d+\.\d+');
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => fractionalSize.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('light and dark themes expose one complete Inter type scale', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final styles = <TextStyle?>[
        theme.textTheme.displayLarge,
        theme.textTheme.displayMedium,
        theme.textTheme.displaySmall,
        theme.textTheme.headlineLarge,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.titleSmall,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelMedium,
        theme.textTheme.labelSmall,
      ];

      expect(styles, everyElement(isNotNull));
      expect(styles.map((style) => style!.fontFamily), everyElement('Inter'));

      expect(theme.textTheme.headlineMedium!.fontSize,
          AppTextStyles.screenTitleSize);
      expect(
          theme.textTheme.titleLarge!.fontSize, AppTextStyles.sectionTitleSize);
      expect(
          theme.textTheme.titleMedium!.fontSize, AppTextStyles.itemTitleSize);
      expect(
          theme.textTheme.bodySmall!.fontSize, AppTextStyles.descriptionSize);
      expect(theme.textTheme.headlineMedium!.fontWeight, FontWeight.w700);
      expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodySmall!.fontWeight, FontWeight.w400);

      expect(theme.appBarTheme.titleTextStyle!.fontSize,
          AppTextStyles.sectionTitleSize);
      expect(theme.listTileTheme.titleTextStyle!.fontSize,
          AppTextStyles.itemTitleSize);
      expect(theme.listTileTheme.subtitleTextStyle!.fontSize,
          AppTextStyles.descriptionSize);
      expect(theme.dialogTheme.titleTextStyle!.fontSize,
          AppTextStyles.sectionTitleSize);
      expect(theme.dialogTheme.contentTextStyle!.fontSize,
          AppTextStyles.descriptionSize);
    }
  });

  testWidgets('settings rows visibly separate titles from descriptions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SettingsRow(
            icon: IOSIcons.info_outline_rounded,
            label: 'Title',
            detail: 'Description',
            showChevron: false,
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Title')).style!;
    final description = tester.widget<Text>(find.text('Description')).style!;

    expect(title.fontSize, AppTextStyles.itemTitleSize);
    expect(title.fontWeight, FontWeight.w600);
    expect(description.fontSize, AppTextStyles.descriptionSize);
    expect(description.fontWeight, FontWeight.w400);
    expect(title.color, isNot(description.color));
  });
}
