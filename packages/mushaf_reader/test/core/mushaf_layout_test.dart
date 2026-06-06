import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/core/mushaf_layout.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';

void main() {
  group('resolveBaseFitScale', () {
    test('fits width without boost', () {
      const config = MushafScale();
      final scale = resolveBaseFitScale(
        scale: config,
        availableWidth: 500,
        availableHeight: 850,
      );
      expect(scale, 1);
    });
  });

  group('resolveReadingBoost', () {
    test('clamps reading boost', () {
      const config = MushafScale(readingBoost: 2, maxReadingBoost: 1.12);
      expect(resolveReadingBoost(config), 1.12);
    });
  });

  group('resolveFitScale (deprecated)', () {
    test('applies readingBoost on top of width fit', () {
      const config = MushafScale(readingBoost: 1.1);
      final scale = resolveFitScale(
        scale: config,
        availableWidth: 500,
        availableHeight: 850,
      );
      expect(scale, closeTo(1.1, 0.001));
    });
  });
}
