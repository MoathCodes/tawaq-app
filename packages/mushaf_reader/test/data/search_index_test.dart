import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/core/arabic_search_normalize.dart';
import 'package:mushaf_reader/src/core/search_index_entry.dart';

void main() {
  group('normalizeArabicForSearch', () {
    test('normalizes alef variations', () {
      expect(normalizeArabicForSearch('أإآٱ'), 'اااا');
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

    test('leaves already-normalized text unchanged', () {
      expect(normalizeArabicForSearch('الله'), 'الله');
    });
  });

  group('parseSearchIndexEntry', () {
    test('parses valid surahNumber|normalizedText', () {
      final entry = parseSearchIndexEntry('2|الله');
      expect(entry, isNotNull);
      expect(entry!.surahNumber, 2);
      expect(entry.normalizedText, 'الله');
    });

    test('returns null for empty or malformed values', () {
      expect(parseSearchIndexEntry(''), isNull);
      expect(parseSearchIndexEntry('|text'), isNull);
      expect(parseSearchIndexEntry('2|'), isNull);
      expect(parseSearchIndexEntry('abc|text'), isNull);
    });
  });

  group('encodeSearchIndexEntry', () {
    test('round-trips through parseSearchIndexEntry', () {
      final encoded = encodeSearchIndexEntry(
        surahNumber: 2,
        normalizedText: 'الله',
      );
      expect(encoded, '2|الله');
      expect(parseSearchIndexEntry(encoded)?.normalizedText, 'الله');
    });
  });
}
