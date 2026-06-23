import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() {
  group('SurahTiming', () {
    const timing = SurahTiming(
      surah: 1,
      readId: 1,
      ayat: [
        AyahTiming(ayah: 0, startMs: 0, endMs: 8200),
        AyahTiming(ayah: 1, startMs: 8200, endMs: 13960),
        AyahTiming(ayah: 2, startMs: 13960, endMs: 20000),
      ],
    );

    test('ayahAt resolves a position to the containing ayah', () {
      expect(timing.ayahAt(8200), 1); // inclusive start
      expect(timing.ayahAt(13959), 1); // exclusive end
      expect(timing.ayahAt(13960), 2); // next ayah start
    });

    test('ayahAt ignores the ayah-0 intro window', () {
      expect(timing.ayahAt(100), isNull);
    });

    test('totalMs uses the largest playable end offset', () {
      expect(const SurahTiming(surah: 1, readId: 1, ayat: []).totalMs, 0);
      expect(timing.totalMs, 20000);
    });
  });
}
