import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_flow_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_search_state.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_service.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'hadith_provider.g.dart';

/// Returns the persisted hadith screen state from shared application settings.
@riverpod
HadithScreenState hadithUiState(Ref ref) {
  final settings = ref.watch(hadithScreenSettingsProvider);
  return settings.asData?.value ?? HadithScreenState.initial();
}

/// Returns the active hadith filters stored in the screen state.
@riverpod
HadithFilters hadithFilters(Ref ref) {
  final uiState = ref.watch(hadithUiStateProvider);
  return uiState.filters;
}

/// Returns the current session search query (in-memory only).
@riverpod
String hadithQuery(Ref ref) {
  return ref.watch(hadithScreenControllerProvider).query;
}

/// Returns the currently selected hadith panel tab.
@riverpod
HadithPanelTab hadithActiveTab(Ref ref) {
  final uiState = ref.watch(hadithUiStateProvider);
  return uiState.activeTab;
}

/// Returns the persisted hadith side-panel width.
@riverpod
double hadithSidePanelWidth(Ref ref) {
  final uiState = ref.watch(hadithUiStateProvider);
  return uiState.sidePanelWidth;
}

/// Loads the user's bookmarked hadiths.
@riverpod
Future<List<DetailedHadith>> hadithBookmarkedHadiths(Ref ref) {
  return ref.read(hadithServiceProvider).getFavorites();
}

/// Returns the current hadith view mode.
@riverpod
HadithViewMode hadithViewMode(Ref ref) {
  final flowState = ref.watch(hadithScreenControllerProvider);
  return flowState.mode;
}

/// Returns whether the hadith UI is currently showing the search view.
@riverpod
bool hadithIsSearchMode(Ref ref) {
  return ref.watch(hadithViewModeProvider) == HadithViewMode.search;
}

/// Returns recent searches only when the search view should display them.
@riverpod
AsyncValue<List<String>> hadithVisibleRecentSearches(Ref ref) {
  final isSearchMode = ref.watch(hadithIsSearchModeProvider);
  if (!isSearchMode) {
    return const AsyncData<List<String>>(<String>[]);
  }

  return ref.watch(hadithRecentSearchesProvider);
}

/// True while a hadith search request or pagination fetch is in flight.
@riverpod
bool hadithSearchBusy(Ref ref) {
  final state =
      ref.watch(hadithSearchControllerProvider).asData?.value ??
      const HadithSearchState();
  return state.isLoading || state.isLoadingMore;
}

/// Whether filter and filter-chip actions should accept input.
///
/// Disabled while search is busy. Filter chips also require a non-empty query
/// because removing a filter triggers a new search.
@riverpod
bool hadithFilterInteractionsEnabled(Ref ref) {
  if (ref.watch(hadithSearchBusyProvider)) {
    return false;
  }
  if (!ref.watch(hadithIsSearchModeProvider)) {
    return false;
  }
  return ref.watch(hadithQueryProvider).trim().isNotEmpty ||
      ref.watch(hadithFiltersProvider) != HadithFilters.fromJson({});
}

/// Returns the hadith results visible for the active view mode.
@riverpod
AsyncValue<List<DetailedHadith>> hadithVisibleResults(Ref ref) {
  final mode = ref.watch(hadithViewModeProvider);
  return switch (mode) {
    HadithViewMode.search => AsyncData(
      ref.watch(hadithSearchControllerProvider).asData?.value.results ??
          const <DetailedHadith>[],
    ),
    HadithViewMode.bookmarks => ref.watch(hadithBookmarkedHadithsProvider),
    HadithViewMode.specificList => AsyncData(
      ref.watch(hadithScreenControllerProvider).specificHadiths,
    ),
  };
}

/// Coordinates hadith screen state, mode transitions, and search actions.
@riverpod
class HadithScreenController extends _$HadithScreenController {
  static const _queryDebounceDuration = Duration(milliseconds: 420);
  static const _filtersDebounceDuration = Duration(milliseconds: 250);

  Timer? _queryDebounce;
  Timer? _filtersDebounce;
  String? _lastBootstrapSignature;

  @override
  HadithFlowState build() {
    ref.onDispose(_cancelDebounces);
    return const HadithFlowState();
  }

  /// Bootstraps the controller into search or specific-list mode.
  Future<void> bootstrap({
    List<DetailedHadith> hadiths = const <DetailedHadith>[],
  }) async {
    final signature = _bootstrapSignature(hadiths: hadiths);
    if (_lastBootstrapSignature == signature) return;
    _lastBootstrapSignature = signature;

    if (hadiths.isEmpty) {
      await exitSpecificMode();
    } else {
      await openSpecificList(hadiths);
    }
  }

