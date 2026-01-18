import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/page_line.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

class MockQuranRepository implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async {
    return List.generate(
      114,
      (i) => Surah(
        number: i + 1,
        nameArabic: 'Surah ${i + 1}',
        nameEnglish: 'Surah ${i + 1}',
        glyph: 'S${i + 1}',
        hasBasmalah: i != 8,
      ),
    );
  }

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async {
    return Ayah(
      ayahId: ayahId,
      surahNumber: 1,
      numberInSurah: ayahId,
      juz: 1,
      page: 1,
      text: 'Ayah $ayahId text',
    );
  }

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    return Ayah(
      ayahId: 1,
      surahNumber: surah,
      numberInSurah: ayahInSurah,
      juz: 1,
      page: 1,
      text: 'Ayah $surah:$ayahInSurah text',
    );
  }

  @override
  Future<String> getBasmalah() async => 'Basmalah';

  @override
  String? getBasmalahSync() => 'Basmalah';

  @override
  Future<Juz> getJuz(int number) async {
    return Juz(number: number, glyph: 'Juz $number');
  }

  @override
  Future<List<Juz>> getJuzs() async {
    return List.generate(30, (i) => Juz(number: i + 1, glyph: 'Juz ${i + 1}'));
  }

  @override
  Map<int, Juz> getJuzsSync() {
    return {for (var i = 1; i <= 30; i++) i: Juz(number: i, glyph: 'Juz $i')};
  }

  @override
  Future<int> getJuzStartPage(int juzNumber) async => (juzNumber - 1) * 20 + 2;

  @override
  Juz? getJuzSync(int number) => Juz(number: number, glyph: 'Juz $number');

  @override
  Future<QuranPage> getPage(int page) async {
    // Generate dummy page content
    // Page 1: Surah 1, Ayahs 1-7
    // Page 2: Surah 2, Ayahs 1-5

    List<SurahBlock> blocks = [];
    List<PageLine> lines = [];
    String glyphText = 'Page $page content';

    if (page == 1) {
      blocks.add(
        SurahBlock(
          surahNumber: 1,
          glyph: 'S1',
          start: 0,
          end: glyphText.length,
          hasBasmalah: true,
          ayahs: [
            AyahFragment(ayahId: 1, start: 0, end: 5),
            AyahFragment(ayahId: 2, start: 6, end: 10),
          ],
        ),
      );
    } else {
      blocks.add(
        SurahBlock(
          surahNumber: 2,
          glyph: 'S2',
          start: 0,
          end: glyphText.length,
          hasBasmalah: false,
          ayahs: [AyahFragment(ayahId: 10, start: 0, end: 5)],
        ),
      );
    }

    return QuranPage(
      pageNumber: page,
      juzNumber: 1,
      glyphText: glyphText,
      lines: lines,
      surahs: blocks,
    );
  }

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => surahNumber;

  @override
  Future<Surah?> getSurah(int surahNumber) async {
    return Surah(
      number: surahNumber,
      nameArabic: 'Surah $surahNumber',
      nameEnglish: 'Surah $surahNumber',
      glyph: 'S$surahNumber',
      hasBasmalah: surahNumber != 9,
    );
  }

  @override
  List<Surah> getSurahsSync() {
    return List.generate(
      114,
      (i) => Surah(
        number: i + 1,
        nameArabic: 'Surah ${i + 1}',
        nameEnglish: 'Surah ${i + 1}',
        glyph: 'S${i + 1}',
        hasBasmalah: (i + 1) != 9,
      ),
    );
  }

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async {
    // Return mock results for testing
    return [];
  }
}
