import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';

class MockHadithRepository extends Mock implements HadithRepository {}

class _TestHadithScreenSettings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async =>
      const HadithPersistedSettings();
}

DetailedHadith _hadith(String text) => DetailedHadith(
  hadith: text,
  rawi: 'rawi',
  mohdith: 'mohdith',
  book: 'book',
  numberOrPage: '1',
  grade: 'sahih',
);

ApiResponse<List<DetailedHadith>> _response(String text) => ApiResponse(
  data: [_hadith(text)],
  metadata: const SearchMetadata(length: 1),
);

void main() {
  late MockHadithRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const HadithSearchParams(value: 'fallback'));
    registerFallbackValue(const SharhTextSearchParams(value: 'fallback'));
    registerFallbackValue(_hadith('fallback'));
  });

  setUp(() {
    repository = MockHadithRepository();
    when(() => repository.addRecentSearch(any())).thenAnswer((_) async {});
    when(() => repository.getRecentSearches()).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((ref) async => repository),
        hadithScreenSettingsProvider.overrideWith(
          _TestHadithScreenSettings.new,
        ),
      ],
    )..listen(hadithSessionControllerProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('HadithSessionController search', () {
    test(
      'refinement keeps committed cards and reader through failure',
      () async {
        final pending = Completer<ApiResponse<List<DetailedHadith>>>();
        when(() => repository.searchDetailed(any()))
            .thenAnswer((_) => pending.future);
        final controller = container.read(
          hadithSessionControllerProvider.notifier,
        );
        final original = _hadith('committed');
        controller.state = controller.state.copyWith(
          query: 'query',
          searchOutcome: AsyncData(HadithSearchPage(results: [original])),
          resultsOffset: 123,
        );
        await controller.selectHadith(original);
        final request = controller.setFilters(
          const HadithFilters(exclude: 'exclude'),
          debounced: false,
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.results, [original]);
        expect(container.read(selectedHadithProvider), original);
        expect(controller.state.resultsOffset, 123);
        pending.completeError(StateError('offline'));
        await request;
        expect(controller.state.searchOutcome.hasError, isTrue);
        expect(controller.state.results, [original]);
        expect(container.read(selectedHadithProvider), original);
      },
    );

    test(
      'study desk navigation keeps drafts and rejects a late request',
      () async {
        final pending = Completer<ApiResponse<List<DetailedHadith>>>();
        when(() => repository.searchDetailed(any()))
            .thenAnswer((_) => pending.future);
        final controller = container.read(
          hadithSessionControllerProvider.notifier,
        );
        const drafts = HadithFilters(
          exclude: 'exclude',
          optionalPhrases: ['phrase'],
        );
        controller.state = controller.state.copyWith(filters: drafts);
        final request = controller.setQuery('query');
        await Future<void>.delayed(Duration.zero);
        controller.openSearchHome();
        expect((controller.state.context as SearchCollection).home, isTrue);
        expect(controller.state.query, isEmpty);
        expect(controller.state.filters, drafts);
        expect(controller.state.searchBusy, isFalse);
        pending.complete(_response('late result'));
        await request;
        expect(controller.state.results, isEmpty);
        expect((controller.state.context as SearchCollection).home, isTrue);
      },
    );

    test('unselected navigation starts at the first or last result', () async {
      final session = container.read(hadithSessionControllerProvider.notifier);
      final results = [_hadith('first'), _hadith('middle'), _hadith('last')];
      session.state = session.state.copyWith(
        searchOutcome: AsyncData(HadithSearchPage(results: results)),
      );
      session.clearSelection();
      await session.selectAdjacentResult(1);
      expect(session.state.selectedHadithKey, hadithStableKey(results.first));
      session.clearSelection();
      await session.selectAdjacentResult(-1);
      expect(session.state.selectedHadithKey, hadithStableKey(results.last));
    });

    test('immediate submit consumes the pending filter debounce', () async {
      when(() => repository.searchDetailed(any()))
          .thenAnswer((_) async => _response('hit'));
      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'query');
      await session.setFilters(const HadithFilters(specialist: true));
      await session.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      verify(() => repository.searchDetailed(any())).called(1);
    });

    test(
      'disposal during repository hydration makes no search request',
      () async {
        final gate = Completer<HadithRepository>();
        final isolated = ProviderContainer(
          overrides: [
            hadithRepositoryProvider.overrideWith((ref) => gate.future),
          ],
        );
        isolated.listen(hadithSessionControllerProvider, (_, _) {});
        final session = isolated.read(hadithSessionControllerProvider.notifier);
        final pending = session.setQuery('query');
        isolated.dispose();
        gate.complete(repository);
        await pending;
        verifyNever(() => repository.searchDetailed(any()));
      },
    );

    test('ignores stale search when a newer search completes first', () async {
      final first = Completer<ApiResponse<List<DetailedHadith>>>();
      final second = Completer<ApiResponse<List<DetailedHadith>>>();

      when(() => repository.searchDetailed(any())).thenAnswer((invocation) {
        final params = invocation.positionalArguments[0]! as HadithSearchParams;
        return switch (params.value) {
          'first' => first.future,
          'second' => second.future,
          _ => Future.value(_response('unexpected')),
        };
      });

      final session = container.read(hadithSessionControllerProvider.notifier);

      session.state = session.state.copyWith(query: 'first');
      final firstSearch = session.search();

      session.state = session.state.copyWith(query: 'second');
      final secondSearch = session.search();

      second.complete(_response('second-result'));
      await secondSearch;

      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'second-result',
      );

      first.complete(_response('stale-result'));
      await firstSearch;
      await pumpEventQueue();

      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'second-result',
      );
    });

    test('ignores stale goToPage after a new search starts', () async {
      final initial = Completer<ApiResponse<List<DetailedHadith>>>();
      final pageTwo = Completer<ApiResponse<List<DetailedHadith>>>();
      final refreshed = Completer<ApiResponse<List<DetailedHadith>>>();

      when(() => repository.searchDetailed(any())).thenAnswer((invocation) {
        final params = invocation.positionalArguments[0]! as HadithSearchParams;
        if (params.page == 2) return pageTwo.future;
        return switch (params.value) {
          'initial' => initial.future,
          'refreshed' => refreshed.future,
          _ => Future.value(_response('unexpected')),
        };
      });

      final session = container.read(hadithSessionControllerProvider.notifier);

      session.state = session.state.copyWith(query: 'initial');
      final initialSearch = session.search();

      initial.complete(
        ApiResponse(
          data: [_hadith('page-one')],
          metadata: const SearchMetadata(
            length: 1,
            totalPages: 3,
            hasNextPage: true,
          ),
        ),
      );
      await initialSearch;

      final pageChange = session.goToPage(2);
      session.state = session.state.copyWith(query: 'refreshed');
      final refreshSearch = session.search();

      refreshed.complete(_response('refreshed-result'));
      await refreshSearch;

      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'refreshed-result',
      );

      pageTwo.complete(
        ApiResponse(
          data: [_hadith('stale-page-two')],
          metadata: const SearchMetadata(length: 1, totalPages: 3),
        ),
      );
      await pageChange;
      await pumpEventQueue();

      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'refreshed-result',
      );
      expect(
        container.read(hadithSessionControllerProvider).searchBusy,
        isFalse,
      );
    });

    test('goToPage replaces results instead of appending', () async {
      when(() => repository.searchDetailed(any())).thenAnswer((invocation) {
        final params = invocation.positionalArguments[0]! as HadithSearchParams;
        return Future.value(
          ApiResponse(
            data: [_hadith('page-${params.page}')],
            metadata: SearchMetadata(
              length: 1,
              page: params.page,
              totalPages: 3,
              hasNextPage: params.page < 3,
            ),
          ),
        );
      });

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'query');
      await session.search();

      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'page-1',
      );
      expect(container.read(hadithSessionControllerProvider).page, 1);

      await session.goToPage(2);

      final state = container.read(hadithSessionControllerProvider);
      expect(state.page, 2);
      expect(state.results, hasLength(1));
      expect(state.results.single.hadith, 'page-2');
    });

    test('search refinement retains the selected record when it leaves the new page', () async {
      when(() => repository.searchDetailed(any())).thenAnswer((invocation) {
        final params = invocation.positionalArguments[0]! as HadithSearchParams;
        return Future.value(
          _response(params.value == 'first' ? 'selected' : 'new'),
        );
      });

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'first');
      await session.search();
      final selected = container
          .read(hadithSessionControllerProvider)
          .results
          .single;
      await session.selectHadith(selected);
      expect(
        container.read(hadithSessionControllerProvider).selectedHadithKey,
        hadithStableKey(selected),
      );

      session.state = session.state.copyWith(query: 'second');
      await session.search();

      expect(
        container.read(hadithSessionControllerProvider).selectedHadithKey,
        hadithStableKey(selected),
      );
    });

    test('goToPage keeps current page when response is empty', () async {
      when(() => repository.searchDetailed(any())).thenAnswer((invocation) {
        final params = invocation.positionalArguments[0]! as HadithSearchParams;
        if (params.page == 2) {
          return Future.value(
            const ApiResponse(
              data: <DetailedHadith>[],
              metadata: SearchMetadata(page: 2, totalPages: 10),
            ),
          );
        }
        return Future.value(
          ApiResponse(
            data: [_hadith('page-1')],
            metadata: const SearchMetadata(
              length: 1,
              page: 1,
              totalPages: 10,
              hasNextPage: true,
            ),
          ),
        );
      });

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'query');
      await session.search();
      await session.goToPage(2);

      final state = container.read(hadithSessionControllerProvider);
      expect(state.page, 1);
      expect(state.results.single.hadith, 'page-1');
      expect(state.searchPage!.reachablePages, 10);
      expect(state.emptyNextPage, 2);
      expect(state.metadata!.hasNextPage, isTrue);
      expect(state.searchBusy, isFalse);
    });

    test('new-query failure is hard error without stale list', () async {
      var call = 0;
      when(() => repository.searchDetailed(any())).thenAnswer((_) async {
        call++;
        if (call == 1) return _response('ok');
        throw Exception('network down');
      });

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'first');
      await session.search();
      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'ok',
      );

      session.state = session.state.copyWith(query: 'second');
      await session.search();

      final state = container.read(hadithSessionControllerProvider);
      expect(state.searchOutcome.hasError, isTrue);
      expect(state.searchOutcome.hasValue, isFalse);
      expect(state.results, isEmpty);
      expect(state.hardSearchError, contains('network down'));
    });

    test('pagination failure keeps prior AsyncData page', () async {
      when(() => repository.searchDetailed(any())).thenAnswer((invocation) {
        final params = invocation.positionalArguments[0]! as HadithSearchParams;
        if (params.page == 2) {
          return Future.error(Exception('page failed'));
        }
        return Future.value(
          ApiResponse(
            data: [_hadith('page-1')],
            metadata: const SearchMetadata(
              length: 1,
              page: 1,
              totalPages: 3,
              hasNextPage: true,
            ),
          ),
        );
      });

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'query');
      await session.search();
      await session.goToPage(2);

      final state = container.read(hadithSessionControllerProvider);
      expect(state.searchOutcome, isA<AsyncData<HadithSearchPage>>());
      expect(state.searchOutcome.hasError, isFalse);
      expect(state.results.single.hadith, 'page-1');
      expect(state.hardSearchError, isNull);
      expect('${state.paginationError}', contains('page failed'));
      expect(state.isPaginating, isFalse);
      expect(state.searchBusy, isFalse);
    });

    test(
      'target switch rejects stale records and keeps record filters for return',
      () async {
        final pending = Completer<ApiResponse<List<DetailedHadith>>>();
        when(() => repository.searchDetailed(any()))
            .thenAnswer((_) => pending.future);
        when(() => repository.searchProse(any())).thenAnswer(
          (_) async => const ApiResponse(
            data: <SharhSnippet>[],
            metadata: SearchMetadata(),
          ),
        );
        final session = container.read(
          hadithSessionControllerProvider.notifier,
        );
        session.state = session.state.copyWith(
          query: 'query',
          filters: const HadithFilters(specialist: true),
        );
        final recordSearch = session.search();
        await Future<void>.delayed(Duration.zero);
        await session.setTarget(HadithSearchTarget.prose);
        pending.complete(_response('stale record'));
        await recordSearch;
        expect(session.state.results, isEmpty);
        expect(session.state.searchPage!.target, HadithSearchTarget.prose);
        expect(session.state.filters.specialist, isTrue);
        expect(session.state.page, 1);
        session.pushReader(_hadith('related'));
        session.readerBack();
        expect(session.state.target, HadithSearchTarget.prose);
        expect(session.state.filters.specialist, isTrue);
      },
    );

    test(
      'prose empty page stops probing without changing SDK metadata',
      () async {
        final snippet = SharhSnippet(
          id: '1',
          uri: Uri.parse('https://dorar.net/sharh/1'),
          document: _document(),
        );
        const metadata = SearchMetadata(
          pagination: PageMetadata(
            page: 1,
            pageSize: 30,
            hasNextPage: true,
            nextPageEvidence: NextPageEvidence.pageSizeHint,
          ),
        );
        var probes = 0;
        when(() => repository.searchProse(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.single as SharhTextSearchParams;
          if (params.page == 2) {
            probes++;
            return const ApiResponse(
              data: <SharhSnippet>[],
              metadata: SearchMetadata(),
            );
          }
          return ApiResponse(data: [snippet], metadata: metadata);
        });
        final session = container.read(
          hadithSessionControllerProvider.notifier,
        );
        session.state = session.state.copyWith(
          query: 'query',
          target: HadithSearchTarget.prose,
        );
        await session.search();
        await session.selectAdjacentResult(1);
        expect(session.state.selectedSharhId, '1');
        expect(session.state.selectedHadithKey, isNull);
        await session.goToPage(2);
        expect(session.state.searchPage!.snippets, [snippet]);
        expect(session.state.metadata, same(metadata));
        expect(session.state.searchPage!.reachablePages, isNull);
        expect(session.state.canGoNext, isFalse);
        await session.goToPage(2);
        expect(probes, 1);
        await session.search();
        expect(session.state.canGoNext, isTrue);
        await session.goToPage(2);
        expect(probes, 2);
      },
    );

    test('detailed capabilities cap displayed totals at page ten', () async {
      when(() => repository.searchDetailed(any())).thenAnswer(
        (_) async => ApiResponse(
          data: [_hadith('hit')],
          metadata: const SearchMetadata(
            pagination: PageMetadata(
              page: 1,
              pageSize: 30,
              displayedTotalPages: 90,
              accessiblePageLimit: 10,
              truncated: true,
            ),
          ),
        ),
      );
      final session = container.read(hadithSessionControllerProvider.notifier);
      await session.setQuery('query');
      expect(session.state.searchPage!.reachablePages, 10);
      await session.goToPage(11);
      verify(() => repository.searchDetailed(any())).called(1);
    });

    test('setFilters commits the full selection set in one write', () async {
      when(() => repository.searchDetailed(any()))
          .thenAnswer((_) async => _response('hit'));

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'query');

      const next = HadithFilters(
        scholars: [
          ReferenceChoice(id: '1', name: 'a'),
          ReferenceChoice(id: '2', name: 'b'),
          ReferenceChoice(id: '3', name: 'c'),
        ],
      );
      await session.setFilters(next, debounced: false);

      final state = container.read(hadithSessionControllerProvider);
      expect(state.filters.scholars.map((s) => s.id), ['1', '2', '3']);
    });

    test(
      'Saved Back restores the actual page without replaying the search',
      () async {
        when(() => repository.searchDetailed(any()))
            .thenAnswer((_) async => _response('original'));
        final session = container.read(
          hadithSessionControllerProvider.notifier,
        );
        await session.setQuery('original');
        await session.selectHadith(session.state.results.single);
        session.setResultsOffset(180);
        final before = session.state;
        await session.openBookmarks();
        expect(session.state.mode, HadithViewMode.bookmarks);
        session.returnToWorkspace();
        expect(session.state.searchOutcome, same(before.searchOutcome));
        expect(session.state.readerTrail, same(before.readerTrail));
        expect(session.state.resultsOffset, 180);
        verify(() => repository.searchDetailed(any())).called(1);
      },
    );

    test('selectHadith does not replace searchOutcome', () async {
      when(() => repository.searchDetailed(any()))
          .thenAnswer((_) async => _response('hit'));

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'q');
      await session.search();

      final before = container
          .read(hadithSessionControllerProvider)
          .searchOutcome;
      await session.selectHadith(_hadith('hit'));
      final after = container
          .read(hadithSessionControllerProvider)
          .searchOutcome;

      expect(identical(before, after), isTrue);
    });

    test('toggleFavorite propagates repository failures', () async {
      when(() => repository.isFavoriteByKey(any()))
          .thenAnswer((_) async => false);
      when(() => repository.toggleFavorite(any()))
          .thenThrow(Exception('bookmark failed'));

      final session = container.read(hadithSessionControllerProvider.notifier);

      await expectLater(
        session.toggleFavorite(_hadith('x')),
        throwsA(
          isA<Exception>().having(
            (e) => '$e',
            'message',
            contains('bookmark failed'),
          ),
        ),
      );
    });
  });

  group('HadithRecentSearches keepAlive', () {
    test('survives listener removal without refetch', () async {
      final sub = container.listen(
        hadithRecentSearchesStoreProvider,
        (_, _) {},
      );
      await container.read(hadithRecentSearchesStoreProvider.future);
      verify(() => repository.getRecentSearches()).called(1);

      sub.close();
      await pumpEventQueue();

      await container.read(hadithRecentSearchesStoreProvider.future);
      verifyNever(() => repository.getRecentSearches());
    });
  });
}

SourcedDocument _document() {
  const text = 'Synthetic prose';
  return SourcedDocument(
    sourceHtml: '',
    sourceText: text,
    contentHash: sha256.convert(utf8.encode('1\n$text')).toString(),
    blocks: const [
      DocumentBlock(
        kind: BlockKind.paragraph,
        range: TextRange(0, text.length),
      ),
    ],
  );
}
