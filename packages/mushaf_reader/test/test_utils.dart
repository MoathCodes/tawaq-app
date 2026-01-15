import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/line_model.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

class MockQuranRepository implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    return List.generate(
      114,
      (i) => SurahModel(
        number: i + 1,
        nameArabic: 'Surah ${i + 1}',
        nameEnglish: 'Surah ${i + 1}',
        glyph: 'S${i + 1}',
        hasBasmalah: i != 8,
      ),
    );
  }

  @override
  Future<AyahModel> getAyah(int ayahId, [bool removeNewLines = true]) async {
    return AyahModel(
      id: ayahId,
      surah: 1,
      numberInSurah: ayahId,
      juz: 1,
      page: 1,
      text: 'Ayah $ayahId text',
    );
  }

  @override
  Future<AyahModel> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    return AyahModel(
      id: 1,
      surah: surah,
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
  Future<JuzModel> getJuz(int number) async {
    return JuzModel(number: number, glyph: 'Juz $number');
  }

  @override
  Future<List<JuzModel>> getJuzs() async {
    return List.generate(
      30,
      (i) => JuzModel(number: i + 1, glyph: 'Juz ${i + 1}'),
    );
  }

  @override
  Map<int, JuzModel> getJuzsSync() {
    return {
      for (var i = 1; i <= 30; i++) i: JuzModel(number: i, glyph: 'Juz $i'),
    };
  }

  @override
  Future<int> getJuzStartPage(int juzNumber) async => (juzNumber - 1) * 20 + 2;

  @override
  JuzModel? getJuzSync(int number) =>
      JuzModel(number: number, glyph: 'Juz $number');

  @override
  Future<QuranPageModel> getPage(int page) async {
    // Generate dummy page content
    // Page 1: Surah 1, Ayahs 1-7
    // Page 2: Surah 2, Ayahs 1-5

    List<SurahBlock> blocks = [];
    List<LineModel> lines = [];
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

    return QuranPageModel(
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
  Future<SurahModel?> getSurah(int surahNumber) async {
    return SurahModel(
      number: surahNumber,
      nameArabic: 'Surah $surahNumber',
      nameEnglish: 'Surah $surahNumber',
      glyph: 'S$surahNumber',
      hasBasmalah: surahNumber != 9,
    );
  }

  @override
  List<SurahModel> getSurahsSync() {
    return List.generate(
      114,
      (i) => SurahModel(
        number: i + 1,
        nameArabic: 'Surah ${i + 1}',
        nameEnglish: 'Surah ${i + 1}',
        glyph: 'S${i + 1}',
        hasBasmalah: (i + 1) != 9,
      ),
    );
  }
}
