import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/hive/hive_adapters.dart';
import 'package:path/path.dart' as p;
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';

class _BoundsTestRepo implements IQuranRepository {
  _BoundsTestRepo(this._juzs, this._hizbs, this._ayahs);

  final Map<int, Juz> _juzs;
  final Map<int, Hizb> _hizbs;
  final Map<int, Ayah> _ayahs;

  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async {
    final ayah = _ayahs[ayahId];
    if (ayah == null) throw ArgumentError('missing $ayahId');
    return ayah;
  }

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    final match = _ayahs.values.firstWhere(
      (a) => a.surahNumber == surah && a.numberInSurah == ayahInSurah,
    );
    return match;
  }

  @override
  Future<String> getBasmalah() async => '';

  @override
  String? getBasmalahSync() => null;

  @override
  Future<Juz> getJuz(int number) async => _juzs[number]!;

  @override
  Future<List<Juz>> getJuzs() async => _juzs.values.toList();

  @override
  Map<int, Juz> getJuzsSync() => _juzs;

  @override
  Future<int> getJuzStartPage(int juzNumber) async => 1;

  @override
  Juz? getJuzSync(int number) => _juzs[number];

  @override
  ({int startAyahId, int endAyahId})? juzAyahBounds(int juzNumber) {
    final juz = _juzs[juzNumber];
    final start = juz?.startAyahId;
    final end = juz?.endAyahId;
    if (start == null || end == null) return null;
    return (startAyahId: start, endAyahId: end);
  }

  @override
  Future<Hizb> getHizb(int number) async => _hizbs[number]!;

  @override
  Future<List<Hizb>> getHizbs() async => _hizbs.values.toList();

  @override
  Map<int, Hizb> getHizbsSync() => _hizbs;

  @override
  Future<int> getHizbStartPage(int hizbNumber) async => 1;

  @override
  Hizb? getHizbSync(int number) => _hizbs[number];

  @override
  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) {
    final hizb = _hizbs[hizbNumber];
    final start = hizb?.startAyahId;
    final end = hizb?.endAyahId;
    if (start == null || end == null) return null;
    return (startAyahId: start, endAyahId: end);
  }

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
  Future<int> getPageForAyah(int ayahId) async => _ayahs[ayahId]!.page;

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
  }) async => [];

  @override
  Future<void> warmUpSearchIndex() async {}
}

