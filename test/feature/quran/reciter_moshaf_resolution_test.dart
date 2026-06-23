import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';

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
  group('resolveMoshafForIntent', () {
    test('ayah intent upgrades non-timed saved moshaf to timed hafs', () {
      final reciter = _reciter([
        _moshaf(id: 10, name: 'حفص عن عاصم - مجوّد'),
        _moshaf(id: 11, name: 'حفص عن عاصم - مرتل', timingReadId: 42),
      ]);

      final resolved = reciter.resolveMoshafForIntent(
        10,
        RecitationPickIntent.ayahLevel,
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

      final resolved = reciter.resolveMoshafForIntent(
        11,
        RecitationPickIntent.ayahLevel,
      );

      expect(resolved, timed);
    });

    test('general intent returns saved moshaf even without timing', () {
      final untimed = _moshaf(id: 10, name: 'حفص عن عاصم - مجوّد');
      final reciter = _reciter([
        untimed,
        _moshaf(id: 11, name: 'حفص عن عاصم - مرتل', timingReadId: 42),
      ]);

      final resolved = reciter.resolveMoshafForIntent(
        10,
        RecitationPickIntent.general,
      );

      expect(resolved, untimed);
    });

    test('ayah intent falls back to any timed moshaf', () {
      final reciter = _reciter([
        _moshaf(id: 10, name: 'ورش - مجوّد'),
        _moshaf(id: 11, name: 'حفص عن عاصم - مرتل', timingReadId: 42),
      ]);

      final resolved = reciter.resolveMoshafForIntent(
        10,
        RecitationPickIntent.ayahLevel,
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
      expect(
        isGlobalRangeComplete(to: to, surah: 3, endAyah: 5),
        isTrue,
      );
      expect(
        isGlobalRangeComplete(to: to, surah: 2, endAyah: 286),
        isFalse,
      );
    });
  });
}
