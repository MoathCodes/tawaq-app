import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';

void main() {
  group('HiveQuranRepository ref count', () {
    tearDown(() {
      while (HiveQuranRepository.refCount > 0) {
        HiveQuranRepository.instance.dispose();
      }
      while (HiveBoxManager.refCount > 0) {
        HiveBoxManager.instance.dispose();
      }
    });

    test('instance does not increment ref count', () {
      expect(HiveQuranRepository.refCount, 0);
      final a = HiveQuranRepository.instance;
      final b = HiveQuranRepository();
      expect(identical(a, b), isTrue);
      expect(HiveQuranRepository.refCount, 0);
    });

    test('acquire/release pairs return count to zero', () {
      final first = HiveQuranRepository.acquire();
      expect(HiveQuranRepository.refCount, 1);

      final second = HiveQuranRepository.acquire();
      expect(identical(first, second), isTrue);
      expect(HiveQuranRepository.refCount, 2);

      first.dispose();
      expect(HiveQuranRepository.refCount, 1);

      second.dispose();
      expect(HiveQuranRepository.refCount, 0);
    });

    test('repeated instance access after teardown creates fresh singleton', () {
      final owned = HiveQuranRepository.acquire();
      owned.dispose();
      expect(HiveQuranRepository.refCount, 0);

      final again = HiveQuranRepository.instance;
      expect(HiveQuranRepository.refCount, 0);
      again.dispose();
      expect(HiveQuranRepository.refCount, 0);
    });
  });

  group('getBasmalahSync HiveBoxManager ref count', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      tempDir = Directory.systemTemp.createTempSync(
        'mushaf_reader_basmalah_ref_',
      );

      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      });

      await MushafReaderLibrary.ensureInitialized();
    });

    tearDownAll(() async {
      while (HiveBoxManager.refCount > 0) {
        HiveBoxManager.instance.dispose();
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));

      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getBasmalahSync after ensureInitialized does not bump box ref count', () {
      expect(HiveBoxManager.refCount, 1);

      final repo = HiveQuranRepository.instance;
      final before = HiveBoxManager.refCount;
      final basmalah = repo.getBasmalahSync();
      expect(HiveBoxManager.refCount, before);
      expect(basmalah, isNotEmpty);
    });

    test('page cache survives intermediate dispose while refs remain', () async {
      final first = HiveQuranRepository.acquire();
      await first.ensureReady();
      await first.getPage(1);
      expect(first.peekCachedPage(1), isNotNull);

      final second = HiveQuranRepository.acquire();
      expect(HiveQuranRepository.refCount, 2);

      first.dispose();
      expect(HiveQuranRepository.refCount, 1);
      expect(second.peekCachedPage(1), isNotNull);

      second.dispose();
      expect(HiveQuranRepository.refCount, 0);
    });
  });

  group('HiveBoxManager ref count', () {
    tearDown(() {
      while (HiveBoxManager.refCount > 0) {
        HiveBoxManager.instance.dispose();
      }
    });

    test('instance does not increment ref count', () {
      expect(HiveBoxManager.refCount, 0);
      final a = HiveBoxManager.instance;
      final b = HiveBoxManager();
      expect(identical(a, b), isTrue);
      expect(HiveBoxManager.refCount, 0);
    });

    test('acquire/release pairs return count to zero', () {
      final first = HiveBoxManager.acquire();
      expect(HiveBoxManager.refCount, 1);

      final second = HiveBoxManager.acquire();
      expect(identical(first, second), isTrue);
      expect(HiveBoxManager.refCount, 2);

      first.dispose();
      expect(HiveBoxManager.refCount, 1);

      second.dispose();
      expect(HiveBoxManager.refCount, 0);
    });

    test('dispose is no-op when ref count already zero', () {
      HiveBoxManager.instance.dispose();
      expect(HiveBoxManager.refCount, 0);
    });
  });
}
