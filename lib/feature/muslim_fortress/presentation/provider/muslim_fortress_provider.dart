import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_flow_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_time_recommendations.dart';
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

    _openCategory(category);
  }

  /// Force-selects a chapter (no toggle). Used by search result open paths.
  void _openCategory(FortressCategory category) {
    state = state.copyWith(
      selectedCategory: category,
      isFocusMode: false,
      // Opening a chapter exits global search so the detail pane shows.
      query: '',
    );
  }

  /// Enters focus-reading mode for the selected chapter.
  ///
  /// Callers must ensure the chapter has content; empty focus still exposes
  /// Finish chrome as a safety net.
  void startFocusReading({int initialIndex = 0}) {
    if (state.selectedCategory == null) return;
    state = state.copyWith(
      isFocusMode: true,
      focusStartIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  /// Leaves focus-reading mode while keeping the selected chapter.
  void exitFocusMode() {
    if (!state.isFocusMode) return;
    state = state.copyWith(isFocusMode: false);
  }

  /// Updates the active **global** Hisn search query (trimmed).
  ///
  /// Sidebar chapter filtering is local and must not call this.
  void setQuery(String query) {
    final trimmed = query.trim();
    if (state.query == trimmed) return;
    state = state.copyWith(query: trimmed);
  }

  /// Clears the global fortress search query.
  void clearGlobalSearch() {
    if (state.query.isEmpty) return;
    state = state.copyWith(query: '');
  }

  /// Opens a title search result in the main pane (force-select, no toggle).
  void selectSearchTitle(FortressCategory category) {
    _openCategory(category);
  }

  /// Opens a content search result in focus-reading mode (force-select).
  Future<void> selectSearchContent(FortressSearchContentHit hit) async {
    final repository = await ref.read(fortressRepositoryProvider.future);
    if (!ref.mounted) return;

    final category = repository
        .loadChapters()
        .where((chapter) => chapter.chapterId == hit.chapterId)
        .firstOrNull;
    if (category == null) return;

    _openCategory(category);

    final duas = repository.loadDuas(hit.chapterId);
    if (duas.isEmpty) return;

    final index = duas.indexWhere((dua) => dua.contentId == hit.item.contentId);
    startFocusReading(initialIndex: index >= 0 ? index : 0);
  }
}

/// Async global Hisn search for [query] (avoids sync SQLite work during build).
@riverpod
Future<FortressSearchResults> fortressSearchResults(
  Ref ref,
  String query,
) async {
  final repository = await ref.watch(fortressRepositoryProvider.future);
  // Yield so the search is not executed synchronously inside build.
  await Future<void>.delayed(Duration.zero);
  if (!ref.mounted) return FortressSearchResults.empty;
  return repository.search(query);
}

/// Time-based recommended fortress categories for the welcome pane.
///
/// Fragments are recomputed at most once per minute via
/// [currentMinuteBucketProvider]. Const fragment lists are reused across ticks
/// within the same window.
///
/// Falls back to clock-hour fragments when [prayerDayProvider] has no snapshot.
/// Returns `[]` while the repository is loading — treat that as loading, not
/// “no recommendations”, until [fortressRepositoryProvider] has data.
@riverpod
List<FortressCategory> fortressRecommendedCategories(Ref ref) {
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
  final fragments = recommendTitleFragments(
    now: day?.now ?? DateTime.now(),
    prayerTimes: day?.today,
    location: day?.location,
  );

  final repository = ref.watch(fortressRepositoryProvider).asData?.value;
  if (repository == null) {
    return const <FortressCategory>[];
  }
  final categories = repository.loadChapters();
  if (fragments.isEmpty || categories.isEmpty) {
    return const <FortressCategory>[];
  }
  return fortressCategoriesForFragments(
    allCategories: categories,
    fragments: fragments,
  );
}
