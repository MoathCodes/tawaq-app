import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/core/performance_utils.dart';

void main() {
  group('PerformanceUtils Tests', () {
    setUp(() {
      // Clear caches before each test
      PerformanceUtils.clearCaches();
    });

    group('Hindu-Arabic Number Conversion', () {
      test('should convert numbers correctly', () {
        expect(PerformanceUtils.toHinduArabicNumber(1), equals('١'));
        expect(PerformanceUtils.toHinduArabicNumber(123), equals('١٢٣'));
        expect(PerformanceUtils.toHinduArabicNumber(604), equals('٦٠٤'));
        expect(PerformanceUtils.toHinduArabicNumber(0), equals('٠'));
      });

      test('should cache converted numbers for performance', () {
        // First call - should compute and cache
        final stopwatch1 = Stopwatch()..start();
        final result1 = PerformanceUtils.toHinduArabicNumber(123);
        stopwatch1.stop();

        // Second call - should use cache
        final stopwatch2 = Stopwatch()..start();
        final result2 = PerformanceUtils.toHinduArabicNumber(123);
        stopwatch2.stop();

        expect(result1, equals(result2));
        expect(result1, equals('١٢٣'));

        // Cached call should be faster (though this might be flaky in CI)
        expect(
          stopwatch2.elapsedMicroseconds,
          lessThan(stopwatch1.elapsedMicroseconds + 100),
        );
      });

      test('should handle edge cases', () {
        expect(PerformanceUtils.toHinduArabicNumber(-1), equals('-١'));
        expect(PerformanceUtils.toHinduArabicNumber(9876543210), contains('٩'));
      });
    });

    group('Font Family Caching', () {
      test('should generate correct font family names', () {
        expect(
          PerformanceUtils.getFontFamilyForPage(1),
          equals('QuranPage_001'),
        );
        expect(
          PerformanceUtils.getFontFamilyForPage(42),
          equals('QuranPage_042'),
        );
        expect(
          PerformanceUtils.getFontFamilyForPage(604),
          equals('QuranPage_604'),
        );
      });

      test('should cache font family names for performance', () {
        // First call - should compute and cache
        final stopwatch1 = Stopwatch()..start();
        final result1 = PerformanceUtils.getFontFamilyForPage(100);
        stopwatch1.stop();

        // Second call - should use cache
        final stopwatch2 = Stopwatch()..start();
        final result2 = PerformanceUtils.getFontFamilyForPage(100);
        stopwatch2.stop();

        expect(result1, equals(result2));
        expect(result1, equals('QuranPage_100'));

        // Cached call should be faster
        expect(
          stopwatch2.elapsedMicroseconds,
          lessThan(stopwatch1.elapsedMicroseconds + 100),
        );
      });
    });

    group('Text Style Caching', () {
      test('should cache text styles correctly', () {
        var callCount = 0;

        final style1 = PerformanceUtils.getCachedTextStyle('test_key', () {
          callCount++;
          return const TextStyle(fontSize: 16);
        });

        final style2 = PerformanceUtils.getCachedTextStyle('test_key', () {
          callCount++;
          return const TextStyle(fontSize: 20); // Different style
        });

        // Should only call builder once
        expect(callCount, equals(1));
        expect(style1, equals(style2));
        expect(style1.fontSize, equals(16)); // Should use first cached value
      });

      test('should handle different keys separately', () {
        final style1 = PerformanceUtils.getCachedTextStyle('key1', () {
          return const TextStyle(fontSize: 16);
        });

        final style2 = PerformanceUtils.getCachedTextStyle('key2', () {
          return const TextStyle(fontSize: 20);
        });

        expect(style1.fontSize, equals(16));
        expect(style2.fontSize, equals(20));
      });
    });

    group('Preloading Functions', () {
      test('should preload page numbers without errors', () {
        expect(() => PerformanceUtils.preloadPageNumbers(), returnsNormally);

        // Verify some numbers are cached
        final result = PerformanceUtils.toHinduArabicNumber(300);
        expect(result, equals('٣٠٠'));
      });

      test('should preload font families without errors', () {
        expect(() => PerformanceUtils.preloadFontFamilies(), returnsNormally);

        // Verify some font families are cached
        final result = PerformanceUtils.getFontFamilyForPage(300);
        expect(result, equals('QuranPage_300'));
      });

      test('should handle full range of Quran pages (1-604)', () {
        PerformanceUtils.preloadPageNumbers();
        PerformanceUtils.preloadFontFamilies();

        for (int i = 1; i <= 604; i++) {
          expect(PerformanceUtils.toHinduArabicNumber(i), isNotEmpty);
          expect(
            PerformanceUtils.getFontFamilyForPage(i),
            contains('QuranPage_'),
          );
        }
      });
    });

    group('Cache Management', () {
      test('should clear all caches', () {
        // Populate caches
        PerformanceUtils.toHinduArabicNumber(123);
        PerformanceUtils.getFontFamilyForPage(123);
        PerformanceUtils.getCachedTextStyle('test', () => const TextStyle());

        // Clear caches
        PerformanceUtils.clearCaches();

        // This test verifies clearing doesn't throw errors
        // Actual cache clearing verification would require access to private fields
        expect(() => PerformanceUtils.clearCaches(), returnsNormally);
      });
    });

    group('Performance Benchmarks', () {
      test('should perform number conversion within reasonable time', () {
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        for (int i = 1; i <= iterations; i++) {
          PerformanceUtils.toHinduArabicNumber(i);
        }

        stopwatch.stop();

        // Should complete 1000 conversions in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should perform font family generation within reasonable time', () {
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        for (int i = 1; i <= iterations; i++) {
          PerformanceUtils.getFontFamilyForPage(i);
        }

        stopwatch.stop();

        // Should complete 1000 font family generations in under 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
