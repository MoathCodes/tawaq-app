import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/select_style.dart';

void main() {
  group('selectStyle', () {
    late FThemeData theme;

    setUp(() {
      theme = FThemes.zinc.light.desktop;
    });

    TextStyle resolvedContentStyle(FSelectStyle style) {
      return style.fieldStyles.md.contentTextStyle.resolve(const {});
    }

    test('useGlyphFont applies QCF4_BSML from mushaf_reader', () {
      final style = selectStyle(
        colors: theme.colors,
        typography: theme.typography,
        style: theme.style,
        useGlyphFont: true,
      );

      final content = resolvedContentStyle(style);
      expect(content.fontFamily, contains('QCF4_BSML'));
    });

    test('useQuranFont applies Uthmanic Hafs', () {
      final style = selectStyle(
        colors: theme.colors,
        typography: theme.typography,
        style: theme.style,
        useQuranFont: true,
      );

      final content = resolvedContentStyle(style);
      expect(content.fontFamily, FontFamily.uthmanicHafs);
    });

    test('useGlyphFont wins over useQuranFont', () {
      final style = selectStyle(
        colors: theme.colors,
        typography: theme.typography,
        style: theme.style,
        useQuranFont: true,
        useGlyphFont: true,
      );

      final content = resolvedContentStyle(style);
      expect(content.fontFamily, contains('QCF4_BSML'));
    });
  });
}
