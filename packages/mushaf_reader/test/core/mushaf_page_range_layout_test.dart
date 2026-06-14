import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() {
  group('MushafPageRangeLayout.basmalah rules', () {
    test('hides basmalah for Al-Fatiha and At-Tawbah', () {
      final block = _block(surahNumber: 1, ayahIds: [1]);
      expect(
        MushafPageRangeLayout.shouldShowBasmalah(block, {1}),
        isFalse,
      );

      final tawbah = _block(surahNumber: 9, ayahIds: [100]);
      expect(
        MushafPageRangeLayout.shouldShowBasmalah(tawbah, {100}),
        isFalse,
      );
    });

    test('shows basmalah when selection starts a normal surah block', () {
      final block = _block(surahNumber: 2, ayahIds: [8, 9]);
      expect(
        MushafPageRangeLayout.shouldShowBasmalah(block, {8}),
        isTrue,
      );
      expect(
        MushafPageRangeLayout.shouldShowBasmalah(block, {9}),
        isFalse,
      );
    });
  });

  group('MushafPageRangeLayout.surah header rules', () {
    test('spansMultipleSurahs detects cross-surah selections', () {
      final page = _page([
        _block(surahNumber: 1, ayahIds: [1, 2]),
        _block(surahNumber: 2, ayahIds: [8, 9]),
      ]);

      expect(MushafPageRangeLayout.spansMultipleSurahs(page, [1]), isFalse);
      expect(MushafPageRangeLayout.spansMultipleSurahs(page, [1, 8]), isTrue);
    });

    test('shows header for any selected ayah in the block', () {
      final block = _block(surahNumber: 2, ayahIds: [8, 9]);

      expect(
        MushafPageRangeLayout.shouldShowSurahHeader(block, {8}),
        isTrue,
      );
      expect(
        MushafPageRangeLayout.shouldShowSurahHeader(block, {9}),
        isTrue,
      );
      expect(
        MushafPageRangeLayout.shouldShowSurahHeader(block, {10}),
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
        MushafPageRangeLayout.shouldShowSurahHeader(block, {6200}),
        isTrue,
      );
    });

    test('surahHeaderPossible when selection touches a block', () {
      final page = _page([
        _block(surahNumber: 1, ayahIds: [1, 2]),
        _block(surahNumber: 102, ayahIds: [6200, 6201], hasBasmalah: false),
      ]);

      expect(MushafPageRangeLayout.surahHeaderPossible(page, [6200]), isTrue);
      expect(MushafPageRangeLayout.surahHeaderPossible(page, [1, 6200]), isTrue);
      expect(MushafPageRangeLayout.surahHeaderPossible(page, []), isFalse);
    });
  });

  group('MushafPageRangeLayout.newline compaction', () {
    test('newlinesWouldCompact is true when any block compacts', () {
      final page = _page([
        _block(surahNumber: 100, ayahIds: [6000, 6001, 6002], hasBasmalah: false),
      ]);

      expect(
        MushafPageRangeLayout.newlinesWouldCompact(page, {6001, 6002}),
        isTrue,
      );
      expect(
        MushafPageRangeLayout.newlinesWouldCompact(page, {6000, 6001, 6002}),
        isFalse,
      );
    });

    test('strips when selection starts mid surah block', () {
      final page = _page([
        _block(surahNumber: 100, ayahIds: [6000, 6001, 6002], hasBasmalah: false),
      ]);

      expect(
        MushafPageRangeLayout.shouldCompactNewlines(
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
        MushafPageRangeLayout.shouldCompactNewlines(
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
        MushafPageRangeLayout.shouldCompactNewlines(
          page,
          page.surahs.first,
          {6000},
        ),
        isFalse,
      );
      expect(
        MushafPageRangeLayout.shouldCompactNewlines(
          page,
          page.surahs.first,
          {6001},
        ),
        isTrue,
      );
    });
  });

  group('MushafPageRangeLayout.contiguous ids', () {
    test('contiguousGlobalIds is inclusive', () {
      expect(
        MushafPageRangeLayout.contiguousGlobalIds(
          startAyahId: 3,
          endAyahId: 5,
        ),
        [3, 4, 5],
      );
    });

    test('contiguousIdsOnPage follows reading order', () {
      final page = _page([
        _block(surahNumber: 1, ayahIds: [1, 2, 3]),
      ]);
      expect(
        MushafPageRangeLayout.contiguousIdsOnPage(
          page,
          startAyahId: 2,
          endAyahId: 3,
        ),
        [2, 3],
      );
    });
  });
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
