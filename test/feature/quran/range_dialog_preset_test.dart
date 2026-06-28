import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';

/// Mirrors continue-from-here preset behavior in the range dialog.
bool shouldForceCustomOnFromEdit(RangeScopePreset preset) =>
    preset != RangeScopePreset.continueFromHere;

/// Mirrors range dialog seed priority when opened without [initial].
({
  int seedSurah,
  int seedAyah,
  int fromSurah,
  int fromAyah,
}) resolveRangeDialogSeed({
  required Ayah? viewedAyah,
  required int? playbackSurah,
  required int? playbackAyah,
  required int? lastFromSurah,
  required int? lastFromAyah,
}) {
  final seedSurah =
      playbackSurah ?? viewedAyah?.surahNumber ?? 1;
  final seedAyah =
      playbackAyah ?? viewedAyah?.numberInSurah ?? 1;
  final fromSurah =
      viewedAyah?.surahNumber ?? lastFromSurah ?? playbackSurah ?? seedSurah;
  final fromAyah =
      viewedAyah?.numberInSurah ?? lastFromAyah ?? playbackAyah ?? seedAyah;
  return (
    seedSurah: seedSurah,
    seedAyah: seedAyah,
    fromSurah: fromSurah,
    fromAyah: fromAyah,
  );
}

void main() {
  group('range dialog preset decoupling', () {
    test('editing from endpoint keeps continueFromHere preset', () {
      expect(
        shouldForceCustomOnFromEdit(RangeScopePreset.continueFromHere),
        isFalse,
      );
    });

    test('editing from endpoint forces custom for bounded presets', () {
      expect(shouldForceCustomOnFromEdit(RangeScopePreset.thisAyah), isTrue);
      expect(shouldForceCustomOnFromEdit(RangeScopePreset.custom), isTrue);
    });

    test('re-selecting continueFromHere keeps user-edited surah', () {
      const seedSurah = 1;
      const seedAyah = 1;
      var fromSurah = 112;
      var fromAyah = 3;
      const previousPreset = RangeScopePreset.continueFromHere;

      if (previousPreset != RangeScopePreset.continueFromHere) {
        fromSurah = seedSurah;
        fromAyah = seedAyah;
      }

      expect(fromSurah, 112);
      expect(fromAyah, 3);
    });

    test('dialog seeds from viewed ayah when not playing', () {
      final viewed = Ayah(
        ayahId: 6236,
        surahNumber: 114,
        numberInSurah: 5,
        page: 604,
        juz: 30,
        text: '',
      );
      final seed = resolveRangeDialogSeed(
        viewedAyah: viewed,
        playbackSurah: null,
        playbackAyah: null,
        lastFromSurah: 1,
        lastFromAyah: 1,
      );

      expect(seed.seedSurah, 114);
      expect(seed.seedAyah, 5);
      expect(seed.fromSurah, 114);
      expect(seed.fromAyah, 5);
    });
  });
}