  String _bootstrapSignature({required List<DetailedHadith> hadiths}) {
    if (hadiths.isEmpty) return 'search';

    final keys = hadiths.map(hadithStableKey).toList(growable: false)..sort();
    return 'specificList:${keys.join('|')}';
  }

  /// Clears the persisted recent-search history.
  Future<void> clearRecentSearches() {
    return ref
        .read(hadithSearchControllerProvider.notifier)
        .clearRecentSearches();
  }

  /// Persists the active hadith panel tab.
  void setActiveTab(HadithPanelTab tab) {
    return ref.read(hadithScreenSettingsProvider.notifier).setActiveTab(tab);
  }

  /// Persists the hadith side-panel width.
  void setSidePanelWidth(double width) {
    return ref
        .read(hadithScreenSettingsProvider.notifier)
        .setSidePanelWidth(width);
  }

  /// Updates the session search query and optionally debounces a refresh.
  Future<void> setQuery(String query, {bool debounced = true}) async {
    if (query == state.query) {
      if (!debounced && state.isSearchMode) {
        await search();
      }
      return;
    }

    if (!state.isSearchMode) {
      await exitSpecificMode(restoreSearchSnapshot: false);
    }

    state = state.copyWith(query: query);
    if (!debounced) {
      await search();
      return;
    }

    _queryDebounce?.cancel();
    _queryDebounce = Timer(_queryDebounceDuration, () {
      unawaited(search());
    });
  }

  /// Updates the active filters and optionally debounces a refresh.
  Future<void> setFilters(
    HadithFilters filters, {
    bool debounced = true,
  }) async {
    final persistedFilters = ref.read(hadithFiltersProvider);
    if (filters == persistedFilters) {
      if (!debounced && state.isSearchMode) {
        await search();
      }
      return;
    }

    ref.read(hadithScreenSettingsProvider.notifier).setFilters(filters);

    if (!state.isSearchMode) {
      return;
    }

    if (!debounced) {
      await search();
      return;
    }

    _filtersDebounce?.cancel();
    _filtersDebounce = Timer(_filtersDebounceDuration, () {
      unawaited(search());
    });
  }

  /// Clears all active hadith search filters.
  Future<void> clearFilters() {
    return setFilters(const HadithFilters(), debounced: false);
  }

  /// Triggers a search using the current query and filters.
  Future<void> search() {
    return ref.read(hadithSearchControllerProvider.notifier).search();
  }

  /// Requests the next page of search results.
  Future<void> loadMore() {
    return ref.read(hadithSearchControllerProvider.notifier).loadMore();
  }

  /// Selects a hadith and optionally opens the details tab.
  Future<void> selectHadith(
    DetailedHadith hadith, {
    bool openDetailsTab = true,
  }) async {
    ref.read(hadithSelectorProvider.notifier).selectHadith(hadith);
    if (openDetailsTab) {
      setActiveTab(HadithPanelTab.details);
    }
  }

  /// Switches to bookmarks mode and selects the first favorite when possible.
  Future<void> openBookmarks() async {
    await _enterSpecificMode(mode: HadithViewMode.bookmarks);
    final favorites = await ref.read(hadithBookmarkedHadithsProvider.future);

    if (state.mode != HadithViewMode.bookmarks) return;

    if (favorites.isEmpty) {
      ref.read(hadithSelectorProvider.notifier).clearSelection();
      return;
    }

    await selectHadith(favorites.first);
  }

  /// Switches to specific-list mode for the provided hadiths.
  Future<void> openSpecificList(
    List<DetailedHadith> hadiths, {
    DetailedHadith? selected,
  }) async {
    await _enterSpecificMode(
      mode: HadithViewMode.specificList,
      hadiths: hadiths,
      selected: selected,
    );
  }

  /// Leaves specific modes and restores the previous search snapshot.
  Future<void> exitSpecificMode({bool restoreSearchSnapshot = true}) async {
    if (state.mode == HadithViewMode.search) return;

    _cancelDebounces();

    final snapshot = restoreSearchSnapshot ? state.searchSnapshot : null;
    state = HadithFlowState(query: snapshot?.query ?? '');

    ref
        .read(hadithScreenSettingsProvider.notifier)
        .setFilters(snapshot?.filters ?? const HadithFilters());
    await ref.read(hadithSearchControllerProvider.notifier).search();

    if ((snapshot?.query ?? '').trim().isEmpty) {
      ref.read(hadithSelectorProvider.notifier).clearSelection();
    }
  }

