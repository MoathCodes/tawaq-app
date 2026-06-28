import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

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
  });

  setUp(() {
    repository = MockHadithRepository();
    when(() => repository.addRecentSearch(any())).thenAnswer((_) async {});

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

    test('ignores stale loadMore after a new search starts', () async {
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
          metadata: const SearchMetadata(length: 1, hasNextPage: true),
        ),
      );
      await initialSearch;

      final loadMore = session.loadMore();
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
          metadata: const SearchMetadata(length: 1),
        ),
      );
      await loadMore;
      await pumpEventQueue();

      expect(
        container.read(hadithSessionControllerProvider).results.single.hadith,
        'refreshed-result',
      );
      expect(
        container.read(hadithSessionControllerProvider).isLoadingMore,
        isFalse,
      );
    });
  });
}
