import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';

/// Mirrors continue-from-here preset behavior in the range dialog.
bool shouldForceCustomOnFromEdit(RangeScopePreset preset) =>
    preset != RangeScopePreset.continueFromHere;

/// Mirrors range dialog seed priority when opened without an initial ayah.
({
  int seedSurah,
  int seedAyah,
  int fromSurah,
  int fromAyah,
  int toSurah,
  int toAyah,
})
resolveRangeDialogSeed({
  required Ayah? viewedAyah,
  required int? playbackSurah,
  required int? playbackAyah,
  required int? playbackRangeFromSurah,
  required int? playbackRangeFromAyah,
  required int? playbackRangeToSurah,
  required int? playbackRangeToAyah,
  required int? lastFromSurah,
  required int? lastFromAyah,
  required int? lastToSurah,
  required int? lastToAyah,
}) {
  final seedSurah = playbackSurah ?? viewedAyah?.surahNumber ?? 1;
  // Prefer the ayah actually being recited over the range start.
  final seedAyah =
      playbackAyah ?? playbackRangeFromAyah ?? viewedAyah?.numberInSurah ?? 1;
  final fromSurah =
      lastFromSurah ??
      playbackRangeFromSurah ??
      viewedAyah?.surahNumber ??
      playbackSurah ??
      seedSurah;
  final fromAyah =
      lastFromAyah ??
      playbackRangeFromAyah ??
      viewedAyah?.numberInSurah ??
      playbackAyah ??
      seedAyah;
  final toSurah =
      lastToSurah ??
      playbackRangeToSurah ??
      viewedAyah?.surahNumber ??
      playbackSurah ??
      seedSurah;
  final toAyah =
      lastToAyah ??
      playbackRangeToAyah ??
      viewedAyah?.numberInSurah ??
      playbackAyah ??
      seedAyah;
  return (
    seedSurah: seedSurah,
    seedAyah: seedAyah,
    fromSurah: fromSurah,
    fromAyah: fromAyah,
    toSurah: toSurah,
    toAyah: toAyah,
  );
}

/// Mirrors "to" surah selection snapping to the last ayah.
int resolveToAyahOnSurahChange({
  required int selectedSurahAyahCount,
}) => selectedSurahAyahCount;

/// Mirrors "from" surah selection resetting ayah to 1.
int resolveFromAyahOnSurahChange() => 1;

/// Mirrors compact ayah jump buttons.
int jumpAyah({
  required int current,
  required int ayahCount,
  required bool toFirst,
}) => toFirst ? 1 : ayahCount;

