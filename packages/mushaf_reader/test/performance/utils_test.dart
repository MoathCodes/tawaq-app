import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/core/extensions.dart';
import 'package:mushaf_reader/src/core/fonts.dart';

void main() {
  group('Extensions and MushafFonts Tests', () {
    group('Hindu-Arabic Number Conversion', () {
      test('should convert numbers correctly', () {
        expect(1.toHinduArabic(), equals('١'));
        expect(123.toHinduArabic(), equals('١٢٣'));
        expect(604.toHinduArabic(), equals('٦٠٤'));
        expect(0.toHinduArabic(), equals('٠'));
      });

      test('should handle edge cases', () {
        expect((-1).toHinduArabic(), equals('-١'));
        expect(9876543210.toHinduArabic(), contains('٩'));
      });
    });

    group('MushafFonts', () {
      test('should generate correct font family names', () {
        expect(MushafFonts.forPage(1), equals('QCF4_001'));
        expect(MushafFonts.forPage(42), equals('QCF4_042'));
        expect(MushafFonts.forPage(100), equals('QCF4_100'));
        expect(MushafFonts.forPage(604), equals('QCF4_604'));
      });

      test('should generate font families quickly', () {
        final stopwatch = Stopwatch()..start();
        for (int i = 1; i <= 604; i++) {
          MushafFonts.forPage(i);
        }
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('should have correct basmalah family', () {
        expect(MushafFonts.basmalahFamily, equals('QCF4_BSML'));
      });
    });

    group('Full Range of Quran Pages', () {
      test('should handle all 604 pages', () {
        for (int i = 1; i <= 604; i++) {
          expect(i.toHinduArabic(), isNotEmpty);
          expect(MushafFonts.forPage(i), contains('QCF4_'));
        }
      });
    });

    group('Performance Benchmarks', () {
      test('should perform number conversion within reasonable time', () {
        final stopwatch = Stopwatch()..start();
        for (int i = 1; i <= 1000; i++) {
          i.toHinduArabic();
        }
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
