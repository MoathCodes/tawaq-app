import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_number_search.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_search.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';

void main() {
  group('searchAyahNumbers', () {
    test('exact match ranks first', () {
      expect(
        searchAyahNumbers(ayahCount: 286, query: '286').first,
        286,
      );
    });

    test('prefix match finds partial numbers', () {
      final results = searchAyahNumbers(ayahCount: 286, query: '20').toList();
      expect(results, contains(20));
      expect(results, contains(200));
      expect(results.first, 20);
    });

    test('empty query returns full range', () {
      expect(searchAyahNumbers(ayahCount: 7, query: '').length, 7);
    });
  });

  group('searchHizbs', () {
    late MushafReaderController controller;
    late List<Hizb> hizbs;

    setUp(() async {
      controller = MushafReaderController.withRepository(
        repository: _SearchHizbsTestRepo(),
      );
      await controller.ensureReady();
      hizbs = [
        Hizb(number: 10, startSurahNumber: 5, startAyahInSurah: 1),
        Hizb(number: 19, startSurahNumber: 8, startAyahInSurah: 41),
        Hizb(number: 20, startSurahNumber: 9, startAyahInSurah: 34),
      ];
    });

    test('exact number match ranks first', () {
      final results = searchHizbs(
        hizbs: hizbs,
        controller: controller,
        query: '19',
        isArabic: false,
      ).toList();
      expect(results.first.number, 19);
    });

    test('prefix match on hizb number', () {
      final results = searchHizbs(
        hizbs: hizbs,
        controller: controller,
        query: '1',
        isArabic: false,
      ).toList();
      expect(results.map((h) => h.number), containsAll([10, 19]));
      expect(results.first.number, 10);
    });

    test('prefix match on English surah name', () {
      final results = searchHizbs(
        hizbs: hizbs,
        controller: controller,
        query: 'al-anf',
        isArabic: false,
      ).toList();
      expect(results.single.number, 19);
    });

    test('prefix match on Arabic surah name', () {
      final surah8 = controller.getSurahSync(8)!;
      final simplified = normalizeArabicForSurahSearch(
        surah8.nameArabicSimplified!,
      );
      String? matchingQuery;
      for (var len = 1; len <= simplified.length; len++) {
        final query = simplified.substring(0, len);
        final results = searchHizbs(
          hizbs: hizbs,
          controller: controller,
          query: query,
          isArabic: true,
        );
        if (results.any((h) => h.number == 19)) {
          matchingQuery = query;
          break;
        }
      }

      expect(matchingQuery, isNotNull);
      final results = searchHizbs(
        hizbs: hizbs,
        controller: controller,
        query: matchingQuery!,
        isArabic: true,
      ).toList();
      expect(results.map((h) => h.number), contains(19));
    });

    test('empty query returns all hizbs', () {
      expect(
        searchHizbs(
          hizbs: hizbs,
          controller: controller,
          query: '',
          isArabic: false,
        ).length,
        hizbs.length,
      );
    });
  });

  group('hizbSelectorStartAyahSubtitleForTest', () {
    test('builds subtitle from denormalized hizb start fields', () async {
      final controller = MushafReaderController.withRepository(
        repository: _SubtitleTestRepo(),
      );
      await controller.ensureReady();
      final l10n = AppLocalizationsEn();

      final subtitle = hizbSelectorStartAyahSubtitleForTest(
        hizb: Hizb(
          number: 15,
          startSurahNumber: 16,
          startAyahInSurah: 1,
        ),
        controller: controller,
        isArabic: false,
        l10n: l10n,
        fallbackSurahName: 'Surah 16',
      );

      expect(subtitle, contains('An-Nahl'));
      expect(subtitle, contains('1'));
    });
  });

  group('hizbNumberForAyahId', () {
    test('resolves hizb from ayah bounds', () {
      final controller = MushafReaderController.withRepository(
        repository: _HizbBoundsTestRepo(),
      );

      expect(hizbNumberForAyahId(controller, 5), 1);
      expect(hizbNumberForAyahId(controller, 50), 2);
      expect(hizbNumberForAyahId(controller, 999), isNull);
    });
  });
}

class _SearchHizbsTestRepo implements IQuranRepository {
  static final Map<int, Surah> _surahs = {
    5: Surah(
      number: 5,
      glyph: 'S5',
      hasBasmalah: true,
      nameArabic: 'سُورَةُ ٱلْمَائِدَةِ',
      nameEnglish: 'Al-Maaida',
    ),
    8: Surah(
      number: 8,
      glyph: 'S8',
      hasBasmalah: true,
      nameArabic: 'سُورَةُ ٱلْأَنفَالِ',
      nameEnglish: 'Al-Anfaal',
    ),
    9: Surah(
      number: 9,
      glyph: 'S9',
      hasBasmalah: false,
      nameArabic: 'سُورَةُ ٱلتَّوْبَةِ',
      nameEnglish: 'At-Tawba',
    ),
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
  ]) =>
      throw UnimplementedError();

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
  Future<QuranPage> getPage(int page) async {
    return QuranPage(
      pageNumber: page,
      glyphText: '',
      lines: const [],
      surahs: const [],
      juzNumber: 1,
    );
  }

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurah(int surahNumber) async => _surahs[surahNumber];

  @override
  List<Surah> getSurahsSync() => _surahs.values.toList();

  @override
  Surah? getSurahSync(int number) => _surahs[number];

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async =>
      [];

  @override
  Future<void> warmUpSearchIndex() async {}
}

class _HizbBoundsTestRepo implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) =>
      throw UnimplementedError();

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
  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) {
    return switch (hizbNumber) {
      1 => (startAyahId: 1, endAyahId: 10),
      2 => (startAyahId: 11, endAyahId: 100),
      _ => null,
    };
  }

  @override
  Future<QuranPage> getPage(int page) => throw UnimplementedError();

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurah(int surahNumber) async => null;

  @override
  List<Surah> getSurahsSync() => [];

  @override
  Surah? getSurahSync(int number) => null;

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async =>
      [];

  @override
  Future<void> warmUpSearchIndex() async {}
}

class _SubtitleTestRepo implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [
        Surah(
          number: 16,
          glyph: 'S16',
          hasBasmalah: true,
          nameEnglish: 'An-Nahl',
        ),
      ];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) =>
      throw UnimplementedError();

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
  Future<QuranPage> getPage(int page) async {
    return QuranPage(
      pageNumber: page,
      glyphText: '',
      lines: const [],
      surahs: const [],
      juzNumber: 1,
    );
  }

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurah(int surahNumber) async => null;

  @override
  List<Surah> getSurahsSync() => [];

  @override
  Surah? getSurahSync(int number) {
    if (number == 16) {
      return Surah(
        number: 16,
        glyph: 'S16',
        hasBasmalah: true,
        nameEnglish: 'An-Nahl',
      );
    }
    return null;
  }

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async =>
      [];

  @override
  Future<void> warmUpSearchIndex() async {}
}
