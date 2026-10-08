import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_interaction.dart';
// Fixture overrides belong to an independent root scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/screens/hadith_screen.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_reader_scroll.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_loading_cards.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_results_column.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_topics.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

const _record = DetailedHadith(
  hadith: 'Synthetic desk narration',
  rawi: 'Fixture narrator',
  mohdith: 'Fixture scholar',
  book: 'Fixture book',
  numberOrPage: '1',
  grade: 'Fixture ruling',
);

class _Session extends HadithSessionController {
  @override
  HadithSessionState build() => const HadithSessionState(
    query: 'fixture',
    searchOutcome: AsyncData(HadithSearchPage(results: [_record])),
  );
}

class _LandingSession extends HadithSessionController {
  @override
  HadithSessionState build() => const HadithSessionState(
    searchOutcome: AsyncData(HadithSearchPage.empty),
  );
}

class _EmptyRecents extends HadithRecentSearchesStore {
  @override
  Future<List<String>> build() async => [];
}

class _EditingSession extends _Session {
  @override
  Future<void> setFilters(
    HadithFilters filters, {
    bool debounced = true,
  }) async {
    state = state.copyWith(filters: filters);
  }
}

class _CheckedSession extends HadithSessionController {
  @override
  HadithSessionState build() => HadithSessionState(
    query: 'fixture',
    searchOutcome: AsyncData(
      HadithSearchPage(
        results: [
          _record.copyWith(
            hadithId: 'fixture',
            asbabAvailability: Availability.advertised,
            usulAvailability: Availability.advertised,
          ),
        ],
      ),
    ),
  );
}

class _Settings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async =>
      const HadithPersistedSettings();
}

