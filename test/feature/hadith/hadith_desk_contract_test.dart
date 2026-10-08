import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_highlight.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_desk_layout.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';

class _Repository extends Mock implements HadithRepository {}

class _Local extends Mock implements HadithLocalDatabase {}

const _record = DetailedHadith(
  hadith: 'Synthetic fixture narration',
  rawi: 'Fixture narrator',
  mohdith: 'Fixture scholar',
  book: 'Fixture source',
  numberOrPage: '1',
  grade: 'Fixture ruling',
  hadithId: 'fixture',
);

void main() {
  setUpAll(() {
    registerFallbackValue(CategoryBrowseParams(categoryId: CategoryId('1')));
    registerFallbackValue(const HadithSearchParams(value: 'fixture'));
  });
  test('layout uses feature width and changes earlier at large text', () {
    expect(HadithDeskLayout.resolve(1100, 1).areas, 3);
    expect(HadithDeskLayout.resolve(900, 1).areas, 2);
    expect(HadithDeskLayout.resolve(700, 1).areas, 1);
    expect(HadithDeskLayout.resolve(900, 1.4).areas, 1);
  });
  test(
    'legacy layout decodes and new fields take precedence without rekeying',
    () {
      final legacy = HadithPersistedSettings.fromJson({
        'activeTab': 'filters',
        'sidePanelRatio': .37,
        'sidePanelCollapsed': true,
      });
      expect(legacy.readerRatio, .37);
      expect(legacy.readerCollapsed, isTrue);
      expect(legacy.filtersVisible, isTrue);
      expect(legacy.filtersWidth, 280);
      final modern = HadithPersistedSettings.fromJson({
        ...legacy.toJson(),
        'readerRatio': .48,
        'readerCollapsed': false,
        'filtersVisible': false,
        'filtersWidth': 318.0,
      });
      expect(modern.readerRatio, .48);
      expect(modern.readerCollapsed, isFalse);
      expect(modern.filtersVisible, isFalse);
      expect(
        HadithPersistedSettings.fromJson(modern.toJson()).filtersWidth,
        318,
      );
      expect(modern.toJson()['activeTab'], 'filters');
    },
  );
  test('highlight maps folded Arabic, marks, repeated matches and surrogate pairs to exact source', () {
    const source = '😀 إِلى المَدْرَسة إِلى';
    final matches = hadithQueryRanges(source, 'الي');
    expect(matches.map((m) => source.substring(m.start, m.end)), [
      'إِلى',
      'إِلى',
    ]);
    expect(hadithQueryRanges(source, '😀').single, (start: 0, end: 2));
    expect(
      hadithQueryRanges(
        source,
        'مدرسه',
      ).map((m) => source.substring(m.start, m.end)),
      ['مَدْرَسة'],
    );
    expect(hadithQueryRanges(source, 'ـَ'), isEmpty);
  });
  test(
    'local Saved and recents never await failed remote initialization',
    () async {
      final local = _Local();
      when(local.getFavoriteEntries).thenAnswer((_) async => []);
      when(() => local.getRecentSearches()).thenAnswer((_) async => []);
      var attempts = 0;
      final container = ProviderContainer(
        overrides: [
          hadithLocalDatabaseProvider.overrideWithValue(local),
          dorarInitProvider.overrideWith((ref) async {
            attempts++;
            throw StateError('offline');
          }),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(hadithFavoritesProvider.future), isEmpty);
      expect(
        await container.read(hadithRecentSearchesStoreProvider.future),
        isEmpty,
      );
      expect(attempts, 0);
    },
  );
  test('category page eleven is allowed and reader trail Back preserves committed page', () async {
    final repository = _Repository();
    when(() => repository.browseCategory(any())).thenAnswer(
      (call) async => const ApiResponse(
        data: [_record],
        metadata: SearchMetadata(totalPages: 20),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hadithSessionControllerProvider, (_, _) {});
    final controller = container.read(hadithSessionControllerProvider.notifier);
    await controller.openCategory(
      ThematicCategory(
        id: '1',
        name: 'Fixture category',
        uri: Uri.parse('https://dorar.net/hadith-category/cat/1'),
      ),
    );
    await controller.goToPage(11);
    expect(controller.state.page, 11);
    await controller.selectHadith(_record);
    controller.setReaderPosition(section: 'usul', offset: 75);
    final page = controller.state.searchPage;
    controller.pushReader(_record.copyWith(hadithId: 'related'));
    controller.readerBack();
    expect(controller.state.searchPage, same(page));
    expect(controller.state.reader!.section, 'usul');
    expect(controller.state.reader!.offset, 75);
    verify(() => repository.browseCategory(any())).called(2);
  });
  test('advanced params and stale category completions stay scoped to their request', () async {
    final repository = _Repository();
    final pending = Completer<ApiResponse<List<DetailedHadith>>>();
    when(() => repository.browseCategory(any()))
        .thenAnswer((_) => pending.future);
    HadithSearchParams? received;
    when(() => repository.searchDetailed(any())).thenAnswer((call) async {
      received = call.positionalArguments.single as HadithSearchParams;
      return const ApiResponse(data: [_record], metadata: SearchMetadata());
    });
    when(() => repository.addRecentSearch(any())).thenAnswer((_) async {});
    when(() => repository.getRecentSearches()).thenAnswer((_) async => []);
    final container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hadithSessionControllerProvider, (_, _) {});
    final controller = container.read(hadithSessionControllerProvider.notifier);
    final category = controller.openCategory(
      ThematicCategory(
        id: '1',
        name: 'Fixture category',
        uri: Uri.parse('https://dorar.net/hadith-category/cat/1'),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await controller.setFilters(
      const HadithFilters(
        exclude: 'excluded',
        optionalPhrases: ['optional'],
        sort: HadithSort.degree,
      ),
    );
    await controller.setQuery('');
    pending.complete(const ApiResponse(data: [], metadata: SearchMetadata()));
    await category;
    expect(received!.optionalPhrases, ['optional']);
    expect(received!.exclude, 'excluded');
    expect(received!.sort, HadithSort.degree);
    expect(controller.state.searchPage, isA<HadithRecordPage>());
    expect(controller.state.results, [_record]);
  });
  test('leaving an initial request restores a retryable origin and rejects its late completion', () async {
    final repository = _Repository();
    final pending = Completer<ApiResponse<List<DetailedHadith>>>();
    when(() => repository.searchDetailed(any()))
        .thenAnswer((_) => pending.future);
    final container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hadithSessionControllerProvider, (_, _) {});
    final controller = container.read(hadithSessionControllerProvider.notifier);
    final request = controller.setQuery('fixture');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.searchBusy, isTrue);
    controller.openTopics();
    controller.returnToWorkspace();
    expect(controller.state.searchBusy, isFalse);
    expect(
      controller.state.searchOutcome.error,
      HadithRequestInterruption.collectionChanged,
    );
    pending.complete(
      const ApiResponse(data: [_record], metadata: SearchMetadata()),
    );
    await request;
    expect(controller.state.results, isEmpty);
    expect(controller.state.searchOutcome.hasError, isTrue);
  });
  test('leaving during filter debounce restores an explicit retry instead of false empty results', () async {
    final repository = _Repository();
    when(() => repository.searchDetailed(any())).thenAnswer(
      (_) async =>
          const ApiResponse(data: [_record], metadata: SearchMetadata()),
    );
    when(() => repository.addRecentSearch(any())).thenAnswer((_) async {});
    when(() => repository.getRecentSearches()).thenAnswer((_) async => []);
    final container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hadithSessionControllerProvider, (_, _) {});
    final controller = container.read(hadithSessionControllerProvider.notifier);
    await controller.setQuery('fixture');
    await controller.setFilters(const HadithFilters(specialist: true));
    controller.openTopics();
    controller.returnToWorkspace();
    expect(controller.state.searchBusy, isFalse);
    expect(
      controller.state.searchOutcome.error,
      HadithRequestInterruption.collectionChanged,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    verify(() => repository.searchDetailed(any())).called(1);
    await controller.search();
    expect(controller.state.results, [_record]);
  });
}
