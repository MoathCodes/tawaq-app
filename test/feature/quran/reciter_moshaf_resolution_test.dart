import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';

class _FakeMushafReaderController extends Mock
    implements MushafReaderController {}

Moshaf _moshaf({
  required int id,
  required String name,
  int? timingReadId,
}) => Moshaf(
  id: id,
  name: name,
  server: 'https://example.com/',
  surahList: List.generate(114, (i) => i + 1),
  surahTotal: 114,
  timingReadId: timingReadId,
);

Reciter _reciter(List<Moshaf> moshaf) => Reciter(id: 1, name: 'Test', moshaf: moshaf);

void main() {
  group('resolveMoshaf', () {
    test('ayah intent upgrades non-timed saved moshaf to timed hafs', () {
      final reciter = _reciter([
        _moshaf(id: 10, name: 'حفص عن عاصم - مجوّد'),
        _moshaf(id: 11, name: 'حفص عن عاصم - مرتل', timingReadId: 42),
      ]);

      final resolved = reciter.resolveMoshaf(
        10,
        intent: RecitationPickIntent.ayahLevel,
      );

      expect(resolved?.id, 11);
      expect(resolved?.hasTiming, isTrue);
    });

    test('ayah intent keeps timed saved moshaf', () {
      final timed = _moshaf(
        id: 11,
        name: 'حفص عن عاصم - مرتل',
        timingReadId: 42,
      );
      final reciter = _reciter([
        _moshaf(id: 10, name: 'حفص عن عاصم - مجوّد'),
        timed,
      ]);

      final resolved = reciter.resolveMoshaf(
        11,
        intent: RecitationPickIntent.ayahLevel,
      );

      expect(resolved, timed);
    });

    test('general intent returns saved moshaf even without timing', () {
      final untimed = _moshaf(id: 10, name: 'حفص عن عاصم - مجوّد');
      final reciter = _reciter([
        untimed,
        _moshaf(id: 11, name: 'حفص عن عاصم - مرتل', timingReadId: 42),
      ]);

      final resolved = reciter.resolveMoshaf(
        10,
      );

      expect(resolved, untimed);
    });

    test('ayah intent falls back to any timed moshaf', () {
      final reciter = _reciter([
        _moshaf(id: 10, name: 'ورش - مجوّد'),
        _moshaf(id: 11, name: 'حفص عن عاصم - مرتل', timingReadId: 42),
      ]);

      final resolved = reciter.resolveMoshaf(
        10,
        intent: RecitationPickIntent.ayahLevel,
      );

      expect(resolved?.id, 11);
    });
  });

  group('AyahReference ordering', () {
    test('compares surah-major order', () {
      const a = AyahReference(surah: 2, ayah: 286);
      const b = AyahReference(surah: 3, ayah: 1);
      expect(a.isBefore(b), isTrue);
      expect(b.isBefore(a), isFalse);
    });
  });

  group('isGlobalRangeComplete', () {
    test('detects completion at global end', () {
      const to = AyahReference(surah: 3, ayah: 5);
      final mushaf = _FakeMushafReaderController();
      when(() => mushaf.getSurahSync(any())).thenReturn(
        Surah(
          number: 3,
          glyph: '',
          hasBasmalah: true,
          ayahCount: 5,
        ),
      );
      expect(
        isGlobalRangeComplete(
          to: to,
          surah: 3,
          endAyah: 5,
          mushaf: mushaf,
        ),
        isTrue,
      );
      expect(
        isGlobalRangeComplete(
          to: to,
          surah: 2,
          endAyah: 286,
          mushaf: mushaf,
        ),
        isFalse,
      );
    });
  });
}
