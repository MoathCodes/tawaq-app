import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/ayah_selection_actions.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _EmptyQuranRepository implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async => throw UnimplementedError();

  @override
  Future<String> getBasmalah() async => '';

  @override
  String? getBasmalahSync() => null;

  @override
  Future<Juz> getJuz(int number) async => throw UnimplementedError();

  @override
  Future<List<Juz>> getJuzs() async => [];

  @override
  Map<int, Juz> getJuzsSync() => {};

  @override
  Future<int> getJuzStartPage(int juzNumber) async => 1;

  @override
  Juz? getJuzSync(int number) => null;

  @override
  ({int startAyahId, int endAyahId})? juzAyahBounds(int juzNumber) => null;

  @override
  Future<Hizb> getHizb(int number) async => throw UnimplementedError();

  @override
  Future<List<Hizb>> getHizbs() async => [];

  @override
  Map<int, Hizb> getHizbsSync() => {};

  @override
  Future<int> getHizbStartPage(int hizbNumber) async => 1;

  @override
  Hizb? getHizbSync(int number) => null;

  @override
  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) => null;

  @override
  Future<QuranPage> getPage(int page) async => QuranPage(
    pageNumber: page,
    glyphText: '',
    lines: const [],
    surahs: const [],
    juzNumber: 1,
  );

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurah(int surahNumber) async => null;

  @override
  List<Surah> getSurahsSync() => [];

  @override
  Surah? getSurahSync(int number) => null;

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async => [];

  @override
  Future<void> warmUpSearchIndex() async {}
}

void main() {
  testWidgets('selected ayah actions remain named and wrap at narrow width', (
    tester,
  ) async {
    final theme = buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );
    final controller = MushafReaderController.withRepository(
      repository: _EmptyQuranRepository(),
    );
    final ayah = Ayah(
      ayahId: 1,
      juz: 1,
      page: 1,
      surahNumber: 1,
      numberInSurah: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      textPlain: 'In the name of Allah',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranMushafControllerProvider.overrideWithValue(controller),
          quranSelectedAyahProvider.overrideWithValue(AsyncData(ayah)),
        ],
        child: FTheme(
          data: theme,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(
                width: 320,
                child: Center(child: AyahSelectionActionsBar()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Play',
      'Share',
      'Copy',
      'Dismiss ayah selection',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byType(Wrap), findsWidgets);

    controller.dispose();
  });
}
