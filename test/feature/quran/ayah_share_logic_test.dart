import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_share_logic.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';

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

  group('AyahShareLogic.basmalah rules', () {
    test('hides basmalah for Al-Fatiha and At-Tawbah', () {
      final block = _block(surahNumber: 1, ayahIds: [1]);
      expect(
        AyahShareLogic.shouldShowShareBasmalah(block, {1}),
        isFalse,
      );

      final tawbah = _block(surahNumber: 9, ayahIds: [100]);
      expect(
        AyahShareLogic.shouldShowShareBasmalah(tawbah, {100}),
        isFalse,
      );
    });

    test('shows basmalah when selection starts a normal surah block', () {
      final block = _block(surahNumber: 2, ayahIds: [8, 9]);
      expect(
        AyahShareLogic.shouldShowShareBasmalah(block, {8}),
        isTrue,
      );
      expect(
        AyahShareLogic.shouldShowShareBasmalah(block, {9}),
        isFalse,
      );
    });
  });

  group('AyahShareLogic.surah header rules', () {
    test('rangeSpansMultipleSurahs detects cross-surah selections', () {
      final page = _page([
        _block(surahNumber: 1, ayahIds: [1, 2]),
        _block(surahNumber: 2, ayahIds: [8, 9]),
      ]);

      expect(AyahShareLogic.rangeSpansMultipleSurahs(page, [1]), isFalse);
      expect(AyahShareLogic.rangeSpansMultipleSurahs(page, [1, 8]), isTrue);
    });

    test('shows header for any selected ayah in the block', () {
      final block = _block(surahNumber: 2, ayahIds: [8, 9]);

      expect(
        AyahShareLogic.shouldShowShareSurahHeader(block, {8}),
        isTrue,
      );
      expect(
        AyahShareLogic.shouldShowShareSurahHeader(block, {9}),
        isTrue,
      );
      expect(
        AyahShareLogic.shouldShowShareSurahHeader(block, {10}),
        isFalse,
      );
    });

    test('shows header for mid-page surah blocks without basmalah', () {
      final block = _block(
        surahNumber: 102,
        ayahIds: [6200, 6201],
        hasBasmalah: false,
      );

      expect(
        AyahShareLogic.shouldShowShareSurahHeader(block, {6200}),
        isTrue,
      );
    });

    test('shareSurahHeaderAvailable when selection touches a block', () {
      final page = _page([
        _block(surahNumber: 1, ayahIds: [1, 2]),
        _block(surahNumber: 102, ayahIds: [6200, 6201], hasBasmalah: false),
      ]);

      expect(AyahShareLogic.shareSurahHeaderAvailable(page, [6200]), isTrue);
      expect(AyahShareLogic.shareSurahHeaderAvailable(page, [1, 6200]), isTrue);
      expect(AyahShareLogic.shareSurahHeaderAvailable(page, []), isFalse);
    });

    test('multi-surah selection shows header for each touched block', () {
      final page = _page([
        _block(surahNumber: 1, ayahIds: [1, 2], hasBasmalah: false),
        _block(surahNumber: 102, ayahIds: [6200, 6201]),
      ]);
      final selected = {1, 6200, 6201};

      for (final block in page.surahs) {
        expect(
          AyahShareLogic.shouldShowShareSurahHeader(block, selected),
          isTrue,
        );
      }
    });
  });

  group('AyahShareLogic.newline compaction', () {
    test('strips when selection starts mid surah block', () {
      final page = _page([
        _block(surahNumber: 100, ayahIds: [6000, 6001, 6002], hasBasmalah: false),
      ]);

      expect(
        AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          page.surahs.first,
          {6001, 6002},
        ),
        isTrue,
      );
    });

    test('keeps breaks when surah opens on page from verse 1', () {
      final page = _page([
        _block(surahNumber: 101, ayahIds: [6200, 6201]),
      ]);

      expect(
        AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          page.surahs.first,
          {6200},
        ),
        isFalse,
      );
    });

    test('strips on first block when page opening is excluded', () {
      final page = _page([
        _block(surahNumber: 100, ayahIds: [6000, 6001], hasBasmalah: false),
      ]);

      expect(
        AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          page.surahs.first,
          {6000},
        ),
        isFalse,
      );
      expect(
        AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          page.surahs.first,
          {6001},
        ),
        isTrue,
      );
    });

    test('applies per block on multi-surah pages', () {
      final page = _page([
        _block(surahNumber: 100, ayahIds: [6000, 6001], hasBasmalah: false),
        _block(surahNumber: 101, ayahIds: [6200, 6201]),
      ]);
      final selected = {6001, 6200, 6201};

      expect(
        AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          page.surahs[0],
          selected,
        ),
        isTrue,
      );
      expect(
        AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          page.surahs[1],
          selected,
        ),
        isFalse,
      );
    });
  });

  group('sliderMarkLabelIndices', () {
    test('omits first and last ayah labels', () {
      final ayahs = [
        _ayah(surahNumber: 1, numberInSurah: 6, ayahId: 6),
        _ayah(surahNumber: 1, numberInSurah: 7, ayahId: 7),
        _ayah(surahNumber: 102, numberInSurah: 1, ayahId: 6200),
        _ayah(surahNumber: 102, numberInSurah: 8, ayahId: 6207),
      ];

      expect(sliderMarkLabelIndices(ayahs), {2});
    });

    test('returns empty set for pages with at most two ayahs', () {
      final ayahs = [
        _ayah(surahNumber: 1, numberInSurah: 1, ayahId: 1),
        _ayah(surahNumber: 102, numberInSurah: 1, ayahId: 6200),
      ];

      expect(sliderMarkLabelIndices(ayahs), isEmpty);
    });
  });
}

Ayah _ayah({
  required int surahNumber,
  required int numberInSurah,
  required int ayahId,
}) {
  return Ayah(
    ayahId: ayahId,
    surahNumber: surahNumber,
    numberInSurah: numberInSurah,
    page: 600,
    juz: 30,
    text: 'text',
  );
}

QuranPage _page(List<SurahBlock> surahs) {
  return QuranPage(
    pageNumber: 1,
    glyphText: 'glyph',
    lines: const [],
    surahs: surahs,
    juzNumber: 1,
  );
}

SurahBlock _block({
  required int surahNumber,
  required List<int> ayahIds,
  bool hasBasmalah = true,
}) {
  return SurahBlock(
    surahNumber: surahNumber,
    glyph: 'glyph',
    start: 0,
    end: ayahIds.length,
    hasBasmalah: hasBasmalah,
    ayahs: [
      for (var i = 0; i < ayahIds.length; i++)
        AyahFragment(
          ayahId: ayahIds[i],
          start: i,
          end: i + 1,
        ),
    ],
  );
}