Widget _theme(Widget child, {Locale locale = const Locale('en')}) => FTheme(
  data: buildAppTheme(
    palette: AppPalette.manuscript,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  ),
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);
void main() {
  testWidgets('desktop subtopics use adjacent readable columns', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 4; i++)
        ThematicCategory(
          id: '$i',
          name: 'Fixture subtopic $i',
          uri: Uri.https('dorar.net', '/hadith-category/cat/$i'),
        ),
    ];
    final container = ProviderContainer(
      overrides: [
        hadithSessionControllerProvider.overrideWith(_Session.new),
        hadithTopicSearchProvider.overrideWith(
          (ref, query) async =>
              ApiResponse(data: items, metadata: const SearchMetadata()),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _theme(
          const Center(child: SizedBox(width: 880, child: HadithTopics())),
        ),
      ),
    );
    await tester.enterText(find.byType(FTextField), 'fixture');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text(items[0].name)).dy,
      tester.getTopLeft(find.text(items[1].name)).dy,
    );
    expect(
      tester.getTopLeft(find.text(items[2].name)).dy,
      greaterThan(tester.getTopLeft(find.text(items[0].name)).dy),
    );
    await tester.binding.setSurfaceSize(const Size(500, 718));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text(items[1].name)).dy,
      greaterThan(tester.getTopLeft(find.text(items[0].name)).dy),
    );
    expect(tester.takeException(), isNull);
  });
  for (final language in ['ar', 'en']) {
    testWidgets('desktop content stays readable without panels in $language', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
          hadithFavoritesProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await container.read(hadithScreenSettingsProvider.future);
      container
          .read(hadithScreenSettingsProvider.notifier)
          .setFiltersVisible(false);
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _theme(const HadithPage(), locale: Locale(language)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(HadithResultCard)).width,
        lessThanOrEqualTo(880),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('hadith-ruling-unmarked')))
            .width,
        lessThan(400),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'landing filters reserve desktop space and compact sheet is opaque in $language',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            hadithSessionControllerProvider.overrideWith(_LandingSession.new),
            hadithScreenSettingsProvider.overrideWith(_Settings.new),
            hadithTopicRootsProvider.overrideWith(
              (ref) async => const ApiResponse(
                data: <ThematicRoot>[],
                metadata: SearchMetadata(),
              ),
            ),
            hadithRecentSearchesStoreProvider.overrideWith(_EmptyRecents.new),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(1440, 900));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _theme(const HadithPage(), locale: Locale(language)),
          ),
        );
        await tester.pumpAndSettle();
        final panel = find.byType(HadithFilterPanel);
        expect(
          find.byKey(const ValueKey('hadith-filter-column')),
          findsOneWidget,
        );
        final heading = find.text(
          lookupAppLocalizations(Locale(language)).hadithStudyDesk,
        );
        expect(
          tester.getRect(panel).overlaps(tester.getRect(heading)),
          isFalse,
        );
        await tester.binding.setSurfaceSize(const Size(664, 718));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(FLucideIcons.slidersHorizontal));
        await tester.pumpAndSettle();
        final surface = tester.widget<ColoredBox>(
          find.byKey(const ValueKey('hadith-filter-sheet-surface')),
        );
        expect(surface.color.a, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('editing survives requests, scroll and panel remount', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hadithSessionControllerProvider.overrideWith(_EditingSession.new),
        hadithScreenSettingsProvider.overrideWith(_Settings.new),
        hadithFavoritesProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _theme(const HadithPage()),
      ),
    );
    await tester.pumpAndSettle();
    final ui = container.read(hadithFilterInteractionProvider);
    for (var i = 0; i < 4; i++) {
      ui.expand(i, true);
    }
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('hadith-exclude'));
    await tester.ensureVisible(field);
    final editor = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    // Keep this test local; the request lifecycle is exercised by controller tests.
    final controller = container.read(hadithSessionControllerProvider.notifier);
    expect(tester.widget<EditableText>(editor).controller, same(ui.exclude));
    await tester.enterText(editor, 'fixture exclusion');
    expect(ui.exclude.text, 'fixture exclusion');
    expect(controller.state.filters.exclude, 'fixture exclusion');
    await tester.pump();
    ui.exclude.selection = const TextSelection.collapsed(offset: 7);
    final editing = tester.element(editor);
    final card = tester.element(find.byType(HadithResultCard));
    final committed = controller.state.searchPage;
    final offset = ui.scroll.offset;
    controller.state = controller.state.copyWith(
      searchOutcome: const AsyncLoading(),
      committedPage: committed,
    );
    await tester.pump();
    expect(tester.element(editor), same(editing));
    expect(tester.element(find.byType(HadithResultCard)), same(card));
    expect(find.byType(HadithLoadingCards), findsNothing);
    controller.state = controller.state.copyWith(
      searchOutcome: AsyncError(StateError('fixture'), StackTrace.empty),
    );
    await tester.pumpAndSettle();
    expect(tester.element(editor), same(editing));
    expect(tester.element(find.byType(HadithResultCard)), same(card));
    expect(ui.exclude.selection.baseOffset, 7);
    controller.setResultsOffset(10);
    ui.scroll.jumpTo(0);
    ui.scroll.jumpTo(offset);
    await tester.pump();
    expect(ui.expanded, {0, 1, 2, 3});
    await tester.tap(find.byIcon(FLucideIcons.slidersHorizontal));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(FLucideIcons.slidersHorizontal));
    await tester.pumpAndSettle();
    expect(container.read(hadithFilterInteractionProvider), same(ui));
    expect(ui.scroll.offset, offset);
    expect(ui.exclude.text, 'fixture exclusion');
    expect(ui.exclude.selection.baseOffset, 7);
    expect(ui.expanded, {0, 1, 2, 3});
    final add = find.text(
      lookupAppLocalizations(const Locale('en')).hadithAddPhrase,
    );
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
    }
    expect(add, findsNothing);
    final third = ui.phrases[2];
    final first = ui.phrases.first;
    final thirdRow = find.byKey(ObjectKey(third));
    await tester.ensureVisible(thirdRow);
    await tester.enterText(
      find.descendant(of: thirdRow, matching: find.byType(EditableText)),
      'third phrase',
    );
    await tester.pump();
    third.selection = const TextSelection.collapsed(offset: 3);
    final secondRow = find.byKey(ObjectKey(ui.phrases[1]));
    await tester.ensureVisible(secondRow);
    await tester.tap(
      find.descendant(of: secondRow, matching: find.byIcon(FLucideIcons.x)),
    );
    await tester.pumpAndSettle();
    expect(ui.phrases, hasLength(3));
    expect(ui.phrases.first, same(first));
    expect(ui.phrases[1], same(third));
    expect(third.text, 'third phrase');
    expect(third.selection.baseOffset, 3);
    expect(add, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unsupported collections have no filter controls or reserved pane',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
          hadithFavoritesProvider.overrideWith((ref) async => []),
          hadithTopicRootsProvider.overrideWith(
            (ref) async => const ApiResponse(
              data: <ThematicRoot>[],
              metadata: SearchMetadata(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _theme(const HadithPage()),
        ),
      );
      await tester.pumpAndSettle();
      final controller = container.read(
        hadithSessionControllerProvider.notifier,
      );
      for (final state in [
        const HadithSessionState(context: TopicsCollection()),
        const HadithSessionState(target: HadithSearchTarget.prose),
        HadithSessionState(
          context: CategoryCollection(
            ThematicCategory(
              id: 'fixture',
              name: 'Fixture category',
              uri: Uri.https('dorar.net', '/hadith-category/cat/fixture'),
            ),
          ),
        ),
      ]) {
        controller.state = state;
        await tester.pumpAndSettle();
        expect(find.byType(HadithFilterPanel), findsNothing);
        expect(
          find.byKey(const ValueKey('hadith-filter-column')),
          findsNothing,
        );
        expect(find.byIcon(FLucideIcons.slidersHorizontal), findsNothing);
        if (state.context is! SearchCollection) {
          expect(find.byKey(const ValueKey('hadith-query')), findsNothing);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown capability is not probed and reader starts at feature top',
    (tester) async {
      var probes = 0;
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
          hadithFavoritesProvider.overrideWith((ref) async => []),
          hadithAsbabProvider.overrideWith((ref, id) async {
            probes++;
            throw StateError('must not probe');
          }),
          hadithUsulProvider.overrideWith((ref, id) async {
            probes++;
            throw StateError('must not probe');
          }),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _theme(const HadithPage()),
        ),
      );
      await tester.pumpAndSettle();
      await container
          .read(hadithSessionControllerProvider.notifier)
          .selectHadith(_record.copyWith(hadithId: 'fixture'));
      await tester.pumpAndSettle();
      expect(probes, 0);
      expect(find.text('Check Dorar'), findsNothing);
      final details = find.byType(HadithSelectedDetailsPane);
      // The pane's padded body starts directly inside its full-height surface.
      final surface = find
          .ancestor(of: details, matching: find.byType(ColoredBox))
          .first;
      expect(
        tester.getTopLeft(surface).dy,
        tester.getTopLeft(find.byType(HadithPage)).dy,
      );
      expect(
        tester.getTopLeft(find.byType(HadithResultsColumn)).dy,
        greaterThan(tester.getTopLeft(details).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'resize preserves selection and compact Back restores result focus',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
          hadithFavoritesProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _theme(const HadithPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hadith-filter-column')),
        findsOneWidget,
      );
      await tester.tap(find.text(_record.hadith));
      await tester.pumpAndSettle();
      expect(find.byType(HadithSelectedDetailsPane), findsOneWidget);
      expect(find.byType(FResizable), findsNWidgets(2));
      final filters = find.byKey(const ValueKey('hadith-filter-column'));
      await tester.tap(
        find.descendant(of: filters, matching: find.byIcon(FLucideIcons.x)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HadithSelectedDetailsPane), findsOneWidget);
      expect(find.byKey(const ValueKey('hadith-filter-column')), findsNothing);
      await tester.tap(find.byIcon(FLucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();
      final page = container.read(hadithSessionControllerProvider).searchPage;
      await tester.binding.setSurfaceSize(const Size(664, 718));
      await tester.pumpAndSettle();
      expect(find.byType(HadithResultCard), findsOneWidget);
      expect(find.byType(FSheets), findsOneWidget);
      expect(find.byType(HadithSelectedDetailsPane), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(HadithResultCard), findsOneWidget);
      expect(
        container.read(hadithSessionControllerProvider).searchPage,
        same(page),
      );
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(900, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(FLucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
      expect(find.byIcon(FLucideIcons.x).hitTestable(), findsOneWidget);
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpAndSettle();
      expect(find.byIcon(FLucideIcons.x).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hadith-filter-column')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
  testWidgets(
    'advertised section loads directly and recognized empty shows once across resize',
    (tester) async {
      final record = _record.copyWith(
        hadithId: 'fixture',
        asbabAvailability: Availability.advertised,
        usulAvailability: Availability.advertised,
      );
      var asbabRequests = 0;
      var usulRequests = 0;
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_CheckedSession.new),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
          hadithFavoritesProvider.overrideWith((ref) async => []),
          hadithAsbabProvider(HadithRecordId('fixture'))
              .overrideWith((ref) async {
                asbabRequests++;
                return ApiResponse(
                  data: AsbabResult(
                    requestedId: 'fixture',
                    source: record,
                    narrations: const [],
                  ),
                  metadata: const SearchMetadata(),
                );
              }),
          hadithUsulProvider(HadithRecordId('fixture'))
              .overrideWith((ref) async {
                usulRequests++;
                return const ApiResponse(
                  data: UsulHadith(hadith: _record, sources: [], count: 0),
                  metadata: SearchMetadata(),
                );
              }),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _theme(const HadithPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(record.hadith));
      await tester.pumpAndSettle();
      expect(find.text('No data available'), findsOneWidget);
      expect(find.text('Source of this group'), findsNothing);
      expect(asbabRequests, 1);
      expect(usulRequests, 0);
      await tester.tap(
        find.descendant(
          of: find.byType(HadithSelectedDetailsPane),
          matching: find.text(
            lookupAppLocalizations(const Locale('en')).hadithUsulHadith,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(usulRequests, 1);
      expect(find.text('Check Dorar'), findsNothing);
      await tester.binding.setSurfaceSize(const Size(664, 718));
      await tester.pumpAndSettle();
      expect(find.text('Check Dorar'), findsNothing);
      expect(find.text('No data available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
  for (final language in ['en', 'ar']) {
    testWidgets('both panes resize and close independently in $language', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
          hadithFavoritesProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _theme(const HadithPage(), locale: Locale(language)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_record.hadith));
      await tester.pumpAndSettle();
      final filters = find.byKey(const ValueKey('hadith-filter-column'));
      final reader = find.byType(HadithSelectedDetailsPane);
      final rtl = language == 'ar';
      final filterRect = tester.getRect(filters);
      await tester.dragFrom(
        Offset(rtl ? filterRect.left : filterRect.right, 500),
        Offset(rtl ? -40 : 40, 0),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(hadithScreenSettingsProvider).value!.filtersWidth,
        greaterThan(300),
      );
      final before = container
          .read(hadithScreenSettingsProvider)
          .value!
          .readerRatio;
      final readerRect = tester.getRect(reader);
      await tester.dragFrom(
        Offset(rtl ? readerRect.right + 20 : readerRect.left - 20, 500),
        Offset(rtl ? 40 : -40, 0),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(hadithScreenSettingsProvider).value!.readerRatio,
        greaterThan(before),
      );
      await tester.tap(
        find.descendant(of: reader, matching: find.byIcon(FLucideIcons.x)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HadithSelectedDetailsPane), findsNothing);
      expect(filters, findsOneWidget);
      await tester.tap(
        find.descendant(of: filters, matching: find.byIcon(FLucideIcons.x)),
      );
      await tester.pumpAndSettle();
      expect(filters, findsNothing);
      expect(find.byType(HadithResultCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  }
  testWidgets('reading offset waits for asynchronous content extent', (
    tester,
  ) async {
    final offsets = <double>[];
    Future<void> render(bool ready) => tester.pumpWidget(
      _theme(
        SizedBox(
          height: 250,
          child: HadithReaderScroll(
            ready: ready,
            initialOffset: 800,
            onOffsetChanged: offsets.add,
            child: SizedBox(
              height: ready ? 1500 : 50,
              child: const Text('Synthetic source content'),
            ),
          ),
        ),
      ),
    );
    await render(false);
    await tester.pumpAndSettle();
    final initial = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(initial.offset, 0);
    expect(offsets, isEmpty);
    await render(true);
    await tester.pumpAndSettle();
    expect(initial.offset, 800);
    expect(offsets, isEmpty);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(offsets.last, greaterThan(800));
  });
}
