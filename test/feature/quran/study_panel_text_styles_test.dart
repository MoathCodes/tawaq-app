import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/study_panel_text_styles.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets('study prose keeps readable tiers and upright source text', (
    tester,
  ) async {
    final theme = buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );
    TextStyle? narrow;
    TextStyle? wide;
    TextStyle? urdu;

    await tester.pumpWidget(
      FTheme(
        data: theme,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              narrow = StudyPanelTextStyles.translation(
                context: context,
                typography: theme.typography,
                colors: theme.colors,
                source: TranslationId.spanish,
                containerWidth: 320,
              );
              wide = StudyPanelTextStyles.translation(
                context: context,
                typography: theme.typography,
                colors: theme.colors,
                source: TranslationId.spanish,
                containerWidth: 800,
              );
              urdu = StudyPanelTextStyles.translation(
                context: context,
                typography: theme.typography,
                colors: theme.colors,
                source: TranslationId.urdu,
                containerWidth: 320,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(narrow!.fontSize, theme.typography.body.md.fontSize);
    expect(wide!.fontSize, theme.typography.body.lg.fontSize);
    expect(narrow!.fontStyle, FontStyle.normal);
    expect(narrow!.height, 1.6);
    expect(urdu!.fontFamily, TranslationId.urdu.fontFamily);
    expect(urdu!.height, 2.0);
  });
}
