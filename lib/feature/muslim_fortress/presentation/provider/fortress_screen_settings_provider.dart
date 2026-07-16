import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'fortress_screen_settings_provider.g.dart';

const _logPrefix = '[FortressScreenSettingsNotifier]';

/// Persisted Muslim Fortress screen UI state.
@riverpod
@JsonPersist()
class FortressScreenSettingsNotifier extends _$FortressScreenSettingsNotifier {
  @override
  Future<FortressScreenState> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? FortressScreenState.initial();
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

  /// Seeds default bookmarks once for new users.
  ///
  /// Existing favorites are preserved; only the seeded flag is set.
  void ensureDefaultBookmarks(List<int> defaultIds) => _commit((s) {
    if (s.defaultBookmarksSeeded) return s;
    if (s.favoriteChapterIds.isNotEmpty) {
      return s.copyWith(defaultBookmarksSeeded: true);
    }
    return s.copyWith(
      favoriteChapterIds: defaultIds,
      defaultBookmarksSeeded: true,
    );
  }, 'Fortress default bookmarks');

  /// Sets the side panel width ratio (0..1).
  void setSidePanelRatio(double ratio) =>
      _commit((s) => s.copyWith(sidePanelRatio: ratio), 'Side panel ratio');

  /// Sets whether the side panel is collapsed.
  void setSidePanelCollapsed({required bool collapsed}) => _commit(
    (s) => s.copyWith(sidePanelCollapsed: collapsed),
    'Side panel collapsed',
  );
}
