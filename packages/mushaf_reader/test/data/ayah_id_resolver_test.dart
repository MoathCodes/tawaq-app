import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

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

    test('Ayah.globalIdFor matches resolver', () {
      expect(Ayah.globalIdFor(surah: 2, ayahInSurah: 255), 262);
      expect(Ayah.globalIdFor(surah: 1, ayahInSurah: 8), isNull);
    });

    test('MushafConstants align with resolver', () {
      expect(MushafConstants.ayahCount, AyahIdResolver.totalAyahs);
    });
  });
}
