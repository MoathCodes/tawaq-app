import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/juz_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';

void main() {
  group('arabicJuzOrdinal', () {
    test('covers 1–30', () {
      expect(arabicJuzOrdinal(1), 'الأول');
      expect(arabicJuzOrdinal(10), 'العاشر');
      expect(arabicJuzOrdinal(11), 'الحادي عشر');
      expect(arabicJuzOrdinal(20), 'العشرون');
      expect(arabicJuzOrdinal(21), 'الحادي والعشرون');
      expect(arabicJuzOrdinal(30), 'الثلاثون');
    });
  });

  group('arabicHizbOrdinal', () {
    test('covers 1–60', () {
      expect(arabicHizbOrdinal(1), 'الأول');
      expect(arabicHizbOrdinal(30), 'الثلاثون');
      expect(arabicHizbOrdinal(40), 'الأربعون');
      expect(arabicHizbOrdinal(51), 'الحادي والخمسون');
      expect(arabicHizbOrdinal(60), 'الستون');
    });
  });

  group('english labels', () {
    test('juz and hizb numeric labels', () {
      expect(englishJuzLabel(5), 'Juz 5');
      expect(englishHizbLabel(12), 'Hizb 12');
    });
  });

  group('localized wrappers', () {
    test('localizedJuzNumericLabel', () {
      expect(localizedJuzNumericLabel(2, isArabic: true), 'الجزء الثاني');
      expect(localizedJuzNumericLabel(2, isArabic: false), 'Juz 2');
    });

    test('localizedHizbTitle', () {
      expect(localizedHizbTitle(3, isArabic: true), 'الحزب الثالث');
      expect(localizedHizbTitle(3, isArabic: false), 'Hizb 3');
    });

    test('juzClosedLabel', () {
      expect(
        juzClosedLabel(number: 1, glyph: 'J1', isArabic: true),
        'J1',
      );
      expect(
        juzClosedLabel(number: 1, glyph: '', isArabic: true),
        'الأول',
      );
      expect(
        juzClosedLabel(number: 1, glyph: 'J1', isArabic: false),
        'Juz 1',
      );
    });
  });
}
