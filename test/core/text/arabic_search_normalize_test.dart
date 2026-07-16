import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';

void main() {
  group('normalizeArabicForSearch', () {
    test('normalizes alef variations including wasla', () {
      expect(normalizeArabicForSearch('أإآٱ'), 'اااا');
      expect(normalizeArabicForSearch('ٱل'), 'ال');
    });

    test('normalizes teh marbuta to heh', () {
      expect(normalizeArabicForSearch('رحمة'), 'رحمه');
    });

    test('normalizes alef maksura to yeh', () {
      expect(normalizeArabicForSearch('موسى'), 'موسي');
    });

    test('removes tatweel', () {
      expect(normalizeArabicForSearch('الـله'), 'الله');
    });

    test('removes diacritics and folds ta marbuta', () {
      expect(normalizeArabicForSearch('سُورَةُ ٱلْبَقَرَةِ'), 'سوره البقره');
    });

    test('typed ال matches surah name with alef wasla', () {
      const surahName = 'سورة ٱلبقرة';
      expect(arabicSearchContains(surahName, 'ال'), isTrue);
      expect(arabicSearchStartsWith(surahName, 'سور'), isTrue);
    });
  });
}