  Future<void> _enterSpecificMode({
    required HadithViewMode mode,
    List<DetailedHadith> hadiths = const <DetailedHadith>[],
    DetailedHadith? selected,
  }) async {
    _cancelDebounces();

    final snapshot = state.searchSnapshot ?? _captureSearchSnapshot();

    state = state.copyWith(
      mode: mode,
      specificHadiths: hadiths,
      searchSnapshot: snapshot,
      query: '',
    );

    ref
        .read(hadithScreenSettingsProvider.notifier)
        .setFilters(const HadithFilters());

    await ref.read(hadithSearchControllerProvider.notifier).search();
    setActiveTab(HadithPanelTab.details);

    final target = selected ?? (hadiths.isEmpty ? null : hadiths.first);
    if (target == null) {
      ref.read(hadithSelectorProvider.notifier).clearSelection();
      return;
    }

    await selectHadith(target, openDetailsTab: false);
  }

  HadithSearchSnapshot _captureSearchSnapshot() {
    return HadithSearchSnapshot(
      query: state.query,
      filters: ref.read(hadithFiltersProvider),
    );
  }

  void _cancelDebounces() {
    _queryDebounce?.cancel();
    _queryDebounce = null;
    _filtersDebounce?.cancel();
    _filtersDebounce = null;
  }
}

/// Owns the detailed hadith search state and remote search operations.
@riverpod
class HadithSearchController extends _$HadithSearchController {
  @override
  FutureOr<HadithSearchState> build() async {
    final service = ref.read(hadithServiceProvider);
    final favorites = await service.getFavorites();
    return HadithSearchState(
      favoriteKeys: favorites.map(hadithStableKey).toList(),
    );
  }

  /// Clears the saved recent-search history.
  Future<void> clearRecentSearches() async {
    await ref.read(hadithServiceProvider).clearRecentSearches();
    ref.invalidate(hadithRecentSearchesProvider);
  }

  /// Re-runs the current search after filters change.
  Future<void> applyFilters() async {
    final current = state.asData?.value ?? const HadithSearchState();
    if (current.query.trim().isEmpty) return;
    await search();
  }

  /// Fetches the next page of search results and appends them.
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.isLoading || current.isLoadingMore || !current.hasNextPage) {
      return;
    }

    final filters = ref.read(hadithFiltersProvider);

    final nextPage = current.page + 1;
    state = AsyncData(current.copyWith(isLoadingMore: true, error: null));

    try {
      final response = await ref
          .read(hadithServiceProvider)
          .searchDetailed(_toSearchParams(current, filters, page: nextPage));

      state = AsyncData(
        current.copyWith(
          page: nextPage,
          results: [...current.results, ...response.data],
          metadata: response.metadata,
          isLoadingMore: false,
          error: null,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: '$e'));
    }
  }

  /// Refreshes the cached favorite keys from the hadith service.
  Future<void> refreshFavorites() async {
    final current = state.asData?.value ?? const HadithSearchState();
    final favorites = await ref.read(hadithServiceProvider).getFavorites();
    ref.invalidate(hadithBookmarkedHadithsProvider);
    state = AsyncData(
      current.copyWith(
        favoriteKeys: favorites.map(hadithStableKey).toList(),
      ),
    );
  }

  /// Runs a hadith search for the current session query and filters.
  Future<void> search({bool reset = true}) async {
    final filters = ref.read(hadithFiltersProvider);
    final value = ref.read(hadithQueryProvider).trim();
    final current = state.asData?.value ?? const HadithSearchState();

    if (value.isEmpty) {
      state = AsyncData(
        current.copyWith(
          query: '',
          page: 1,
          results: const <DetailedHadith>[],
          metadata: null,
          error: null,
          isLoading: false,
          isLoadingMore: false,
        ),
      );
      return;
    }

    final targetPage = reset ? 1 : current.page;
    state = AsyncData(
      current.copyWith(
        query: value,
        page: targetPage,
        isLoading: true,
        isLoadingMore: false,
        error: null,
      ),
    );

    try {
      final response = await ref
          .read(hadithServiceProvider)
          .searchDetailed(
            _toSearchParams(current.copyWith(query: value), filters, page: 1),
          );

      state = AsyncData(
        current.copyWith(
          query: value,
          page: 1,
          results: response.data,
          metadata: response.metadata,
          isLoading: false,
          isLoadingMore: false,
          error: null,
        ),
      );

      unawaited(
        ref
            .read(hadithServiceProvider)
            .addRecentSearch(value)
            .then((_) => ref.invalidate(hadithRecentSearchesProvider)),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          query: value,
          isLoading: false,
          isLoadingMore: false,
          error: '$e',
        ),
      );
    }
  }

  /// Toggles a hadith between favorite and non-favorite state.
  Future<void> toggleFavorite(HadithBase hadith) async {
    final current = state.asData?.value ?? const HadithSearchState();
    await ref.read(hadithServiceProvider).toggleFavorite(hadith);
    ref.invalidate(hadithBookmarkedHadithsProvider);

    final key = hadithStableKey(hadith);
    final isFav = current.favoriteKeys.contains(key);
    final next = List<String>.from(current.favoriteKeys);
    if (isFav) {
      next.remove(key);
    } else {
      next.add(key);
    }

    state = AsyncData(current.copyWith(favoriteKeys: next));
  }

  HadithSearchParams _toSearchParams(
    HadithSearchState state,
    HadithFilters filters, {
    int? page,
  }) {
    return HadithSearchParams(
      value: state.query,
      page: page ?? state.page,
      specialist: filters.specialist,
      searchMethod: filters.searchMethod,
      zone: filters.zone,
      degrees: filters.degrees.isEmpty ? null : filters.degrees,
      mohdith: filters.scholars.isEmpty
          ? null
          : filters.scholars
                .map((entry) => entry.toMohdithReference())
                .toList(growable: false),
      books: filters.books.isEmpty
          ? null
          : filters.books
                .map((entry) => entry.toBookReference())
                .toList(growable: false),
      rawi: filters.rawi.isEmpty
          ? null
          : filters.rawi
                .map((entry) => entry.toRawiReference())
                .toList(growable: false),
    );
  }
}

