import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_result_item.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_selector.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Repository extends Mock implements IQuranRepository {}

void main() {
  testWidgets('selecting a search result navigates and closes the popup', (
    tester,
  ) async {
    final repository = _Repository();
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
    final surah = Surah(
      number: 1,
      glyph: '',
      hasBasmalah: true,
      nameEnglish: 'Al-Fatiha',
    );
    when(repository.ensureReady).thenAnswer((_) async {});
    when(repository.getBasmalah).thenAnswer((_) async => '');
    when(repository.getJuzs).thenAnswer((_) async => []);
    when(repository.getHizbs).thenAnswer((_) async => []);
    when(repository.getAllSurahs).thenAnswer((_) async => [surah]);
    when(repository.warmUpSearchIndex).thenAnswer((_) async {});
    when(() => repository.searchAyahs(any(), maxResults: 20)).thenAnswer(
      (call) async => (call.positionalArguments.single as String).trim().isEmpty
          ? []
          : [ayah],
    );
    when(() => repository.getPageForAyah(1)).thenAnswer((_) async => 1);
    when(() => repository.getPage(any())).thenAnswer(
      (call) async => QuranPage(
        pageNumber: call.positionalArguments.single as int,
        glyphText: '',
        lines: const [],
        surahs: const [],
        juzNumber: 1,
      ),
    );
    final controller = MushafReaderController.withRepository(
      repository: repository,
    );
    await controller.ensureReady();
    final focus = FocusNode();
    final container = ProviderContainer(
      overrides: [
        quranMushafControllerProvider.overrideWithValue(controller),
      ],
    );
    addTearDown(() {
      focus.dispose();
      controller.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: FTheme(
          data: buildAppTheme(
            palette: AppPalette.neutral,
            themeMode: ThemeMode.light,
            touch: false,
            textScale: 1,
          ),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: AyahSearchSelector(focusNode: focus),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'بسم');
    await tester.pumpAndSettle();
    expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
    await tester.tap(find.text('بِسْمِ اللَّهِ'));
    await tester.pumpAndSettle();
    expect(container.read(quranSelectedAyahIdProvider), 1);
    expect(controller.selectedAyahId, 1);
    expect(focus.hasFocus, isFalse);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('بِسْمِ اللَّهِ'), findsNothing);
    expect(find.byType(EmptyStatePanel), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: const TargetPlatformVariant({TargetPlatform.linux}));

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
