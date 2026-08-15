import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';

FortressCategory _category(int chapterId, {String title = 'title'}) =>
    FortressCategory(
      chapterId: chapterId,
      title: title,
      recurrence: HisnRecurrence.daily,
      supplicationCount: 1,
    );

void main() {
  group('FortressScreenController search vs filter isolation', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('session query starts empty (sidebar filter is local-only)', () {
      final state = container.read(fortressScreenControllerProvider);
      expect(state.query, isEmpty);
      expect(state.query.length < fortressSearchMinQueryLength, isTrue);
    });

    test('setQuery drives global search; selectCategory clears it', () {
      final controller =
          container.read(fortressScreenControllerProvider.notifier)
            ..setQuery('دعاء')
            ..selectCategory(_category(1));

      final state = container.read(fortressScreenControllerProvider);
      expect(state.query, isEmpty);
      expect(state.selectedChapterId, 1);

      controller.setQuery('الصباح');
      expect(
        container.read(fortressScreenControllerProvider).query.length,
        greaterThanOrEqualTo(fortressSearchMinQueryLength),
      );
    });

    test('clearGlobalSearch exits search without clearing selection', () {
      final controller =
          container.read(fortressScreenControllerProvider.notifier)
            ..selectCategory(_category(2))
            ..setQuery('نوم');

      expect(container.read(fortressScreenControllerProvider).query, 'نوم');
      expect(
        container.read(fortressScreenControllerProvider).selectedChapterId,
        2,
      );

      controller.clearGlobalSearch();
      final state = container.read(fortressScreenControllerProvider);
      expect(state.query, isEmpty);
      expect(state.selectedChapterId, 2);
    });
  });

  group('FortressScreenController search open without toggle', () {
    test(
      'selectSearchTitle keeps already-selected chapter and clears query',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final category = _category(5);
        final controller =
            container.read(fortressScreenControllerProvider.notifier)
              ..selectCategory(category)
              ..setQuery('صباح');

        expect(
          container.read(fortressScreenControllerProvider).selectedChapterId,
          category.chapterId,
        );

        // Toggle-style selectCategory would clear; search open must not.
        controller.selectSearchTitle(_category(5, title: 'other instance'));

        final state = container.read(fortressScreenControllerProvider);
        expect(state.selectedChapterId, 5);
        expect(state.query, isEmpty);
        expect(state.isFocusMode, isFalse);
      },
    );

    test(
      'selectSearchContent enters focus when chapter already selected',
      () async {
        final client = await HisnClient.open();
        addTearDown(client.close);
        final repository = FortressRepository(client);
        final chapters = repository.loadChapters();
        expect(chapters, isNotEmpty);
        final category = chapters.first;
        final duas = repository.loadDuas(category.chapterId);
        expect(duas, isNotEmpty);

        final container = ProviderContainer(
          overrides: [
            fortressRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(fortressScreenControllerProvider.notifier)
            .selectCategory(_category(category.chapterId));
        expect(
          container.read(fortressScreenControllerProvider).selectedChapterId,
          category.chapterId,
        );

        await container
            .read(fortressScreenControllerProvider.notifier)
            .selectSearchContent(
              FortressSearchContentHit(
                chapterId: category.chapterId,
                categoryTitle: category.title,
                item: duas.first,
              ),
            );

        final state = container.read(fortressScreenControllerProvider);
        expect(state.selectedChapterId, category.chapterId);
        expect(state.isFocusMode, isTrue);
        expect(state.focusStartIndex, 0);
        expect(state.query, isEmpty);
      },
    );
  });

  group('FortressScreenController focus empty exit', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('startFocusReading + exitFocusMode round-trip', () {
      final controller =
          container.read(fortressScreenControllerProvider.notifier)
            ..selectCategory(_category(9))
            ..startFocusReading();

      expect(
        container.read(fortressScreenControllerProvider).isFocusMode,
        isTrue,
      );

      controller.exitFocusMode();
      final state = container.read(fortressScreenControllerProvider);
      expect(state.isFocusMode, isFalse);
      expect(state.selectedChapterId, 9);
    });

    test('startFocusReading no-ops without a selected category', () {
      container
          .read(fortressScreenControllerProvider.notifier)
          .startFocusReading();
      expect(
        container.read(fortressScreenControllerProvider).isFocusMode,
        isFalse,
      );
    });
  });
}
