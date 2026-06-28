import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_mushaf_pane.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestQuranScreenSettings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async {
    return QuranScreenState.initial().copyWith(
      layout: QuranReadingLayout.doublePage,
    );
  }
}

class _MushafViewportTestRepo implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) =>
      throw UnimplementedError();

  @override
  Future<String> getBasmalah() async => '';

  @override
  String? getBasmalahSync() => '';

  @override
  Future<Juz> getJuz(int number) => throw UnimplementedError();

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
  Future<Hizb> getHizb(int number) => throw UnimplementedError();

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
  Future<QuranPage> getPage(int page) async {
    return QuranPage(
      pageNumber: page,
      glyphText: '',
      lines: const [],
      surahs: const [],
      juzNumber: 1,
    );
  }

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
  }) async =>
      [];

  @override
  Future<void> warmUpSearchIndex() async {}
}

void main() {
  late MushafReaderController controller;

  setUp(() {
    controller = MushafReaderController.withRepository(
      repository: _MushafViewportTestRepo(),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget wrap({
    required double width,
    required Widget child,
  }) {
    final theme = buildAppTheme(
      palette: AppPalette.zinc,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    return ProviderScope(
      overrides: [
        mushafLibraryInitProvider.overrideWith((ref) async {}),
        quranScreenSettingsProvider.overrideWith(_TestQuranScreenSettings.new),
        quranMushafControllerProvider.overrideWithValue(controller),
        appThemeDataProvider.overrideWithValue(theme),
      ],
      child: FTheme(
        data: theme,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 700,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('QuranMushafPane double-page guard', () {
    testWidgets(
      'falls back to single page below 2× mushaf minimum width',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            width: 700,
            child: const QuranMushafPane(),
          ),
        );
        await tester.pump();

        final reader = tester.widget<MushafReader>(find.byType(MushafReader));
        expect(reader.pagesPerViewport, 1);
        expect(
          find.text(AppLocalizationsEn().quranDoublePageWidthFallback),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'keeps two-page spread when container is wide enough',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            width: 800,
            child: const QuranMushafPane(),
          ),
        );
        await tester.pump();

        final reader = tester.widget<MushafReader>(find.byType(MushafReader));
        expect(reader.pagesPerViewport, 2);
        expect(find.byType(FAlert), findsNothing);
      },
    );
  });
}
