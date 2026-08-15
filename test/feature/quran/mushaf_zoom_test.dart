import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/src/core/mushaf_layout.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/theme/custom_themes.dart';

void main() {
  group('mushafZoomFromJson', () {
    test('maps continuous doubles', () {
      expect(mushafZoomFromJson(1.0), kMushafZoomDefault);
      expect(mushafZoomFromJson(0.9), 0.9);
      expect(mushafZoomFromJson(1.12), 1.12);
      expect(mushafZoomFromJson(1.08), 1.08);
    });

    test('clamps out-of-range doubles', () {
      expect(mushafZoomFromJson(0.5), kMushafZoomMin);
      expect(mushafZoomFromJson(2.0), kMushafZoomMax);
    });

    test('maps legacy enum names', () {
      expect(mushafZoomFromJson('small'), 0.9);
      expect(mushafZoomFromJson('medium'), kMushafZoomDefault);
      expect(mushafZoomFromJson('large'), 1.08);
      expect(mushafZoomFromJson('extraLarge'), 1.12);
      expect(mushafZoomFromJson('unknown'), kMushafZoomDefault);
    });

    test('maps legacy integer indices', () {
      expect(mushafZoomFromJson(0), 0.9);
      expect(mushafZoomFromJson(1), kMushafZoomDefault);
      expect(mushafZoomFromJson(2), 1.08);
      expect(mushafZoomFromJson(3), 1.12);
    });

    test('null and unsupported fall back to default', () {
      expect(mushafZoomFromJson(null), kMushafZoomDefault);
      expect(mushafZoomFromJson(true), kMushafZoomDefault);
    });
  });

  group('clampMushafZoom', () {
    test('clamps into the full fit→fill range', () {
      expect(clampMushafZoom(0.5), kMushafZoomMin);
      expect(clampMushafZoom(1.12), 1.12);
      expect(clampMushafZoom(2), kMushafZoomMax);
    });
  });

  group('buildQuranMushafStyle', () {
    late FThemeData theme;

    setUp(() {
      theme = ManuscriptTheme.darkManuscript.desktop;
    });

    test('emits full maxReadingBoost and clamped readingBoost', () {
      final style = buildQuranMushafStyle(theme, zoom: 1.12);
      expect(style.scale.maxReadingBoost, kMushafZoomMax);
      expect(style.scale.readingBoost, 1.12);
    });

    test('fit-page zoom never needs vertical scroll on a short wide pane', () {
      const availableWidth = 800.0;
      const availableHeight = 400.0;
      final style = buildQuranMushafStyle(
        theme,
      );
      final contain = resolveContainScale(
        scale: style.scale,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );
      final pageScale = resolvePageScale(
        scaleConfig: style.scale,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );
      expect(pageScale, lessThanOrEqualTo(contain + 0.0001));
      expect(
        pageNeedsVerticalScroll(
          scale: pageScale,
          availableHeight: availableHeight,
          scaleConfig: style.scale,
        ),
        isFalse,
      );
    });
  });
}
