import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';

part 'fortress_screen_settings_provider.g.dart';

const _logPrefix = '[FortressScreenSettingsNotifier]';

/// Persisted Muslim Fortress screen UI state.
@riverpod
@JsonPersist()
class FortressScreenSettingsNotifier extends _$FortressScreenSettingsNotifier {
  @override
  Future<FortressScreenState> build() async {
    await persist(
      ref.watch(settingsStorageProvider.future),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    final hydrated = state.value ?? FortressScreenState.initial();

    // Seed only when both hydrate and the Hisn repo are ready. Watching the
    // AsyncValue (not `.future`) lets settings resolve first, then rebuild and
    // seed once the repo loads — without a discarded in-flight await race.
    final repository = ref.watch(fortressRepositoryProvider).asData?.value;
    if (repository == null) return hydrated;

    final seeded = hydrated.seedDefaultBookmarks(
      repository.defaultBookmarkChapterIds(),
    );
    if (seeded != hydrated) {
      ref
          .read(loggerProvider)
          .i('$_logPrefix Fortress default bookmarks updated');
    }
    return seeded;
  }

  void _commit(
    FortressScreenState Function(FortressScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_logPrefix $field updated');
  }

  /// Sets the fortress sidebar tab.
  void setSidebarTab(FortressSidebarTab tab) =>
      _commit((s) => s.copyWith(sidebarTab: tab), 'Fortress sidebar tab');

  /// Toggles a chapter in the favorites list (most recent first).
  void toggleFavorite(int chapterId) => _commit((s) {
    final ids = List<int>.from(s.favoriteChapterIds);
    if (ids.contains(chapterId)) {
      ids.remove(chapterId);
    } else {
      ids.insert(0, chapterId);
    }
    return s.copyWith(favoriteChapterIds: ids);
  }, 'Fortress favorite chapter');

  /// Sets the side panel width ratio (0..1).
  void setSidePanelRatio(double ratio) =>
      _commit((s) => s.copyWith(sidePanelRatio: ratio), 'Side panel ratio');

  /// Sets whether the side panel is collapsed.
  void setSidePanelCollapsed({required bool collapsed}) => _commit(
    (s) => s.copyWith(sidePanelCollapsed: collapsed),
    'Side panel collapsed',
  );
}
