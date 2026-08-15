import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
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
        container.read(hadithSessionControllerProvider).isLoading,
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
      expect(state.totalPages, 1);
      expect(state.isLoading, isFalse);
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
      expect(state.paginationError, contains('page failed'));
      expect(state.isPaginating, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('setFilters commits the full selection set in one write', () async {
      when(
        () => repository.searchDetailed(any()),
      ).thenAnswer((_) async => _response('hit'));

      final session = container.read(hadithSessionControllerProvider.notifier);
      session.state = session.state.copyWith(query: 'query');

      const next = HadithFilters(
        scholars: [
          HadithLookupRef(id: '1', name: 'a'),
          HadithLookupRef(id: '2', name: 'b'),
          HadithLookupRef(id: '3', name: 'c'),
        ],
      );
      await session.setFilters(next, debounced: false);

      final state = container.read(hadithSessionControllerProvider);
      expect(state.filters.scholars.map((s) => s.id), ['1', '2', '3']);
    });

    test(
      'exitSpecificMode restores search snapshot from specificList',
      () async {
        when(
          () => repository.searchDetailed(any()),
        ).thenAnswer((_) async => _response('restored'));

        final session = container.read(
          hadithSessionControllerProvider.notifier,
        );
        session.state = session.state.copyWith(
          query: 'original',
          filters: const HadithFilters(specialist: true),
        );
        await session.openSpecificList([_hadith('similar')]);

        expect(
          container.read(hadithSessionControllerProvider).mode,
          HadithViewMode.specificList,
        );

        await session.exitSpecificMode();

        final state = container.read(hadithSessionControllerProvider);
        expect(state.mode, HadithViewMode.search);
        expect(state.query, 'original');
        expect(state.filters.specialist, isTrue);
        expect(state.results.single.hadith, 'restored');
      },
    );

    test('selectHadith does not replace searchOutcome', () async {
      when(
        () => repository.searchDetailed(any()),
      ).thenAnswer((_) async => _response('hit'));

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
      when(
        () => repository.isFavoriteByKey(any()),
      ).thenAnswer((_) async => false);
      when(
        () => repository.toggleFavorite(any()),
      ).thenThrow(Exception('bookmark failed'));

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