void main() {
  group('recitation_range division resolution', () {
    late MushafReaderController controller;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      var dir = Directory.current;
      while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
        dir = dir.parent;
      }
      final hivePath = p.join(
        dir.path,
        'packages',
        'mushaf_reader',
        'assets',
        'hive',
      );
      Hive.init(hivePath);
      Hive
        ..registerAdapter(JuzAdapter())
        ..registerAdapter(HizbAdapter())
        ..registerAdapter(AyahAdapter());

      final juzsBox = await Hive.openBox<Juz>('juzs');
      final hizbsBox = await Hive.openBox<Hizb>('hizbs');
      final ayahsBox = await Hive.openLazyBox<Ayah>('ayahs');

      final juzs = {for (final k in juzsBox.keys) k as int: juzsBox.get(k)!};
      final hizbs = {for (final k in hizbsBox.keys) k as int: hizbsBox.get(k)!};
      final ayahs = <int, Ayah>{};

      Future<void> cacheAyah(int id) async {
        ayahs[id] = (await ayahsBox.get(id))!;
      }

      final juz10 = juzs[10]!;
      await cacheAyah(juz10.startAyahId!);
      await cacheAyah(juz10.endAyahId!);

      final anfal1 = ayahs[juz10.startAyahId!]!;
      final hizbNum = anfal1.hizb!;
      final hizbBounds = (
        startAyahId: hizbs[hizbNum]!.startAyahId!,
        endAyahId: hizbs[hizbNum]!.endAyahId!,
      );
      await cacheAyah(hizbBounds.startAyahId);
      await cacheAyah(hizbBounds.endAyahId);

      controller = MushafReaderController.withRepository(
        repository: _BoundsTestRepo(juzs, hizbs, ayahs),
      );
      await controller.ensureReady();

      await juzsBox.close();
      await hizbsBox.close();
      await ayahsBox.close();
      await Hive.close();
    });

    test('juzNumberForAyah resolves from From endpoint', () async {
      final juz = await juzNumberForAyah(controller, 8, 41);
      expect(juz, 10);
    });

    test('resolveJuzAyahRange uses hive endAyahId for juz 10', () async {
      final range = await resolveJuzAyahRange(
        mushaf: controller,
        juzNumber: 10,
      );
      expect(range, isNotNull);
      expect(range!.from, const AyahReference(surah: 8, ayah: 41));
      expect(range.to, const AyahReference(surah: 9, ayah: 92));
    });

    test('hizbNumberForAyah resolves Al-Anfal 41', () async {
      final hizb = await hizbNumberForAyah(controller, 8, 41);
      expect(hizb, 19);
    });

    test('resolveHizbAyahRange uses hive endAyahId for hizb 19', () async {
      final range = await resolveHizbAyahRange(
        mushaf: controller,
        hizbNumber: 19,
      );
      expect(range, isNotNull);
      expect(range!.from, const AyahReference(surah: 8, ayah: 41));
      expect(range.to, const AyahReference(surah: 9, ayah: 33));
    });

    test('resolveJuzRangeForAyah returns resolved range', () async {
      final result = await resolveJuzRangeForAyah(controller, 8, 41);
      expect(result.error, isNull);
      expect(result.range, isNotNull);
      expect(result.range!.from, const AyahReference(surah: 8, ayah: 41));
      expect(result.range!.to, const AyahReference(surah: 9, ayah: 92));
    });

    test('resolveHizbRangeForAyah returns resolved range', () async {
      final result = await resolveHizbRangeForAyah(controller, 8, 41);
      expect(result.error, isNull);
      expect(result.range, isNotNull);
      expect(result.range!.from, const AyahReference(surah: 8, ayah: 41));
      expect(result.range!.to, const AyahReference(surah: 9, ayah: 33));
    });
  });

  group('firstSegmentForRange / nextSegmentForRange', () {
    late MushafReaderController controller;

    setUp(() async {
      controller = MushafReaderController.withRepository(
        repository: _SegmentTestRepo(),
      );
      await controller.ensureReady();
    });

    test('cross-surah juz range 8:41→9:92', () {
      const from = AyahReference(surah: 8, ayah: 41);
      const to = AyahReference(surah: 9, ayah: 92);

      final first = firstSegmentForRange(
        from: from,
        to: to,
        mushaf: controller,
      );
      expect(first, (surah: 8, startAyah: 41, endAyah: 75));

      final next = nextSegmentForRange(
        from: from,
        to: to,
        currentSurah: 8,
        mushaf: controller,
      );
      expect(next, (surah: 9, startAyah: 1, endAyah: 92));
    });

    test('open-ended range first segment runs to end of starting surah', () {
      const from = AyahReference(surah: 8, ayah: 41);

      final first = firstSegmentForRange(
        from: from,
        to: null,
        mushaf: controller,
      );
      expect(first, (surah: 8, startAyah: 41, endAyah: 75));
    });

    test('open-ended range next segment runs to end of next surah', () {
      const from = AyahReference(surah: 8, ayah: 41);

      final next = nextSegmentForRange(
        from: from,
        to: null,
        currentSurah: 8,
        mushaf: controller,
      );
      expect(next, (surah: 9, startAyah: 1, endAyah: 129));
    });

    test('open-ended range stops after surah 114', () {
      const from = AyahReference(surah: 114, ayah: 1);

      final next = nextSegmentForRange(
        from: from,
        to: null,
        currentSurah: 114,
        mushaf: controller,
      );
      expect(next, isNull);
    });

    test(
      'isGlobalRangeComplete is false until end of Quran for open-ended',
      () {
        expect(
          isGlobalRangeComplete(
            to: null,
            surah: 8,
            endAyah: 75,
            mushaf: controller,
          ),
          isFalse,
        );
        expect(
          isGlobalRangeComplete(
            to: null,
            surah: 9,
            endAyah: 129,
            mushaf: controller,
          ),
          isFalse,
        );
      },
    );
  });

  group('isWholeSurahEndpoints / rangeNeedsAyahTiming', () {
    late MushafReaderController controller;

    setUp(() async {
      controller = MushafReaderController.withRepository(
        repository: _SegmentTestRepo(),
      );
      await controller.ensureReady();
    });

    test('detects same-surah full endpoints', () {
      const from = AyahReference(surah: 8, ayah: 1);
      const to = AyahReference(surah: 8, ayah: 75);

      expect(isWholeSurahEndpoints(from, to, controller), isTrue);
      expect(
        rangeNeedsAyahTiming(
          preset: RangeScopePreset.custom,
          from: from,
          to: to,
          mushaf: controller,
        ),
        isFalse,
      );
    });

    test('detects cross-surah full endpoints', () {
      const from = AyahReference(surah: 8, ayah: 1);
      const to = AyahReference(surah: 9, ayah: 129);

      expect(isWholeSurahEndpoints(from, to, controller), isTrue);
      expect(
        rangeNeedsAyahTiming(
          preset: RangeScopePreset.custom,
          from: from,
          to: to,
          mushaf: controller,
        ),
        isFalse,
      );
    });

    test('partial custom range still needs timing', () {
      const from = AyahReference(surah: 8, ayah: 2);
      const to = AyahReference(surah: 8, ayah: 75);

      expect(isWholeSurahEndpoints(from, to, controller), isFalse);
      expect(
        rangeNeedsAyahTiming(
          preset: RangeScopePreset.custom,
          from: from,
          to: to,
          mushaf: controller,
        ),
        isTrue,
      );
    });
  });
}

class _SegmentTestRepo implements IQuranRepository {
  static final _surahs = <int, Surah>{
    8: Surah(number: 8, glyph: 'S8', hasBasmalah: true, ayahCount: 75),
    9: Surah(number: 9, glyph: 'S9', hasBasmalah: false, ayahCount: 129),
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
  ]) => throw UnimplementedError();

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
  }) async => [];

  @override
  Future<void> warmUpSearchIndex() async {}
}
