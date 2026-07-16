import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_flow_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_time_recommendations.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';

part 'muslim_fortress_provider.g.dart';

/// Coordinates fortress screen session state and navigation actions.
@riverpod
class FortressScreenController extends _$FortressScreenController {
  @override
  FortressFlowState build() => const FortressFlowState();

  /// Selects a chapter in the main pane, or clears selection when tapped again.
  void selectCategory(FortressCategory category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(selectedCategory: null);
      return;
    }

    state = state.copyWith(
      selectedCategory: category,
      isFocusMode: false,
    );
  }

  /// Enters focus-reading mode for the selected chapter.
  void startFocusReading({int initialIndex = 0}) {
    if (state.selectedCategory == null) return;
    state = state.copyWith(
      isFocusMode: true,
      focusStartIndex: initialIndex,
    );
  }

  /// Leaves focus-reading mode while keeping the selected chapter.
  void exitFocusMode() {
    if (!state.isFocusMode) return;
    state = state.copyWith(isFocusMode: false);
  }

  /// Switches the sidebar to the favorites tab.
  void openFavoritesTab() {
    ref
        .read(fortressScreenSettingsProvider.notifier)
        .setSidebarTab(FortressSidebarTab.favorites);
  }

  /// Clears the global fortress search query.
  void clearGlobalSearch() {
    ref.read(muslimFortressSearchQueryProvider.notifier).setQuery('');
  }

  /// Opens a title search result in the main pane.
  void selectSearchTitle(FortressCategory category) {
    clearGlobalSearch();
    selectCategory(category);
  }

  /// Opens a content search result in focus-reading mode.
  Future<void> selectSearchContent(FortressSearchContentHit hit) async {
    clearGlobalSearch();

    final repository = await ref.read(fortressRepositoryProvider.future);
    final category = repository
        .loadChapters()
        .where((chapter) => chapter.chapterId == hit.chapterId)
        .firstOrNull;
    if (category == null) return;

    selectCategory(category);

    final duas = repository.loadDuas(hit.chapterId);
    final index = duas.indexWhere((dua) => dua.contentId == hit.item.contentId);
    startFocusReading(initialIndex: index >= 0 ? index : 0);
  }
}

/// Time-based recommended fortress categories for the welcome pane.
///
/// Fragments are recomputed at most once per minute via
/// [currentMinuteBucketProvider]. Const fragment lists are reused across ticks
/// within the same window.
@riverpod
List<FortressCategory> fortressRecommendedCategories(Ref ref) {
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
  if (day == null) return const [];

  final fragments = recommendTitleFragments(
    now: day.now,
    prayerTimes: day.today,
    location: day.location,
  );
  final categories =
      ref.watch(fortressRepositoryProvider).asData?.value.loadChapters() ??
      const <FortressCategory>[];
  if (fragments.isEmpty || categories.isEmpty) {
    return const <FortressCategory>[];
  }
  return fortressCategoriesForFragments(
    allCategories: categories,
    fragments: fragments,
  );
}

/// In-memory global search query (trimmed; debounced in the screen).
@riverpod
class MuslimFortressSearchQuery extends _$MuslimFortressSearchQuery {
  @override
  String build() => '';

  /// Updates the active search query.
  void setQuery(String query) => state = query.trim();
}
