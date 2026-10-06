import 'package:tawaq/feature/quran/presentation/widgets/study/study_content_section.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_search.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/tafsir_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_header_widget.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_search_field.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study_mode_layout.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Repository extends Mock implements IQuranRepository {}

class _Notes extends QuranNotesStore {
  @override
  Future<QuranNotesState> build() async => QuranNotesState({});
}

class _Settings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async =>
      QuranScreenState.initial().copyWith(sidePanelCollapsed: false);
}

void main() {
  late _Repository repository;
  late MushafReaderController controller;
  final surah = Surah(
    number: 2,
    glyph: '',
    hasBasmalah: true,
    nameEnglish: 'Al-Baqarah',
    nameArabic: 'سُورَةُ الْبَقَرَةِ',
    ayahCount: 286,
    startPage: 2,
  );
  final ayah = Ayah(
    ayahId: 262,
    juz: 3,
    page: 42,
    surahNumber: 2,
    numberInSurah: 255,
    text: 'glyph',
    uthmaniText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
    textPlain: 'الله لا إله إلا هو',
  );
  setUp(() async {
    repository = _Repository();
    when(repository.ensureReady).thenAnswer((_) async {});
    when(repository.getBasmalah).thenAnswer((_) async => '');
    when(repository.getJuzs).thenAnswer(
      (_) async => List.generate(
        30,
        (i) => Juz(number: i + 1, glyph: '', startAyahId: 262),
      ),
    );
    when(() => repository.getJuz(any())).thenAnswer(
      (call) async => Juz(
        number: call.positionalArguments.single as int,
        glyph: '',
        startAyahId: 262,
      ),
    );
    when(repository.getHizbs).thenAnswer(
      (_) async =>
          List.generate(60, (i) => Hizb(number: i + 1, startAyahId: 262)),
    );
    when(() => repository.getHizb(any())).thenAnswer(
      (call) async => Hizb(
        number: call.positionalArguments.single as int,
        startAyahId: 262,
      ),
    );
    when(() => repository.getAyah(262, any())).thenAnswer((_) async => ayah);
    when(repository.getAllSurahs).thenAnswer(
      (_) async => [
        surah,
        Surah(number: 20, glyph: '', hasBasmalah: true, nameEnglish: 'Taa-Haa'),
      ],
    );
    when(() => repository.getAyahBySurah(2, 255)).thenAnswer((_) async => ayah);
    when(() => repository.searchAyahs(any(), maxResults: 20))
        .thenAnswer((_) async => [ayah]);
    when(() => repository.getPageForAyah(262)).thenAnswer((_) async => 42);
    when(() => repository.getPage(any())).thenAnswer(
      (call) async => QuranPage(
        pageNumber: call.positionalArguments.single as int,
        glyphText: '',
        lines: [],
        surahs: [
          SurahBlock(
            surahNumber: 2,
            glyph: '',
            start: 0,
            end: 1,
            hasBasmalah: false,
            ayahs: [AyahFragment(ayahId: 262, start: 0, end: 1)],
          ),
        ],
        juzNumber: 1,
      ),
    );
    controller = MushafReaderController.withRepository(repository: repository);
    await controller.ensureReady();
    addTearDown(controller.dispose);
  });
  test('a number preserves the distinction between navigation types', () async {
    final found = await QuranSearch(controller).search('٢');
    expect(found.map((r) => r.kind), [
      QuranSearchKind.surah,
      QuranSearchKind.juz,
      QuranSearchKind.hizb,
    ]);
  });
  test(
    'English and Arabic explicit divisions are bounded and distinct',
    () async {
      final search = QuranSearch(controller);
      for (final term in ['juz 3', 'جزء ٣', 'الجزء 3']) {
        final result = await search.search(term);
        expect(result.single.kind, QuranSearchKind.juz);
        expect(result.single.number, 3);
      }
      expect((await search.search('حزب ٧')).single.kind, QuranSearchKind.hizb);
      for (final term in ['juz 31', 'hizb 61', 'juz 0', '2:287', '115:1']) {
        expect(await search.search(term), isEmpty, reason: term);
      }
      verifyNever(() => repository.getAyahBySurah(2, 287));
      verifyNever(() => repository.searchAyahs('juz 31', maxResults: 20));
    },
  );
  test('numeric and named references resolve the actual source ayah', () async {
    for (final query in ['2:255', '٢:٢٥٥', 'Al-Baqarah 255', 'البقرة ٢٥٥']) {
      final found = await QuranSearch(controller).search(query);
      expect(found.single.ayah, ayah, reason: query);
    }
  });
  test(
    'common Latin name spelling and punctuation resolve sourced names',
    () async {
      for (final name in ['Al Baqara', 'baqarah', 'albaqara']) {
        expect(
          (await QuranSearch(controller).search('surah $name')).single.surah,
          surah,
        );
      }
    },
  );
  test(
    'a word beginning with a division name still searches Quran text',
    () async {
      expect((await QuranSearch(controller).search('حزبهم')).single.ayah, ayah);
      verify(() => repository.searchAyahs('حزبهم', maxResults: 20)).called(1);
    },
  );
  test('name and source-text search keep source content unchanged', () async {
    expect(
      (await QuranSearch(controller).search('سورة البقرة')).single.surah,
      surah,
    );
    final found = await QuranSearch(controller).search('الله');
    expect(found.single.ayah!.uthmaniText, ayah.uthmaniText);
    verify(() => repository.searchAyahs('الله', maxResults: 20)).called(1);
  });

  test('division results carry their sourced opening ayah', () async {
    for (final query in ['juz 21', 'hizb 21']) {
      final result = (await QuranSearch(controller).search(query)).single;
      expect(result.ayah, same(ayah));
      expect(result.surah, same(surah));
      expect(result.number, 21);
    }
  });

  Future<ProviderContainer> mount(WidgetTester tester, Widget child) async {
    final container = ProviderContainer(
      overrides: [
        quranMushafControllerProvider.overrideWithValue(controller),
        quranScreenSettingsProvider.overrideWith(_Settings.new),
        quranNotesStoreProvider.overrideWith(_Notes.new),
        tafsirForAyahProvider(
          kDefaultTafsirId,
          2,
          255,
        ).overrideWith((_) async => null),
        ayahTranslationRowProvider(
          kDefaultTranslationId,
          2,
          255,
        ).overrideWith((_) async => null),
      ],
    );
    addTearDown(container.dispose);
    await container.read(quranScreenSettingsProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: FTheme(
          data: buildAppTheme(
            palette: AppPalette.manuscript,
            themeMode: ThemeMode.light,
            touch: false,
            textScale: 1,
          ),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'loaded commentary is immediate with reduced motion',
    (tester) async {
      await mount(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: _ReducedCommentary(),
        ),
      );
      expect(find.text('Loaded commentary'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'Forui popup groups destinations and selecting an ayah navigates',
    (tester) async {
      final container = await mount(
        tester,
        const Padding(padding: EdgeInsets.all(20), child: QuranSearchField()),
      );
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Surahs'), findsOneWidget);
      expect(find.text('286 verses • Page 2'), findsOneWidget);
      expect(find.text('Juz'), findsOneWidget);
      expect(find.text('Hizb'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '2:255');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text(ayah.uthmaniText!), findsOneWidget);
      await tester.tap(find.text(ayah.uthmaniText!));
      await tester.pumpAndSettle();
      expect(controller.currentPage, 42);
      expect(container.read(quranSelectedAyahIdProvider), 262);
      expect(find.text(ayah.uthmaniText!), findsNothing);
    },
    semanticsEnabled: false,
  );
  testWidgets(
    'late search responses cannot replace a newer query',
    (tester) async {
      final old = Completer<List<Ayah>>();
      when(() => repository.searchAyahs('old', maxResults: 20))
          .thenAnswer((_) => old.future);
      when(() => repository.searchAyahs('new', maxResults: 20))
          .thenAnswer((_) async => []);
      await mount(tester, const QuranSearchField());
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'old');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'new');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('No results found'), findsOneWidget);
      old.complete([ayah]);
      await tester.pumpAndSettle();
      expect(find.text(ayah.uthmaniText!), findsNothing);
      expect(find.text('No results found'), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'search failure is recoverable in the same popover',
    (tester) async {
      var attempts = 0;
      when(() => repository.searchAyahs('الله', maxResults: 20))
          .thenAnswer((_) async {
            if (attempts++ == 0) throw StateError('fixture index failure');
            return [ayah];
          });
      await mount(tester, const QuranSearchField());
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'الله');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Search could not load. Try again.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text(ayah.uthmaniText!), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'keyboard can move through results and Escape dismisses',
    (tester) async {
      await mount(tester, const QuranSearchField());
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final selected = tester
          .widgetList<FItem>(find.byType(FItem))
          .where((item) => item.selected)
          .single;
      expect(
        find.descendant(
          of: find.byWidget(selected),
          matching: find.text('Juz 2'),
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FItem), findsNothing);
      await tester.enterText(find.byType(TextField), '3');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Juz 3'), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'mouse and keyboard share one active result',
    (tester) async {
      await mount(tester, const QuranSearchField());
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(0, 0));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Hizb 2')));
      await tester.pumpAndSettle();
      FItem activeItem() => tester
          .widgetList<FItem>(find.byType(FItem))
          .where((w) => w.selected)
          .single;
      expect(
        find.descendant(
          of: find.byWidget(activeItem()),
          matching: find.text('Hizb 2'),
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byWidget(activeItem()),
          matching: find.text('Juz 2'),
        ),
        findsOneWidget,
      );
      final context = tester.element(find.byWidget(activeItem()));
      for (final item in tester.widgetList<FItem>(find.byType(FItem))) {
        final style = item.style(context.theme.itemStyles.primary);
        final hovered = style.contentDecoration.resolve({
          FTappableVariant.hovered,
        }) as ShapeDecoration;
        expect(
          hovered.color,
          item.selected ? context.theme.colors.secondary : Colors.transparent,
        );
      }
      expect(find.byIcon(FLucideIcons.arrowUpRight), findsNothing);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'compact Study opens with a hint and the same button closes it',
    (tester) async {
      var opened = false;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => QuranHeaderWidget(
            studyInPopover: true,
            studyOpen: opened,
            onStudy: () => setState(() => opened = !opened),
            onStudyDismiss: () => setState(() => opened = false),
          ),
        ),
      );
      await tester.tap(find.byIcon(FLucideIcons.bookOpen));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Select an ayah in the Mushaf to open its tafsir, translation, and your reflection.',
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(5, 500));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      await tester.tap(find.byIcon(FLucideIcons.bookOpen));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Select an ayah in the Mushaf to open its tafsir, translation, and your reflection.',
        ),
        findsNothing,
      );
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'nested source menus keep the Study companion open',
    (tester) async {
      var opened = false;
      final container = await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FPopover(
            hideRegion: FPopoverHideRegion.none,
            control: FPopoverControl.lifted(
              shown: opened,
              onChange: (value) => setState(() => opened = value),
            ),
            popoverBuilder: (context, _) => const SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Study companion'),
                  TafsirSourceSelector(),
                  TranslationSourceSelector(showLabel: false),
                ],
              ),
            ),
            child: FButton(
              onPress: () => setState(() => opened = true),
              child: const Text('Study trigger'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Study trigger'));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is FSelect<TafsirId>));
      await tester.pumpAndSettle();
      final tafsir = TafsirId.values.firstWhere(
        (id) =>
            id !=
            container.read(quranScreenSettingsProvider).value!.selectedTafsir,
      );
      await tester.tap(find.text(tafsir.displayLabel(isArabic: false)));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(
        container.read(quranScreenSettingsProvider).value!.selectedTafsir,
        tafsir,
      );
      expect(find.text('Study companion'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate((w) => w is FSelect<TranslationId>),
      );
      await tester.pumpAndSettle();
      final translation = TranslationId.values.firstWhere(
        (id) =>
            id !=
            container
                .read(quranScreenSettingsProvider)
                .value!
                .selectedTranslation,
      );
      await tester.ensureVisible(find.text(translation.displayName));
      await tester.pumpAndSettle();
      await tester.tap(find.text(translation.displayName));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(
        container.read(quranScreenSettingsProvider).value!.selectedTranslation,
        translation,
      );
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'mode tabs update inside the open popover',
    (tester) async {
      final container = await mount(tester, const QuranHeaderWidget());
      final buttons = tester.widgetList<FButton>(find.byType(FButton)).toList();
      buttons.last.onPress!();
      await tester.pumpAndSettle();
      final before = tester.widget<FTabs>(find.byType(FTabs));
      expect(before.control, isA<FTabControl>());
      // Drive the rendered tab, keeping the popover open throughout.
      await tester.tap(find.text('Double Page'));
      await tester.pumpAndSettle();
      expect(
        container.read(quranScreenSettingsProvider).value!.layout,
        QuranReadingLayout.doublePage,
      );
      final tabs = tester.widget<FTabs>(find.byType(FTabs));
      expect(
        tabs.control
            .toDiagnosticsNode()
            .getProperties()
            .singleWhere((p) => p.name == 'index')
            .value,
        0,
      );
      expect(find.byType(FTabs), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'opening Study ignores a stale page load',
    (tester) async {
      final pending = Completer<QuranPage>();
      when(() => repository.getPage(42)).thenAnswer((_) => pending.future);
      final container = await mount(
        tester,
        Consumer(
          builder: (context, ref, _) => FButton(
            onPress: () => revealQuranStudy(ref),
            child: const Text('Open Study'),
          ),
        ),
      );
      controller.jumpToPage(42);
      await tester.tap(find.text('Open Study'));
      controller.jumpToPage(43);
      pending.complete(
        QuranPage(
          pageNumber: 42,
          glyphText: '',
          lines: [],
          juzNumber: 1,
          surahs: [
            SurahBlock(
              surahNumber: 2,
              glyph: '',
              start: 0,
              end: 1,
              hasBasmalah: false,
              ayahs: [AyahFragment(ayahId: 262, start: 0, end: 1)],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(quranSelectedAyahIdProvider), isNull);
      expect(controller.currentPage, 43);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'opening Study preserves a newer user selection',
    (tester) async {
      final pending = Completer<Ayah>();
      when(() => repository.getAyah(262, any()))
          .thenAnswer((_) => pending.future);
      final container = await mount(
        tester,
        Consumer(
          builder: (context, ref, _) => FButton(
            onPress: () => revealQuranStudy(ref),
            child: const Text('Open Study'),
          ),
        ),
      );
      await tester.tap(find.text('Open Study'));
      await tester.pump();
      container.read(quranSelectedAyahIdProvider.notifier).select(6236);
      pending.complete(ayah);
      await tester.pumpAndSettle();
      expect(container.read(quranSelectedAyahIdProvider), 6236);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'Study follows selection and its edge control selects the page start',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1500, 900);
      addTearDown(tester.view.resetPhysicalSize);
      final container = await mount(
        tester,
        const StudyModeLayout(mushaf: Text('Reader')),
      );
      controller.jumpToPage(43);
      CollapsibleHorizontalSplitPane split() =>
          tester.widget(find.byType(CollapsibleHorizontalSplitPane));
      expect(split().collapsed, isTrue);
      expect(
        find.text(
          'Select an ayah in the Mushaf to open its tafsir, translation, and your reflection.',
        ),
        findsNothing,
      );
      split().onCollapsedChanged(false);
      await tester.pumpAndSettle();
      expect(container.read(quranSelectedAyahIdProvider), 262);
      expect(controller.selectedAyahId, 262);
      expect(controller.currentPage, 43);
      expect(split().collapsed, isFalse);
      container.read(quranSelectedAyahIdProvider.notifier).select(null);
      await tester.pumpAndSettle();
      expect(split().collapsed, isTrue);
      container.read(quranSelectedAyahIdProvider.notifier).select(262);
      await tester.pumpAndSettle();
      expect(split().collapsed, isFalse);
      split().onCollapsedChanged(true);
      await tester.pumpAndSettle();
      expect(split().collapsed, isTrue);
      expect(container.read(quranSelectedAyahIdProvider), 262);
    },
    semanticsEnabled: false,
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}

class _ReducedCommentary extends StatelessWidget {
  const _ReducedCommentary();
  @override
  Widget build(BuildContext context) => StudyContentSection<String>(
    asyncValue: const AsyncData('Loaded commentary'),
    contentKey: 'commentary',
    errorMessage: 'Error',
    emptyMessage: 'Empty',
    sourceSelector: const Text('Source'),
    contentBuilder: (data) => Text(data),
  );
}
