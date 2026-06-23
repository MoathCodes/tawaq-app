import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';

void main() {
  group('HiveQuranRepository bounds', () {
    HiveQuranRepository? repo;
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      tempDir = Directory.systemTemp.createTempSync('mushaf_reader_bounds_');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      });

      await MushafReaderLibrary.ensureInitialized();
      repo = HiveQuranRepository();
      await repo!.ensureReady();
    });

    tearDownAll(() async {
      repo?.dispose();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('juzAyahBounds returns 30 contiguous ranges', () {
      final repository = repo!;
      expect(repository.juzAyahBounds(0), isNull);
      expect(repository.juzAyahBounds(31), isNull);

      for (var n = 1; n <= 30; n++) {
        final bounds = repository.juzAyahBounds(n);
        expect(bounds, isNotNull, reason: 'juz $n');
        expect(bounds!.startAyahId, greaterThan(0));
        expect(bounds.endAyahId, greaterThanOrEqualTo(bounds.startAyahId));
      }
    });

    test('hizbAyahBounds returns 60 contiguous ranges', () {
      final repository = repo!;
      expect(repository.hizbAyahBounds(0), isNull);
      expect(repository.hizbAyahBounds(61), isNull);

      for (var n = 1; n <= 60; n++) {
        final bounds = repository.hizbAyahBounds(n);
        expect(bounds, isNotNull, reason: 'hizb $n');
        expect(bounds!.startAyahId, greaterThan(0));
        expect(bounds.endAyahId, greaterThanOrEqualTo(bounds.startAyahId));
      }
    });

    test('juz adjacency via repository', () {
      final repository = repo!;
      for (var n = 1; n < 30; n++) {
        final current = repository.juzAyahBounds(n)!;
        final next = repository.juzAyahBounds(n + 1)!;
        expect(current.endAyahId + 1, next.startAyahId);
      }
    });

    test('hizb adjacency via repository', () {
      final repository = repo!;
      for (var n = 1; n < 60; n++) {
        final current = repository.hizbAyahBounds(n)!;
        final next = repository.hizbAyahBounds(n + 1)!;
        expect(current.endAyahId + 1, next.startAyahId);
      }
    });

    test('juz 9 and 10 bounds at Al-Anfal 40/41 split', () async {
      final repository = repo!;
      final j9 = repository.juzAyahBounds(9)!;
      final j10 = repository.juzAyahBounds(10)!;

      final end = await repository.getAyah(j9.endAyahId);
      final start = await repository.getAyah(j10.startAyahId);

      expect(end.surahNumber, 8);
      expect(end.numberInSurah, 40);
      expect(start.surahNumber, 8);
      expect(start.numberInSurah, 41);
    });

    test('hizb 1 starts at Al-Fatiha 1', () async {
      final repository = repo!;
      final bounds = repository.hizbAyahBounds(1)!;
      final start = await repository.getAyah(bounds.startAyahId);
      expect(start.surahNumber, 1);
      expect(start.numberInSurah, 1);
    });

    test('hizb 60 ends at An-Nas 6', () async {
      final repository = repo!;
      final bounds = repository.hizbAyahBounds(60)!;
      final end = await repository.getAyah(bounds.endAyahId);
      expect(end.surahNumber, 114);
      expect(end.numberInSurah, 6);
    });

    test('getHizbSync exposes denormalized start metadata', () {
      final repository = repo!;
      final hizb = repository.getHizbSync(1);
      expect(hizb, isNotNull);
      expect(hizb!.startAyahId, repository.hizbAyahBounds(1)!.startAyahId);
      expect(hizb.startSurahNumber, 1);
      expect(hizb.startAyahInSurah, 1);
      expect(hizb.startHizbQuarter, 1);
    });
  });
}
