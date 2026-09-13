import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
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

class _TestQuranSelectedAyahId extends QuranSelectedAyahId {
  _TestQuranSelectedAyahId(this._ayahId);

  final int? _ayahId;

  @override
  int? build() => _ayahId;
}

void main() {
  final theme = buildAppTheme(
    palette: AppPalette.neutral,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
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

  Future<MushafReaderController> pumpReaderComposition(
    WidgetTester tester, {
    required double width,
    _TestQuranSelectedAyahId? selectedState,
  }) async {
    final controller = MushafReaderController.withRepository(
      repository: _EmptyQuranRepository(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranMushafControllerProvider.overrideWithValue(controller),
          quranSelectedAyahProvider.overrideWithValue(AsyncData(ayah)),
          quranSelectedAyahIdProvider.overrideWith(
            () => selectedState ?? _TestQuranSelectedAyahId(ayah.ayahId),
          ),
        ],
        child: FTheme(
          data: theme,
          child: FToaster(
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SizedBox(
                  width: width,
                  height: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
                        child: ColoredBox(
                          color: Color(0xfff4f0e8),
                          child: Center(child: Text('page metadata')),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: AyahSelectionActionsBar(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  void performSemanticTap(WidgetTester tester, String label) {
    final node = tester.getSemantics(find.bySemanticsLabel(label));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
  }

  testWidgets('reader composition keeps actions named and wraps when narrow', (
    tester,
  ) async {
    final controller = await pumpReaderComposition(tester, width: 320);
    for (final label in [
      'Play',
      'Share',
      'Copy',
      'Dismiss ayah selection',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byType(Wrap), findsWidgets);
    expect(
      tester.getTopLeft(find.text('page metadata')).dy,
      lessThan(tester.getTopLeft(find.bySemanticsLabel('Copy')).dy),
    );
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('ayah-selection-actions-surface')),
    );
    expect(surfaceRect.width, lessThanOrEqualTo(320));
    expect(surfaceRect.height, lessThan(220));
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('wide reader composition keeps labels and play chevron visible', (
    tester,
  ) async {
    final controller = await pumpReaderComposition(tester, width: 760);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.byIcon(FLucideIcons.chevronDown), findsOneWidget);
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('ayah-selection-actions-surface')),
    );
    final playRect = tester.getRect(find.bySemanticsLabel('Play'));
    final shareRect = tester.getRect(find.bySemanticsLabel('Share'));
    final copyRect = tester.getRect(find.bySemanticsLabel('Copy'));
    expect(playRect.top, closeTo(shareRect.top, 1));
    expect(shareRect.top, closeTo(copyRect.top, 1));
    expect(surfaceRect.width, lessThanOrEqualTo(520));
    expect(surfaceRect.height, lessThan(150));
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('labeled actions activate through semantic tap', (tester) async {
    final selectedState = _TestQuranSelectedAyahId(ayah.ayahId);

    var controller = await pumpReaderComposition(
      tester,
      width: 760,
      selectedState: selectedState,
    );
    performSemanticTap(tester, 'Play');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Play this ayah'), findsOneWidget);
    controller.dispose();

    controller = await pumpReaderComposition(
      tester,
      width: 760,
      selectedState: selectedState,
    );
    performSemanticTap(tester, 'Copy');
    // FToaster intentionally keeps its dismissal timer alive; a bounded
    // pump is enough to flush the clipboard callback without waiting for the
    // toast lifecycle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Copied'), findsOneWidget);
    controller.dispose();

    controller = await pumpReaderComposition(
      tester,
      width: 760,
      selectedState: selectedState,
    );
    performSemanticTap(tester, 'Dismiss ayah selection');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(selectedState.state, isNull);
    controller.dispose();
  });

  testWidgets('Play is reachable with Tab and activates with Enter', (
    tester,
  ) async {
    final selectedState = _TestQuranSelectedAyahId(ayah.ayahId);
    final controller = await pumpReaderComposition(
      tester,
      width: 760,
      selectedState: selectedState,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Play this ayah'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('Copy is reachable with Tab and activates with Space', (
    tester,
  ) async {
    final selectedState = _TestQuranSelectedAyahId(ayah.ayahId);
    final controller = await pumpReaderComposition(
      tester,
      width: 760,
      selectedState: selectedState,
    );
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Copied'), findsOneWidget);
    controller.dispose();
  });
}