/// Searches books that can be used to narrow hadith lookups.
@riverpod
Future<List<HadithLookupRef>> hadithBooksLookup(Ref ref, String query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final response = await ref.read(hadithServiceProvider).searchBooks(q);
  return response.data
      .map((item) => HadithLookupRef(id: item.id, name: item.name))
      .toList(growable: false);
}

/// Resolves the detailed hadith payload for the given hadith record.
@riverpod
Future<DetailedHadith?> hadithDetails(Ref ref, Hadith hadith) {
  return ref.read(hadithServiceProvider).resolveDetails(hadith);
}

/// Searches scholars that can be used to narrow hadith lookups.
@riverpod
Future<List<HadithLookupRef>> hadithScholarsLookup(
  Ref ref,
  String query,
) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final response = await ref.read(hadithServiceProvider).searchScholars(q);
  return response
      .map((item) => HadithLookupRef(id: item.id, name: item.name))
      .toList(growable: false);
}

/// Searches rawi entries that can be used to narrow hadith lookups.
@riverpod
Future<List<HadithLookupRef>> hadithRawiLookup(Ref ref, String query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final response = await ref.read(hadithServiceProvider).searchRawi(q);
  return response
      .map((item) => HadithLookupRef(id: item.id, name: item.name))
      .toList(growable: false);
}

/// Returns the user's persisted recent-search queries.
@riverpod
Future<List<String>> hadithRecentSearches(Ref ref) async {
  final entries = await ref.read(hadithServiceProvider).getRecentSearches();
  return entries.map((entry) => entry.query).toList(growable: false);
}

/// Loads the sharh metadata for the given sharh identifier.
@riverpod
Future<Sharh> hadithSharh(Ref ref, String sharhId) {
  return ref.read(hadithServiceProvider).getSharh(sharhId);
}

/// Loads hadiths that are similar to the given hadith identifier.
@riverpod
Future<List<DetailedHadith>> hadithSimilar(Ref ref, String hadithId) {
  return ref.read(hadithServiceProvider).getSimilarHadith(hadithId);
}

/// Loads the alternate narration for the given hadith identifier.
@riverpod
Future<DetailedHadith?> hadithAlternate(Ref ref, String hadithId) {
  return ref.read(hadithServiceProvider).getAlternateHadith(hadithId);
}

/// Loads the usul record for the given hadith identifier.
@riverpod
Future<UsulHadith> hadithUsul(Ref ref, String hadithId) {
  return ref.read(hadithServiceProvider).getUsulHadith(hadithId);
}

/// Stores the currently selected hadith for the detail pane.
@riverpod
class HadithSelector extends _$HadithSelector {
  @override
  FutureOr<DetailedHadith?> build() {
    return null;
  }

  /// Marks the supplied hadith as the current selection.
  void selectHadith(DetailedHadith hadith) {
    state = AsyncData(hadith);
  }

  /// Clears the current hadith selection.
  void clearSelection() {
    state = const AsyncData(null);
  }
}
