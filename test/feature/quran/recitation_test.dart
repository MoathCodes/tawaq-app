import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_url_builder.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';

void main() {
  group('surahAudioUrl', () {
    test('zero-pads the surah to three digits', () {
      expect(
        surahAudioUrl('https://server6.mp3quran.net/akdr/', 1),
        'https://server6.mp3quran.net/akdr/001.mp3',
      );
      expect(
        surahAudioUrl('https://server6.mp3quran.net/akdr/', 114),
        'https://server6.mp3quran.net/akdr/114.mp3',
      );
    });

    test('tolerates a server without a trailing slash', () {
      expect(
        surahAudioUrl('https://x.net/akdr', 12),
        'https://x.net/akdr/012.mp3',
      );
    });
  });

  group('SurahTiming', () {
    const timing = SurahTiming(
      surah: 1,
      readId: 1,
      ayat: [
        AyahTiming(ayah: 0, startMs: 0, endMs: 8200),
        AyahTiming(ayah: 1, startMs: 8200, endMs: 13960),
        AyahTiming(ayah: 2, startMs: 13960, endMs: 19240),
      ],
    );

    test('forAyah returns the matching entry', () {
      expect(timing.forAyah(2)?.startMs, 13960);
      expect(timing.forAyah(9), isNull);
    });

    test('ayahAt resolves a position to the containing ayah', () {
      expect(timing.ayahAt(8200), 1); // inclusive start
      expect(timing.ayahAt(13959), 1); // exclusive end
      expect(timing.ayahAt(13960), 2); // next ayah start
    });

    test('ayahAt ignores the ayah-0 intro window', () {
      expect(timing.ayahAt(100), isNull);
    });

    test('firstAyah skips the ayah-0 intro', () {
      expect(timing.firstAyah, 1);
    });

    test('totalMs is the largest ayah endMs (ignoring the intro)', () {
      expect(timing.totalMs, 19240);
      expect(const SurahTiming(surah: 1, readId: 1, ayat: []).totalMs, 0);
    });
  });

  group('moshafTags', () {
    test('parses style from the moshaf name', () {
      expect(moshafTags('حفص عن عاصم - مرتل').style, RecitationStyle.murattal);
      expect(
        moshafTags('المصحف المجود - حفص').style,
        RecitationStyle.mujawwad,
      );
      expect(moshafTags('حفص عن عاصم').style, isNull);
    });

    test('parses the canonical riwayah', () {
      expect(moshafTags('حفص عن عاصم - مرتل').riwayah, 'حفص');
      expect(moshafTags('ورش عن نافع').riwayah, 'ورش');
      expect(moshafTags('الدوري عن أبي عمرو').riwayah, 'الدوري');
      expect(moshafTags('قالون عن نافع').riwayah, 'قالون');
    });

    test('returns null tags for an unrecognized name', () {
      final tags = moshafTags('تلاوة خاصة');
      expect(tags.style, isNull);
      expect(tags.riwayah, isNull);
    });
  });
}
