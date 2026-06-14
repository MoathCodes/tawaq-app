import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() {
  final testSurah = Surah(
    number: 2,
    nameArabic: 'البقرة',
    nameEnglish: 'Al-Baqarah',
    glyph: 'S2',
    hasBasmalah: true,
  );

  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('SurahHeaderWidget banner selection', () {
    testWidgets('uses light package asset when isDark is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SurahHeaderWidget(
            surahData: testSurah,
            isDark: false,
            width: 200,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          ValueKey('surah-header-${MushafConstants.surahHeaderLightAsset}'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('uses dark package asset when isDark is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SurahHeaderWidget(
            surahData: testSurah,
            isDark: true,
            width: 200,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          ValueKey('surah-header-${MushafConstants.surahHeaderDarkAsset}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('auto-selects dark asset from Theme brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SurahHeaderWidget(
            surahData: testSurah,
            width: 200,
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          ValueKey('surah-header-${MushafConstants.surahHeaderDarkAsset}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('respects custom light and dark overrides', (tester) async {
      await tester.pumpWidget(
        wrap(
          SurahHeaderWidget(
            surahData: testSurah,
            isDark: true,
            width: 200,
            customHeaderImageLight: 'assets/custom_light.svg',
            customHeaderImageDark: 'assets/custom_dark.svg',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('surah-header-assets/custom_dark.svg')),
        findsOneWidget,
      );
    });
  });
}
