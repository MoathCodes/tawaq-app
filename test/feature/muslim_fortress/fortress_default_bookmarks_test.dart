import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';

FortressCategory _category(int chapterId, {String title = 'title'}) =>
    FortressCategory(
      chapterId: chapterId,
      title: title,
      recurrence: HisnRecurrence.daily,
      supplicationCount: 1,
    );

void main() {
  group('FortressCategory equality', () {
    test('== and hashCode use chapterId only', () {
      final a = _category(7, title: 'a');
      final b = _category(7, title: 'b');
      final c = _category(8, title: 'a');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('FortressScreenController selectCategory', () {
    test('toggle deselects across distinct instances with same chapterId', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        fortressScreenControllerProvider.notifier,
      )..selectCategory(_category(3, title: 'first'));
      expect(
        container.read(fortressScreenControllerProvider).selectedChapterId,
        3,
      );

      controller.selectCategory(_category(3, title: 'second instance'));
      expect(
        container.read(fortressScreenControllerProvider).selectedChapterId,
        isNull,
      );
    });
  });

  group('fortress default bookmarks', () {
    late HisnClient client;

    setUp(() async {
      client = await HisnClient.open();
    });

    tearDown(() {
      client.close();
    });

    test('all fragments resolve to exactly one chapter each', () {
      expect(fortressDefaultBookmarkFragments, hasLength(8));

      for (final fragment in fortressDefaultBookmarkFragments) {
        final matches = client.titles.byNameFragments([fragment]);
        expect(
          matches,
          hasLength(1),
          reason: 'Expected one chapter for fragment: $fragment',
        );
      }
    });

    test('seedDefaultBookmarks is once-only and preserves favorites', () {
      const defaults = [1, 2, 3];
      final seeded = FortressScreenState.initial().seedDefaultBookmarks(
        defaults,
      );
      expect(seeded.favoriteChapterIds, defaults);
      expect(seeded.defaultBookmarksSeeded, isTrue);

      final again = seeded.seedDefaultBookmarks([9, 9, 9]);
      expect(again.favoriteChapterIds, defaults);

      final withFavorites = const FortressScreenState(
        favoriteChapterIds: [42],
      ).seedDefaultBookmarks(defaults);
      expect(withFavorites.favoriteChapterIds, [42]);
      expect(withFavorites.defaultBookmarksSeeded, isTrue);
    });

    test('settings seeds once when repo becomes ready after hydrate', () async {
      final storage = Storage<String, String>.inMemory();
      final repoCompleter = Completer<FortressRepository>();
      final repository = FortressRepository(client);
      final expectedIds = repository.defaultBookmarkChapterIds();
      expect(expectedIds, isNotEmpty);

      final container = ProviderContainer(
        overrides: [
          hiveCoreInitProvider.overrideWith((ref) async {}),
          settingsStorageProvider.overrideWith((ref) async => storage),
          fortressRepositoryProvider.overrideWith(
            (ref) => repoCompleter.future,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Settings hydrate can finish while the repo is still pending.
      final beforeRepo = await container.read(
        fortressScreenSettingsProvider.future,
      );
      expect(beforeRepo.defaultBookmarksSeeded, isFalse);
      expect(beforeRepo.favoriteChapterIds, isEmpty);

      final seededCompleter = Completer<FortressScreenState>();
      final sub = container.listen(
        fortressScreenSettingsProvider,
        (previous, next) {
          next.whenData((value) {
            if (value.defaultBookmarksSeeded && !seededCompleter.isCompleted) {
              seededCompleter.complete(value);
            }
          });
        },
      );
      addTearDown(sub.close);

      repoCompleter.complete(repository);
      final state = await seededCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      expect(state.favoriteChapterIds, expectedIds);

      // Rebuild / re-read must not re-seed over user favorites.
      container
          .read(fortressScreenSettingsProvider.notifier)
          .toggleFavorite(expectedIds.first);
      final afterToggle = container
          .read(fortressScreenSettingsProvider)
          .requireValue;
      expect(
        afterToggle.favoriteChapterIds.contains(expectedIds.first),
        isFalse,
      );

      // Force rebuild by invalidating; seed flag keeps favorites as-is.
      container.invalidate(fortressScreenSettingsProvider);
      final afterRebuild = await container.read(
        fortressScreenSettingsProvider.future,
      );
      expect(afterRebuild.favoriteChapterIds, afterToggle.favoriteChapterIds);
      expect(afterRebuild.defaultBookmarksSeeded, isTrue);
    });
  });
}
