import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_flow_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_service.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_time_recommendations.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'muslim_fortress_provider.g.dart';

/// Returns the persisted fortress screen state from shared application settings.
@riverpod
FortressScreenState fortressUiState(Ref ref) {
  final settings = ref.watch(fortressScreenSettingsProvider);
  return settings.asData?.value ?? FortressScreenState.initial();
}

/// Returns the currently selected fortress chapter.
@riverpod
FortressCategory? fortressSelectedCategory(Ref ref) {
  return ref.watch(fortressScreenControllerProvider).selectedCategory;
}

/// Returns whether fortress focus-reading mode is active.
@riverpod
bool fortressIsFocusMode(Ref ref) {
  return ref.watch(fortressScreenControllerProvider).isFocusMode;
}

/// Returns the initial dua index for focus-reading mode.
@riverpod
int fortressFocusStartIndex(Ref ref) {
  return ref.watch(fortressScreenControllerProvider).focusStartIndex;
}

/// Coordinates fortress screen session state and navigation actions.
@riverpod
class FortressScreenController extends _$FortressScreenController {
  @override
  FortressFlowState build() => const FortressFlowState();

  /// Selects a chapter in the main pane, or clears selection when tapped again.
  void selectCategory(FortressCategory category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearSelectedCategory: true);
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

    final chapters = await ref.read(muslimFortressChaptersProvider.future);
    final category = chapters
        .where((chapter) => chapter.chapterId == hit.chapterId)
        .firstOrNull;
    if (category == null) return;

    selectCategory(category);

    final duas = await ref.read(
      muslimFortressDuasProvider(hit.chapterId).future,
    );
    final index = duas.indexWhere((dua) => dua.contentId == hit.item.contentId);
    startFocusReading(initialIndex: index >= 0 ? index : 0);
  }
}

/// Active time-of-day recommendation window as a value-equal key.
///
/// Recomputed at most once per minute (via [currentMinuteBucketProvider]) but
/// its String value only changes when the prayer window crosses (~5–6x/day),
/// so [fortressRecommendedCategories] re-runs only then rather than every tick.
@riverpod
String fortressRecommendationWindow(Ref ref) {
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
  if (day == null) return '';
  // Newline-joined: fragments are single-line phrases that may contain spaces.
  return recommendTitleFragments(
    now: day.now,
    prayerTimes: day.today,
    location: day.location,
  ).join('\n');
}

/// Time-based recommended fortress categories for the welcome pane.
///
/// Keyed on the value-equal [fortressRecommendationWindowProvider], so the
/// welcome pane rebuilds only at window crossings rather than on every 1 Hz
/// clock tick (mirrors the [sunnahTimeLabels] dedup pattern).
@riverpod
List<FortressCategory> fortressRecommendedCategories(Ref ref) {
  final window = ref.watch(fortressRecommendationWindowProvider);
  final categories =
      ref.watch(muslimFortressChaptersProvider).asData?.value ??
      const <FortressCategory>[];
  if (window.isEmpty || categories.isEmpty) return const <FortressCategory>[];
  return fortressCategoriesForFragments(
    allCategories: categories,
    fragments: window.split('\n'),
  );
}

/// All Hisn al-Muslim titles for the fortress UI.
@riverpod
Future<List<FortressCategory>> muslimFortressChapters(Ref ref) async {
  final service = await ref.watch(fortressServiceProvider.future);
  return service.loadChapters();
}

/// Dhikr items for a single Hisn title.
///
/// [chapterId] is the Hisn title id.
@riverpod
Future<List<FortressDuaItem>> muslimFortressDuas(
  Ref ref,
  int chapterId,
) async {
  final chaptersFuture = ref.watch(muslimFortressChaptersProvider.future);
  final service = await ref.watch(fortressServiceProvider.future);
  final chapters = await chaptersFuture;
  return service.loadDuasForChapter(chapterId, chapters: chapters);
}

/// In-memory global search query (trimmed; debounced in the screen).
@riverpod
class MuslimFortressSearchQuery extends _$MuslimFortressSearchQuery {
  @override
  String build() => '';

  /// Updates the active search query.
  void setQuery(String query) => state = query.trim();
}

/// Search results for [muslimFortressSearchQueryProvider].
@riverpod
Future<FortressSearchResults> muslimFortressSearchResults(Ref ref) async {
  final query = ref.watch(muslimFortressSearchQueryProvider);
  final service = await ref.watch(fortressServiceProvider.future);
  return service.search(query);
}

/// On-demand sharh commentary for a Hisn content id.
@riverpod
Future<HisnCommentary?> muslimFortressCommentary(
  Ref ref,
  int contentId,
) async {
  final service = await ref.watch(fortressServiceProvider.future);
  return service.loadCommentaryForContent(contentId);
}
