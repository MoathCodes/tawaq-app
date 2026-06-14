import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_share_logic.dart';

void main() {
  group('AyahShareLogic.slider mapping', () {
    test('single ayah maps to zero', () {
      expect(AyahShareLogic.ayahIndexToSliderValue(0, 1), 0);
      expect(AyahShareLogic.sliderValueToAyahIndex(0.5, 1), 0);
    });

    test('round-trips indices for multi-ayah pages', () {
      const count = 5;
      for (var i = 0; i < count; i++) {
        final value = AyahShareLogic.ayahIndexToSliderValue(i, count);
        expect(AyahShareLogic.sliderValueToAyahIndex(value, count), i);
      }
    });
  });
}
