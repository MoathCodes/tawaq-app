import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/data/ayah_id_resolver.dart';

void main() {
  group('AyahIdResolver', () {
    test('static counts sum to total ayahs', () {
      final sum = AyahIdResolver.ayahsPerSurah.fold<int>(0, (a, b) => a + b);
      expect(sum, AyahIdResolver.totalAyahs);
    });

    test('buildStarts matches known references', () {
      final starts = AyahIdResolver.buildStarts({});

      expect(
        AyahIdResolver.globalId(
          surah: 1,
          ayahInSurah: 1,
          startsBySurah: starts,
        ),
        1,
      );
      expect(
        AyahIdResolver.globalId(
          surah: 2,
          ayahInSurah: 255,
          startsBySurah: starts,
        ),
        262,
      );
      expect(
        AyahIdResolver.globalId(
          surah: 114,
          ayahInSurah: 6,
          startsBySurah: starts,
        ),
        AyahIdResolver.totalAyahs,
      );
    });

    test('rejects out-of-range ayah numbers', () {
      final starts = AyahIdResolver.buildStarts({});
      expect(
        AyahIdResolver.globalId(
          surah: 1,
          ayahInSurah: 8,
          startsBySurah: starts,
        ),
        isNull,
      );
    });
  });
}
