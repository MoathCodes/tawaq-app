import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';

void main() {
  group('mushafAyahOrNull', () {
    late MushafReaderController mushaf;

    setUp(() {
      mushaf = MushafReaderController.withRepository(
        repository: _AnNamlRepo(),
      );
    });

    test('returns ayah when within Hafs ayahCount', () async {
      final ayah = await mushafAyahOrNull(mushaf, 27, 93);
      expect(ayah, isNotNull);
      expect(ayah!.surahNumber, 27);
      expect(ayah.numberInSurah, 93);
    });

    test('returns null for non-Hafs timing ayah beyond mushaf count', () async {
      // السوسي timing for An-Naml includes 94/95; Hafs stops at 93.
      expect(await mushafAyahOrNull(mushaf, 27, 94), isNull);
      expect(await mushafAyahOrNull(mushaf, 27, 95), isNull);
    });

    test('returns null for ayah < 1 without throwing', () async {
      expect(await mushafAyahOrNull(mushaf, 27, 0), isNull);
      expect(await mushafAyahOrNull(mushaf, 27, -1), isNull);
    });

    test('returns null when getAyahBySurah throws ArgumentError', () async {
      final throwing = MushafReaderController.withRepository(
        repository: _ThrowingRepo(),
      );
      expect(await mushafAyahOrNull(throwing, 1, 1), isNull);
    });
  });
}

class _AnNamlRepo implements IQuranRepository {
  static final _surahs = <int, Surah>{
    27: Surah(number: 27, glyph: 'Naml', hasBasmalah: true, ayahCount: 93),
  };

  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => _surahs.values.toList();

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    final count = _surahs[surah]?.ayahCount;
    if (count == null || ayahInSurah < 1 || ayahInSurah > count) {
      throw ArgumentError('Ayah $surah:$ayahInSurah not found');
    }
    return Ayah(
      ayahId: surah * 1000 + ayahInSurah,
      juz: 19,
      page: 377,
      surahNumber: surah,
      numberInSurah: ayahInSurah,
      text: 'text',
      textPlain: '$surah:$ayahInSurah',
    );
  }

  @override
  Future<String> getBasmalah() async => '';

  @override
  String? getBasmalahSync() => null;

  @override
  Future<Juz> getJuz(int number) => throw UnimplementedError();

  @override
  Future<List<Juz>> getJuzs() async => [];

  @override
  Map<int, Juz> getJuzsSync() => {};

  @override
  Future<int> getJuzStartPage(int juzNumber) async => 1;

  @override
  Juz? getJuzSync(int number) => null;

  @override
  ({int startAyahId, int endAyahId})? juzAyahBounds(int juzNumber) => null;

  @override
  Future<Hizb> getHizb(int number) => throw UnimplementedError();

  @override
  Future<List<Hizb>> getHizbs() async => [];

  @override
  Map<int, Hizb> getHizbsSync() => {};

  @override
  Future<int> getHizbStartPage(int hizbNumber) async => 1;

  @override
  Hizb? getHizbSync(int number) => null;

  @override
  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) => null;

  @override
  Future<QuranPage> getPage(int page) async => QuranPage(
    pageNumber: page,
    glyphText: '',
    lines: const [],
    surahs: const [],
    juzNumber: 1,
  );

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurah(int number) async => _surahs[number];

  @override
  List<Surah> getSurahsSync() => _surahs.values.toList();

  @override
  Surah? getSurahSync(int number) => _surahs[number];

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async => [];

  @override
  Future<void> warmUpSearchIndex() async {}
}

/// Surah metadata present so count guard is skipped; lookup always throws.
class _ThrowingRepo extends _AnNamlRepo {
  @override
  Surah? getSurahSync(int number) =>
      Surah(number: number, glyph: 'X', hasBasmalah: true, ayahCount: 999);

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    throw ArgumentError('Ayah $surah:$ayahInSurah not found');
  }
}
