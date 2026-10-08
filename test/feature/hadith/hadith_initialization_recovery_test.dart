import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';

class _Client extends Mock implements DorarClient {}

class _Local extends Mock implements HadithLocalDatabase {}

void main() {
  for (final consumer in ['lookup', 'detail']) {
    test('$consumer retry resets failed Dorar initialization and recovers', () async {
      var attempts = 0;
      final client = _Client();
      final local = _Local();
      when(() => client.searchMohdith('اب')).thenAnswer((_) async => []);
      when(() => client.getAlternates('fixture')).thenAnswer(
        (_) async => const ApiResponse(
          data: RelatedHadithResult(
            requestedId: 'fixture',
            source: null,
            kind: RelatedHadithKind.alternate,
            related: [],
          ),
          metadata: SearchMetadata(),
        ),
      );
      when(() => local.getFavoriteEntries()).thenAnswer((_) async => []);
      when(() => local.getRecentSearches()).thenAnswer((_) async => []);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          dorarInitProvider.overrideWith((ref) async {
            if (++attempts == 1) throw StateError('initialization failed');
          }),
          dorarClientProvider.overrideWith((ref) async {
            await ref.watch(dorarInitProvider.future);
            return client;
          }),
          hadithLocalDatabaseProvider.overrideWithValue(local),
        ],
      );
      addTearDown(container.dispose);
      container.listen(hadithSessionControllerProvider, (_, _) {});
      Future<Object?> load() => switch (consumer) {
        'lookup' => container.read(
          hadithLookupProvider(HadithLookupKind.scholars, 'اب').future,
        ),
        'detail' => container.read(
          hadithRelatedProvider(
            HadithRecordId('fixture'),
            RelatedHadithKind.alternate,
          ).future,
        ),
        _ => throw StateError('unexpected consumer'),
      };
      await expectLater(load(), throwsStateError);
      container
          .read(hadithSessionControllerProvider.notifier)
          .retryInitialization();
      switch (consumer) {
        case 'lookup':
          container.invalidate(
            hadithLookupProvider(HadithLookupKind.scholars, 'اب'),
          );
        case 'detail':
          container.invalidate(
            hadithRelatedProvider(
              HadithRecordId('fixture'),
              RelatedHadithKind.alternate,
            ),
          );
        case 'favorites':
          container.invalidate(hadithFavoritesStoreProvider);
        case 'recents':
          container.invalidate(hadithRecentSearchesStoreProvider);
      }
      expect(
        await load(),
        consumer == 'detail'
            ? isA<ApiResponse<RelatedHadithResult>>()
            : isEmpty,
      );
      expect(attempts, 2);
      // Request retries preserve successful initialization and the live client.
      container
          .read(hadithSessionControllerProvider.notifier)
          .retryInitialization();
      expect(await container.read(dorarClientProvider.future), same(client));
      expect(attempts, 2);
    });
  }
}
