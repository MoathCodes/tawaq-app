import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/logic/mushaf_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MushafController Optimization Tests', () {
    late MushafController controller;

    setUp(() {
      controller = MushafController.instance;
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(() => controller.init(), returnsNormally);
        await controller.init();

        // Should be able to call init multiple times without issues
        await controller.init();
        await controller.init();
      });

      test('should preload performance caches during init', () async {
        await controller.init();

        // After init, subsequent calls should be faster due to preloading
        // This is tested indirectly by ensuring no exceptions are thrown
        expect(() => controller.init(), returnsNormally);
      });
    });

    group('Page Loading Tests', () {
      test('should load pages successfully', () async {
        await controller.init();

        final page1 = await controller.getPage(1);
        expect(page1.pageNumber, equals(1));
        expect(page1.glyphText, isNotEmpty);

        final page604 = await controller.getPage(604);
        expect(page604.pageNumber, equals(604));
        expect(page604.glyphText, isNotEmpty);
      });

      test('should cache pages for performance', () async {
        await controller.init();

        // First load - should fetch from repository
        final stopwatch1 = Stopwatch()..start();
        final page1 = await controller.getPage(100);
        stopwatch1.stop();

        // Second load - should use cache
        final stopwatch2 = Stopwatch()..start();
        final page2 = await controller.getPage(100);
        stopwatch2.stop();

        expect(page1.pageNumber, equals(page2.pageNumber));
        expect(page1.glyphText, equals(page2.glyphText));

        // Cached call should be significantly faster
        expect(
          stopwatch2.elapsedMicroseconds,
          lessThan(stopwatch1.elapsedMicroseconds),
        );
      });
    });

    group('Batch Preloading Tests', () {
      test('should preload multiple pages successfully', () async {
        await controller.init();

        final pagesToPreload = [1, 2, 3, 4, 5];

        expect(() => controller.preloadPages(pagesToPreload), returnsNormally);
        await controller.preloadPages(pagesToPreload);

        // Verify pages are accessible after preloading
        for (final pageNum in pagesToPreload) {
          final page = await controller.getPage(pageNum);
          expect(page.pageNumber, equals(pageNum));
        }
      });

      test('should handle large batch preloading efficiently', () async {
        await controller.init();

        // Preload a larger batch
        final largeBatch = List.generate(50, (i) => i + 1);

        final stopwatch = Stopwatch()..start();
        await controller.preloadPages(largeBatch);
        stopwatch.stop();

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds

        // Verify some pages from the batch
        final samplePages = [1, 25, 50];
        for (final pageNum in samplePages) {
          final page = await controller.getPage(pageNum);
          expect(page.pageNumber, equals(pageNum));
        }
      });

      test('should handle empty preload list gracefully', () async {
        await controller.init();

        expect(() => controller.preloadPages([]), returnsNormally);
        await controller.preloadPages([]);
      });

      test('should handle invalid page numbers gracefully', () async {
        await controller.init();

        // Test with out-of-range pages
        final invalidPages = [0, -1, 605, 1000];

        // Should not throw exceptions, but may return empty or error results
        expect(() => controller.preloadPages(invalidPages), returnsNormally);

        try {
          await controller.preloadPages(invalidPages);
        } catch (e) {
          // Some invalid pages might throw exceptions, which is acceptable
          expect(e, isA<Exception>());
        }
      });
    });

    group('Cache Management Tests', () {
      test('should clear caches successfully', () async {
        await controller.init();

        // Load some pages to populate caches
        await controller.getPage(1);
        await controller.getPage(2);

        // Clear caches
        expect(() => controller.clearCaches(), returnsNormally);
        controller.clearCaches();
      });
    });

    group('Other API Tests', () {
      test('should load ayahs successfully', () async {
        await controller.init();

        final ayah = await controller.getAyah(1);
        expect(ayah.id, equals(1));
        expect(ayah.codeV4, isNotEmpty);

        final ayahByReference = await controller.getAyahBySurah(1, 1);
        expect(ayahByReference.surah, equals(1));
        expect(ayahByReference.numberInSurah, equals(1));
      });

      test('should load basmalah successfully', () async {
        await controller.init();

        final basmalah = await controller.getBasmalah();
        expect(basmalah, isNotEmpty);
      });

      test('should load juz information successfully', () async {
        await controller.init();

        final juz1 = await controller.getJuz(1);
        expect(juz1.number, equals(1));
        expect(juz1.codeV4, isNotEmpty);

        final allJuzs = await controller.getJuzs();
        expect(allJuzs.length, equals(30));
        expect(allJuzs.first.number, equals(1));
        expect(allJuzs.last.number, equals(30));
      });
    });

    group('Performance and Concurrency Tests', () {
      test('should handle concurrent page requests efficiently', () async {
        await controller.init();

        // Make multiple concurrent requests
        final futures = <Future>[];
        for (int i = 1; i <= 10; i++) {
          futures.add(controller.getPage(i));
        }

        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();

        expect(results.length, equals(10));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds

        // Verify all pages loaded correctly
        for (int i = 0; i < results.length; i++) {
          final page = results[i] as dynamic;
          expect(page.pageNumber, equals(i + 1));
        }
      });

      test('should maintain singleton behavior', () {
        final instance1 = MushafController.instance;
        final instance2 = MushafController.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Error Handling Tests', () {
      test('should handle repository errors gracefully', () async {
        await controller.init();

        // Test with invalid ayah ID
        try {
          await controller.getAyah(-1);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<ArgumentError>());
        }

        // Test with invalid surah/ayah combination
        try {
          await controller.getAyahBySurah(999, 999);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<ArgumentError>());
        }
      });
    });
  });
}