/// Mirrors mutable-anchor preset application for thisAyah / thisSurah.
({int fromSurah, int fromAyah, int toSurah, int toAyah}) applyAnchoredPreset({
  required RangeScopePreset preset,
  required int anchorSurah,
  required int anchorAyah,
  required int Function(int surah) ayahCountOf,
}) {
  switch (preset) {
    case RangeScopePreset.thisAyah:
      return (
        fromSurah: anchorSurah,
        fromAyah: anchorAyah,
        toSurah: anchorSurah,
        toAyah: anchorAyah,
      );
    case RangeScopePreset.thisSurah:
      final count = ayahCountOf(anchorSurah);
      return (
        fromSurah: anchorSurah,
        fromAyah: 1,
        toSurah: anchorSurah,
        toAyah: count,
      );
    case RangeScopePreset.continueFromHere:
      return (
        fromSurah: anchorSurah,
        fromAyah: anchorAyah,
        toSurah: anchorSurah,
        toAyah: anchorAyah,
      );
    case RangeScopePreset.custom:
    case RangeScopePreset.thisJuz:
    case RangeScopePreset.thisHizb:
      throw UnsupportedError('Not mirrored for this helper');
  }
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

    test('anchor follows user-edited from across preset switches', () {
      // Seed opened on Al-Fatiha ayah 1; user then picks Al-Ikhlas ayah 3.
      var anchorSurah = 1;
      var anchorAyah = 1;

      // editFromSurah(112) + editFromAyah(3) update the mutable anchor.
      anchorSurah = 112;
      anchorAyah = 3;

      final thisAyah = applyAnchoredPreset(
        preset: RangeScopePreset.thisAyah,
        anchorSurah: anchorSurah,
        anchorAyah: anchorAyah,
        ayahCountOf: (_) => 4,
      );
      expect(thisAyah.fromSurah, 112);
      expect(thisAyah.fromAyah, 3);
      expect(thisAyah.toSurah, 112);
      expect(thisAyah.toAyah, 3);

      final thisSurah = applyAnchoredPreset(
        preset: RangeScopePreset.thisSurah,
        anchorSurah: anchorSurah,
        anchorAyah: anchorAyah,
        ayahCountOf: (s) => s == 112 ? 4 : 7,
      );
      expect(thisSurah.fromSurah, 112);
      expect(thisSurah.fromAyah, 1);
      expect(thisSurah.toSurah, 112);
      expect(thisSurah.toAyah, 4);

      final continueFrom = applyAnchoredPreset(
        preset: RangeScopePreset.continueFromHere,
        anchorSurah: anchorSurah,
        anchorAyah: anchorAyah,
        ayahCountOf: (_) => 4,
      );
      expect(continueFrom.fromSurah, 112);
      expect(continueFrom.fromAyah, 3);
    });

    test('from-surah change resets ayah to 1', () {
      expect(resolveFromAyahOnSurahChange(), 1);

      // Custom: was 2:255, pick surah 3 → ayah resets to 1 (not clamped 255).
      var fromSurah = 2;
      var fromAyah = 255;
      fromSurah = 3;
      fromAyah = resolveFromAyahOnSurahChange();
      expect(fromSurah, 3);
      expect(fromAyah, 1);
    });

    test('seed ayah prefers playback current over range from', () {
      final viewed = Ayah(
        ayahId: 1,
        surahNumber: 1,
        numberInSurah: 1,
        page: 1,
        juz: 1,
        text: '',
      );
      final seed = resolveRangeDialogSeed(
        viewedAyah: viewed,
        playbackSurah: 2,
        playbackAyah: 10,
        playbackRangeFromSurah: 2,
        playbackRangeFromAyah: 1,
        playbackRangeToSurah: 2,
        playbackRangeToAyah: 286,
        lastFromSurah: null,
        lastFromAyah: null,
        lastToSurah: null,
        lastToAyah: null,
      );

      expect(seed.seedSurah, 2);
      expect(seed.seedAyah, 10);
      // Endpoints still prefer the active range bounds.
      expect(seed.fromSurah, 2);
      expect(seed.fromAyah, 1);
      expect(seed.toSurah, 2);
      expect(seed.toAyah, 286);
    });

    test(
      'dialog seeds from viewed ayah when not playing and no saved range',
      () {
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
          playbackRangeFromSurah: null,
          playbackRangeFromAyah: null,
          playbackRangeToSurah: null,
          playbackRangeToAyah: null,
          lastFromSurah: null,
          lastFromAyah: null,
          lastToSurah: null,
          lastToAyah: null,
        );

        expect(seed.seedSurah, 114);
        expect(seed.seedAyah, 5);
        expect(seed.fromSurah, 114);
        expect(seed.fromAyah, 5);
        expect(seed.toSurah, 114);
        expect(seed.toAyah, 5);
      },
    );

    test('saved multi-surah range wins over viewed ayah', () {
      final viewed = Ayah(
        ayahId: 2350,
        surahNumber: 20,
        numberInSurah: 64,
        page: 315,
        juz: 16,
        text: '',
      );
      final seed = resolveRangeDialogSeed(
        viewedAyah: viewed,
        playbackSurah: 20,
        playbackAyah: 64,
        playbackRangeFromSurah: null,
        playbackRangeFromAyah: null,
        playbackRangeToSurah: null,
        playbackRangeToAyah: null,
        lastFromSurah: 19,
        lastFromAyah: 1,
        lastToSurah: 20,
        lastToAyah: 135,
      );

      expect(seed.fromSurah, 19);
      expect(seed.fromAyah, 1);
      expect(seed.toSurah, 20);
      expect(seed.toAyah, 135);
    });

    test('saved full single-surah range wins over viewed ayah', () {
      final viewed = Ayah(
        ayahId: 1,
        surahNumber: 1,
        numberInSurah: 1,
        page: 1,
        juz: 1,
        text: '',
      );
      final seed = resolveRangeDialogSeed(
        viewedAyah: viewed,
        playbackSurah: 1,
        playbackAyah: 1,
        playbackRangeFromSurah: null,
        playbackRangeFromAyah: null,
        playbackRangeToSurah: null,
        playbackRangeToAyah: null,
        lastFromSurah: 1,
        lastFromAyah: 1,
        lastToSurah: 1,
        lastToAyah: 7,
      );

      expect(seed.fromSurah, 1);
      expect(seed.fromAyah, 1);
      expect(seed.toSurah, 1);
      expect(seed.toAyah, 7);
    });

    test('selecting to-surah snaps ayah to last ayah of that surah', () {
      expect(resolveToAyahOnSurahChange(selectedSurahAyahCount: 135), 135);
      expect(resolveToAyahOnSurahChange(selectedSurahAyahCount: 7), 7);
    });

    test('ayah jump buttons move to first and last ayah', () {
      expect(
        jumpAyah(current: 64, ayahCount: 135, toFirst: true),
        1,
      );
      expect(
        jumpAyah(current: 64, ayahCount: 135, toFirst: false),
        135,
      );
    });
  });
}
