import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  QuranPage _testPage() {
    const glyphText = 'Page 1 content';
    return QuranPage(
      pageNumber: 1,
      juzNumber: 1,
      glyphText: glyphText,
      lines: const [],
      surahs: [
        SurahBlock(
          surahNumber: 1,
          glyph: 'S1',
          start: 0,
          end: glyphText.length,
          hasBasmalah: true,
          ayahs: [
            AyahFragment(ayahId: 1, start: 0, end: 5),
            AyahFragment(ayahId: 2, start: 6, end: glyphText.length),
          ],
        ),
      ],
    );
  }

  group('MushafPageRange', () {
    testWidgets('renders single-page range from preloaded page data', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPageRange.onPage(
              page: 1,
              startAyahId: 1,
              endAyahId: 1,
              pageData: _testPage(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MushafPageRange), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('hides surah header when showSurahHeader is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPageRange.onPage(
              page: 1,
              startAyahId: 1,
              endAyahId: 1,
              pageData: _testPage(),
              showSurahHeader: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SurahHeaderWidget), findsNothing);
    });
  });
}
