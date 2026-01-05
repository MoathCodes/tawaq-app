import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/quran_page_model.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';
import 'package:mushaf_reader/src/data/models/surah_model.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

class MockQuranRepository implements IQuranRepository {
  bool ensureReadyCalled = false;
  bool disposeCalled = false;

  @override
  void dispose() {
    disposeCalled = true;
  }

  @override
  Future<void> ensureReady() async {
    ensureReadyCalled = true;
  }

  @override
  Future<AyahModel> getAyah(int ayahId, [bool removeNewLines = true]) async {
    if (ayahId == -1) throw ArgumentError('Ayah not found');
    return AyahModel(
      id: ayahId,
      surah: 1,
      numberInSurah: 1,
      page: 1,
      text: 'test_code',
      juz: 1,
    );
  }

  @override
  Future<AyahModel> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    if (surah == 999) throw ArgumentError('Ayah not found');
    return AyahModel(
      id: 1,
      surah: surah,
      numberInSurah: ayahInSurah,
      page: 1,
      text: 'test_code',
      juz: 1,
    );
  }

  @override
  Future<String> getBasmalah() async {
    return 'basmalah_glyph';
  }

  @override
  Future<JuzModel> getJuz(int number) async {
    return JuzModel(number: number, glyph: 'juz_glyph');
  }

  @override
  Future<List<JuzModel>> getJuzs() async {
    return List.generate(
      30,
      (index) => JuzModel(number: index + 1, glyph: 'juz_glyph'),
    );
  }

  @override
  Future<QuranPageModel> getPage(int page) async {
    return QuranPageModel(
      pageNumber: page,
      glyphText: 'page_glyph',
      lines: [],
      surahs: [
        const SurahBlock(
          surahNumber: 1,
          glyph: 'surah_glyph',
          start: 0,
          end: 10,
          hasBasmalah: true,
          ayahs: [],
        ),
      ],
      juzNumber: 1,
    );
  }

  @override
  Future<SurahModel?> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) return null;
    return SurahModel(
      number: surahNumber,
      glyph: 'surah_glyph',
      hasBasmalah: surahNumber != 9 && surahNumber != 1,
      nameArabic: 'سورة',
      nameEnglish: 'Surah $surahNumber',
      startPage: surahNumber,
    );
  }

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    return List.generate(
      114,
      (index) => SurahModel(
        number: index + 1,
        glyph: 'surah_glyph',
        hasBasmalah: (index + 1) != 9 && (index + 1) != 1,
        nameArabic: 'سورة',
        nameEnglish: 'Surah ${index + 1}',
        startPage: index + 1,
      ),
    );
  }

  @override
  Future<int> getStartPageForSurah(int surahNumber) async {
    return surahNumber; // Simplified: surah N starts on page N
  }

  @override
  Future<int> getPageForAyah(int ayahId) async {
    return 1; // Simplified
  }

  @override
  Future<int> getJuzStartPage(int juzNumber) async {
    return (juzNumber - 1) * 20 + 1; // Simplified
  }

  // Sync methods for cached data access
  String? _basmalahCache;
  final Map<int, JuzModel> _juzCache = {};
  final List<SurahModel> _surahCache = [];

  @override
  String? getBasmalahSync() => _basmalahCache;

  @override
  JuzModel? getJuzSync(int number) => _juzCache[number];

  @override
  List<SurahModel> getSurahsSync() => _surahCache;

  @override
  Map<int, JuzModel> getJuzsSync() => _juzCache;
}
