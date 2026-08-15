import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/hive/hive_adapters.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/hizb.dart';
import 'package:mushaf_reader/src/data/models/juz.dart';
import '../hive_test_support.dart';

void main() {
  group('division bounds', () {
    late Box<Juz> juzsBox;
    late Box<Hizb> hizbsBox;
    late LazyBox<Ayah> ayahsBox;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      Hive.init(bundledHiveAssetsPath());
      Hive
        ..registerAdapter(JuzAdapter())
        ..registerAdapter(HizbAdapter())
        ..registerAdapter(AyahAdapter());

      juzsBox = await Hive.openBox<Juz>('juzs');
      hizbsBox = await Hive.openBox<Hizb>('hizbs');
      ayahsBox = await Hive.openLazyBox<Ayah>('ayahs');
    });

    tearDownAll(() async {
      await juzsBox.close();
      await hizbsBox.close();
      await ayahsBox.close();
      await Hive.close();
    });

    Future<Ayah> ayah(int id) async {
      final a = await ayahsBox.get(id);
      if (a == null) throw StateError('Ayah $id missing');
      return a;
    }

    ({int startAyahId, int endAyahId})? juzBounds(int number) {
      final juz = juzsBox.get(number);
      final start = juz?.startAyahId;
      final end = juz?.endAyahId;
      if (start == null || end == null) return null;
      return (startAyahId: start, endAyahId: end);
    }

    ({int startAyahId, int endAyahId})? hizbBounds(int number) {
      final hizb = hizbsBox.get(number);
      final start = hizb?.startAyahId;
      final end = hizb?.endAyahId;
      if (start == null || end == null) return null;
      return (startAyahId: start, endAyahId: end);
    }

    Future<void> expectBounds({
      required ({int startAyahId, int endAyahId}) bounds,
      required int startSurah,
      required int startAyahInSurah,
      required int endSurah,
      required int endAyahInSurah,
    }) async {
      final start = await ayah(bounds.startAyahId);
      final end = await ayah(bounds.endAyahId);
      expect(start.surahNumber, startSurah);
      expect(start.numberInSurah, startAyahInSurah);
      expect(end.surahNumber, endSurah);
      expect(end.numberInSurah, endAyahInSurah);
    }

    test('juz and hizb box counts', () {
      expect(juzsBox.length, 30);
      expect(hizbsBox.length, 60);
    });

    test('juz adjacency: end + 1 equals next start', () {
      for (var n = 1; n < 30; n++) {
        final current = juzBounds(n)!;
        final next = juzBounds(n + 1)!;
        expect(current.endAyahId + 1, next.startAyahId);
      }
    });

    test('hizb adjacency: end + 1 equals next start', () {
      for (var n = 1; n < 60; n++) {
        final current = hizbBounds(n)!;
        final next = hizbBounds(n + 1)!;
        expect(current.endAyahId + 1, next.startAyahId);
      }
    });

    test('neighbor ayah boundaries at juz 9/10 and juz 10/11 splits', () async {
      final id840 = Ayah.globalIdFor(surah: 8, ayahInSurah: 40)!;
      final id841 = Ayah.globalIdFor(surah: 8, ayahInSurah: 41)!;
      final id993 = Ayah.globalIdFor(surah: 9, ayahInSurah: 93)!;

      expect((await ayah(id840)).juz, 9);
      expect((await ayah(id841)).juz, 10);
      expect((await ayah(id993)).juz, 11);
    });

    test('hizb 1 denormalized fields', () {
      final hizb = hizbsBox.get(1)!;
      expect(hizb.startAyahId, 1);
      expect(hizb.startSurahNumber, 1);
      expect(hizb.startAyahInSurah, 1);
      expect(hizb.startHizbQuarter, 1);
      expect(hizb.startPage, isNotNull);
    });

    test('hizb 30 denormalized fields match first ayah in hizb', () async {
      final hizb = hizbsBox.get(30)!;
      final start = await ayah(hizb.startAyahId!);
      expect(hizb.startSurahNumber, start.surahNumber);
      expect(hizb.startAyahInSurah, start.numberInSurah);
      expect(hizb.startHizbQuarter, start.hizbQuarter);
      expect(hizb.startPage, start.page);
      expect(start.hizb, 30);
    });

    test('juz 9 spans Al-Araf 88 through Al-Anfal 40', () async {
      final bounds = juzBounds(9)!;
      await expectBounds(
        bounds: bounds,
        startSurah: 7,
        startAyahInSurah: 88,
        endSurah: 8,
        endAyahInSurah: 40,
      );
      final start = await ayah(bounds.startAyahId);
      final end = await ayah(bounds.endAyahId);
      expect(start.juz, 9);
      expect(end.juz, 9);
    });

    test('juz 10 spans Al-Anfal 41 through At-Tawbah 92', () async {
      final bounds = juzBounds(10)!;
      await expectBounds(
        bounds: bounds,
        startSurah: 8,
        startAyahInSurah: 41,
        endSurah: 9,
        endAyahInSurah: 92,
      );
      final start = await ayah(bounds.startAyahId);
      final end = await ayah(bounds.endAyahId);
      expect(start.juz, 10);
      expect(end.juz, 10);
    });

    test('juz 30 ends at An-Nas 6', () async {
      final bounds = juzBounds(30)!;
      final end = await ayah(bounds.endAyahId);
      expect(end.surahNumber, 114);
      expect(end.numberInSurah, 6);
      expect(end.juz, 30);
    });

    test('hizb 1 starts at Al-Fatiha 1', () async {
      final bounds = hizbBounds(1)!;
      final start = await ayah(bounds.startAyahId);
      expect(start.surahNumber, 1);
      expect(start.numberInSurah, 1);
      expect(start.hizb, 1);
    });

    test('hizb 60 ends at An-Nas 6', () async {
      final bounds = hizbBounds(60)!;
      final end = await ayah(bounds.endAyahId);
      expect(end.surahNumber, 114);
      expect(end.numberInSurah, 6);
      expect(end.hizb, 60);
    });

    test('all juz stored endAyahId matches endpoint juz', () async {
      for (final key in juzsBox.keys) {
        final juz = juzsBox.get(key)!;
        expect(juz.endAyahId, isNotNull);
        final bounds = juzBounds(juz.number)!;
        final start = await ayah(bounds.startAyahId);
        final end = await ayah(bounds.endAyahId);
        expect(start.juz, juz.number);
        expect(end.juz, juz.number);
      }
    });

    test('all hizb bounds match derived hizb on endpoints', () async {
      for (final key in hizbsBox.keys) {
        final hizb = hizbsBox.get(key)!;
        final bounds = hizbBounds(hizb.number)!;
        final start = await ayah(bounds.startAyahId);
        final end = await ayah(bounds.endAyahId);
        expect(start.hizb, hizb.number);
        expect(end.hizb, hizb.number);
      }
    });
  });
}
