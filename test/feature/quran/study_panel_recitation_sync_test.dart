// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestQuranScreenSettings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async => QuranScreenState.initial();
}

class _TestQuranSelectedAyahId extends QuranSelectedAyahId {
  new(this._ayahId);

  final int? _ayahId;

  @override
  int? build() => _ayahId;
}

class _TestQuranNotesStore extends QuranNotesStore {
  @override
  Future<QuranNotesState> build() async => QuranNotesState({});
}

class _StudyPanelTestRepo implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async =>
      _makeAyah(ayahId);

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async => _makeAyah(surah * 1000 + ayahInSurah);

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

Future<Ayah> _makeAyah(int ayahId) async => Ayah(
  ayahId: ayahId,
  juz: 1,
  page: 1,
  surahNumber: 1,
  numberInSurah: ayahId,
  text: '',
  textPlain: 'test $ayahId',
);

void main() {
  late MushafReaderController controller;
  late Ayah selected;

  setUp(() async {
    selected = await _makeAyah(1);
    controller = MushafReaderController.withRepository(
      repository: _StudyPanelTestRepo(),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget wrap({
    required RecitationState recitationState,
    required Widget child,
    bool hasSelection = true,
    Future<Ayah?> Function()? loadSelection,
  }) {
    final theme = buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    return ProviderScope(
      retry: (_, _) => null,
      overrides: [
        quranScreenSettingsProvider.overrideWith(_TestQuranScreenSettings.new),
        quranSelectedAyahIdProvider.overrideWith(
          () => _TestQuranSelectedAyahId(hasSelection ? selected.ayahId : null),
        ),
        if (loadSelection != null)
          quranSelectedAyahProvider.overrideWith((ref) => loadSelection()),
        quranMushafControllerProvider.overrideWithValue(controller),
        recitationControllerProvider.overrideWithValue(recitationState),
        quranNotesStoreProvider.overrideWith(_TestQuranNotesStore.new),
        quranAllNotesProvider.overrideWith((ref) async => const []),
        ayahTranslationRowProvider(
          kDefaultTranslationId,
          1,
          1,
        ).overrideWithValue(const AsyncData<Translation?>(null)),
        ayahTranslationRowProvider(
          kDefaultTranslationId,
          1,
          7,
        ).overrideWithValue(const AsyncData<Translation?>(null)),
        tafsirForAyahProvider(
          TafsirId.tafseerMouaser,
          1,
          1,
        ).overrideWithValue(const AsyncData<TafsirParseResult?>(null)),
        tafsirForAyahProvider(
          TafsirId.tafseerMouaser,
          1,
          7,
        ).overrideWithValue(const AsyncData<TafsirParseResult?>(null)),
        appThemeDataProvider.overrideWithValue(theme),
      ],
      child: FTheme(
        data: theme,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox(width: 600, height: 800, child: child)),
        ),
      ),
    );
  }

  testWidgets('empty Study explains selection without disabled editors', (
    tester,
  ) async {
    var returned = false;
    await tester.pumpWidget(
      wrap(
        recitationState: const RecitationState(),
        hasSelection: false,
        child: StudyPanel(onBackToReading: () => returned = true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Select an ayah in the Mushaf'), findsOneWidget);
    expect(find.byType(FAccordion), findsNothing);
    expect(find.byType(FTextField), findsNothing);
    await tester.tap(find.text('Back to reading'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected ayah loading is distinct from empty selection', (
    tester,
  ) async {
    final pending = Completer<Ayah?>();
    await tester.pumpWidget(
      wrap(
        recitationState: const RecitationState(),
        loadSelection: () => pending.future,
        child: const StudyPanel(),
      ),
    );
    await tester.pump();
    expect(find.byType(FCircularProgress), findsOneWidget);
    expect(find.textContaining('Select an ayah in the Mushaf'), findsNothing);
    pending.complete(selected);
    await tester.pumpAndSettle();
    expect(find.byType(FAccordion), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Study retries selected ayah errors without losing selection', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      wrap(
        recitationState: const RecitationState(),
        loadSelection: () async {
          if (++attempts == 1) throw StateError('fixture failure');
          return selected;
        },
        child: const StudyPanel(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load the selected ayah'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(FAccordion), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StudyPanel)),
    );
    expect(container.read(quranSelectedAyahIdProvider), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'StudyPanel keeps session selection when recitation has surah-local ayah',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          recitationState: const RecitationState(
            active: true,
            surah: 112,
            currentAyah: 7,
          ),
          child: const StudyPanel(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final element = tester.element(find.byType(StudyPanel));
      final container = ProviderScope.containerOf(element);
      expect(container.read(quranSelectedAyahIdProvider), 1);
    },
  );

  testWidgets('StudyPanel does not sync selection from inactive recitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        recitationState: const RecitationState(currentAyah: 7),
        child: const StudyPanel(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final element = tester.element(find.byType(StudyPanel));
    final container = ProviderScope.containerOf(element);
    expect(container.read(quranSelectedAyahIdProvider), 1);
  });

  testWidgets('StudyPanel does not sync when recitation has no currentAyah', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        recitationState: const RecitationState(active: true),
        child: const StudyPanel(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final element = tester.element(find.byType(StudyPanel));
    final container = ProviderScope.containerOf(element);
    expect(container.read(quranSelectedAyahIdProvider), 1);
  });
}
