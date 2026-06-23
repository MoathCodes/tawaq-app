import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/page_line.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

class MockQuranRepository implements IQuranRepository {
  static const int _kAyahCount = 6236;

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

  Juz _mockJuz(int number) {
    final bounds = juzAyahBounds(number);
    return Juz(
      number: number,
      glyph: 'Juz $number',
      startPage: (number - 1) * 20 + 2,
      startAyahId: bounds?.startAyahId,
      endAyahId: bounds?.endAyahId,
    );
  }

  @override
  Future<Juz> getJuz(int number) async => _mockJuz(number);

  @override
  Future<List<Juz>> getJuzs() async {
    return List.generate(30, (i) => _mockJuz(i + 1));
  }

  @override
  Map<int, Juz> getJuzsSync() {
    return {for (var i = 1; i <= 30; i++) i: _mockJuz(i)};
  }

  @override
  Future<int> getJuzStartPage(int juzNumber) async => (juzNumber - 1) * 20 + 2;

  @override
  Juz? getJuzSync(int number) {
    if (number < 1 || number > 30) return null;
    return _mockJuz(number);
  }

  @override
  ({int startAyahId, int endAyahId})? juzAyahBounds(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) return null;
    final start = (juzNumber - 1) * 200 + 1;
    final end = juzNumber == 30 ? _kAyahCount : juzNumber * 200;
    return (startAyahId: start, endAyahId: end);
  }

  Hizb _mockHizb(int number) {
    final bounds = hizbAyahBounds(number);
    return Hizb(
      number: number,
      startPage: (number - 1) * 10 + 1,
      startAyahId: bounds?.startAyahId,
      endAyahId: bounds?.endAyahId,
      startSurahNumber: 1,
      startAyahInSurah: 1,
      startHizbQuarter: (number - 1) * 4 + 1,
    );
  }

  @override
  Future<Hizb> getHizb(int number) async => _mockHizb(number);

  @override
  Future<List<Hizb>> getHizbs() async {
    return List.generate(60, (i) => _mockHizb(i + 1));
  }

  @override
  Map<int, Hizb> getHizbsSync() {
    return {for (var i = 1; i <= 60; i++) i: _mockHizb(i)};
  }

  @override
  Future<int> getHizbStartPage(int hizbNumber) async =>
      (hizbNumber - 1) * 10 + 1;

  @override
  Hizb? getHizbSync(int number) {
    if (number < 1 || number > 60) return null;
    return _mockHizb(number);
  }

  @override
  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) {
    if (hizbNumber < 1 || hizbNumber > 60) return null;
    final start = (hizbNumber - 1) * 100 + 1;
    final end = hizbNumber == 60 ? _kAyahCount : hizbNumber * 100;
    return (startAyahId: start, endAyahId: end);
  }

  @override
  QuranPage? peekCachedPage(int page) => null;

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
  Surah? getSurahSync(int number) {
    if (number < 1 || number > 114) return null;
    return Surah(
      number: number,
      nameArabic: 'Surah $number',
      nameEnglish: 'Surah $number',
      glyph: 'S$number',
      hasBasmalah: number != 9,
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

  @override
  Future<void> warmUpSearchIndex() async {}
}
