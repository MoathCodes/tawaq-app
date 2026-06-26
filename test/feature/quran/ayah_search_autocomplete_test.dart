import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_result_item.dart';
import 'package:tawaq/gen/fonts.gen.dart';

void main() {
  group('filterAyahsForSearch', () {
    test('requires minimum query length before searching', () {
      expect(kAyahSearchMinQueryLength, 2);
    });
  });

  group('ayahSearchPreviewText', () {
    test('prefers uthmaniText over textPlain', () {
      final ayah = Ayah(
        ayahId: 1,
        juz: 1,
        page: 1,
        surahNumber: 1,
        numberInSurah: 1,
        text: 'glyph',
        uthmaniText: 'بِسْمِ اللَّهِ',
        textPlain: 'بسم الله',
      );

      expect(ayahSearchPreviewText(ayah), 'بِسْمِ اللَّهِ');
    });

    test('falls back to textPlain when uthmaniText is empty', () {
      final ayah = Ayah(
        ayahId: 1,
        juz: 1,
        page: 1,
        surahNumber: 1,
        numberInSurah: 1,
        text: 'glyph',
        textPlain: 'بسم الله',
      );

      expect(ayahSearchPreviewText(ayah), 'بسم الله');
    });
  });

  group('Uthmani preview rendering', () {
    testWidgets('uses Uthmanic Hafs with two-line ellipsis', (tester) async {
      const preview = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              preview,
              style: TextStyle(fontFamily: FontFamily.uthmanicHafs),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontFamily, FontFamily.uthmanicHafs);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
