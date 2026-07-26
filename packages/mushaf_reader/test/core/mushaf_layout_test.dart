import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/core/mushaf_layout.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';

void main() {
  group('resolveContainScale / resolveWidthFitScale', () {
    test('contain equals 1 at reference size', () {
      const config = MushafScale();
      expect(
        resolveContainScale(
          scale: config,
          availableWidth: 500,
          availableHeight: mushafReferencePageHeight,
        ),
        1,
      );
    });

    test('contain is limited by the shorter axis', () {
      const config = MushafScale();
      expect(
        resolveContainScale(
          scale: config,
          availableWidth: 1000,
          availableHeight: mushafReferencePageHeight / 2,
        ),
        0.5,
      );
      expect(
        resolveContainScale(
          scale: config,
          availableWidth: 250,
          availableHeight: 2000,
        ),
        0.5,
      );
    });

    test('widthFit is availableWidth / referenceWidth', () {
      const config = MushafScale();
      expect(
        resolveWidthFitScale(scale: config, availableWidth: 400),
        closeTo(0.8, 1e-9),
      );
    });
  });

  group('resolveReadingBoost', () {
    test('clamps reading boost', () {
      const config = MushafScale(readingBoost: 2, maxReadingBoost: 1.12);
      expect(resolveReadingBoost(config), 1.12);
    });
  });

  group('resolvePageScale', () {
    test('boost 1.0 stays at contain (no scroll needed at ref size)', () {
      const config = MushafScale(readingBoost: 1);
      final scale = resolvePageScale(
        scaleConfig: config,
        availableWidth: 500,
        availableHeight: mushafReferencePageHeight,
      );
      expect(scale, 1);
      expect(
        pageNeedsVerticalScroll(
          scale: scale,
          availableHeight: mushafReferencePageHeight,
          scaleConfig: config,
        ),
        isFalse,
      );
    });

    test('boost above 1 lerps toward widthFit and never exceeds it', () {
      const config = MushafScale(
        readingBoost: 1.15,
        maxReadingBoost: 1.15,
      );
      // Height-limited pane → contain < widthFit
      const availW = 500.0;
      const availH = 600.0;
      final contain = resolveContainScale(
        scale: config,
        availableWidth: availW,
        availableHeight: availH,
      );
      final widthFit = resolveWidthFitScale(
        scale: config,
        availableWidth: availW,
      );
      expect(contain, lessThan(widthFit));

      final scale = resolvePageScale(
        scaleConfig: config,
        availableWidth: availW,
        availableHeight: availH,
      );
      expect(scale, closeTo(widthFit, 1e-9));
      expect(scale, lessThanOrEqualTo(widthFit));
      expect(config.referenceWidth * scale, lessThanOrEqualTo(availW + 1e-6));
      expect(
        pageNeedsVerticalScroll(
          scale: scale,
          availableHeight: availH,
          scaleConfig: config,
        ),
        isTrue,
      );
    });

    test('boost below 1 shrinks from contain', () {
      const config = MushafScale(readingBoost: 0.9);
      final scale = resolvePageScale(
        scaleConfig: config,
        availableWidth: 500,
        availableHeight: mushafReferencePageHeight,
      );
      expect(scale, closeTo(0.9, 1e-9));
    });

    test('explicit factor is capped at widthFit', () {
      const config = MushafScale(factor: 3);
      final scale = resolvePageScale(
        scaleConfig: config,
        availableWidth: 500,
        availableHeight: mushafReferencePageHeight,
      );
      expect(scale, 1);
    });
  });

  group('resolveFitScale (deprecated)', () {
    test('matches resolvePageScale for boost > 1', () {
      const config = MushafScale(readingBoost: 1.1, maxReadingBoost: 1.15);
      final a = resolveFitScale(
        scale: config,
        availableWidth: 500,
        availableHeight: mushafReferencePageHeight,
      );
      final b = resolvePageScale(
        scaleConfig: config,
        availableWidth: 500,
        availableHeight: mushafReferencePageHeight,
      );
      expect(a, closeTo(b, 1e-9));
    });
  });
}
