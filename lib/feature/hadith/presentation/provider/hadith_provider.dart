import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';

part 'hadith_provider.g.dart';

/// Widget-layer helper for the active hadith results list.
extension HadithVisibleResultsRef on WidgetRef {
  /// Results list for the active hadith view mode.
  AsyncValue<List<DetailedHadith>> hadithVisibleResults(
    HadithSessionState session,
  ) {
    return switch (session.mode) {
      HadithViewMode.search => AsyncData(session.results),
      HadithViewMode.bookmarks => watch(hadithFavoritesProvider),
      HadithViewMode.specificList => AsyncData(session.specificHadiths),
    };
  }
}

/// Synchronous visible results when favorites are already resolved.
List<DetailedHadith>? hadithVisibleResultsList(
  Ref ref,
  HadithSessionState session,
) {
  return switch (session.mode) {
    HadithViewMode.search => session.results,
    HadithViewMode.bookmarks => ref.read(hadithFavoritesProvider).value,
    HadithViewMode.specificList => session.specificHadiths,
  };
}

/// Bookmarked hadiths loaded from local storage.
@Riverpod(keepAlive: true)
Future<List<DetailedHadith>> hadithFavorites(Ref ref) async {
  final repository = await ref.read(hadithRepositoryProvider.future);
  return repository.getFavorites();
}

/// Coordinates hadith session state, search, mode transitions, and selection.
@riverpod
class HadithSessionController extends _$HadithSessionController {
  static const _filtersDebounceDuration = Duration(milliseconds: 250);

  Timer? _filtersDebounce;
  String? _lastBootstrapSignature;
  int _searchGeneration = 0;

  @override
  HadithSessionState build() {
    ref.onDispose(_cancelDebounces);
    return const HadithSessionState();
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

  /// Commits the session search query and triggers a search when in search mode.
  Future<void> setQuery(String query) async {
    if (query == state.query) {
      if (state.isSearchMode) {
        await search();
      }
      return;
    }

    if (!state.isSearchMode) {
      await exitSpecificMode(restoreSearchSnapshot: false);
    }

    state = state.copyWith(query: query);
    await search();
  }

  /// Updates the session filters and optionally debounces a refresh.
  Future<void> setFilters(
    HadithFilters filters, {
    bool debounced = true,
  }) async {
    if (filters == state.filters) {
      if (!debounced && state.isSearchMode) {
        await search();
      }
      return;
    }

    state = state.copyWith(filters: filters);

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
  Future<void> search({bool reset = true}) async {
    final generation = ++_searchGeneration;
    final value = state.query.trim();

    if (value.isEmpty) {
      state = state.copyWith(
        query: '',
        page: 1,
        results: const <DetailedHadith>[],
        clearMetadata: true,
        clearError: true,
        isLoading: false,
        isLoadingMore: false,
      );
      return;
    }

    final targetPage = reset ? 1 : state.page;
    state = state.copyWith(
      query: value,
      page: targetPage,
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final repository = await ref.read(hadithRepositoryProvider.future);
      final response = await repository.searchDetailed(
        _toSearchParams(query: value, page: 1),
      );

      if (generation != _searchGeneration) return;

      state = state.copyWith(
        query: value,
        page: 1,
        results: response.data,
        metadata: response.metadata,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );

      ref.read(hadithRecentSearchesProvider.notifier).prepend(value);
      unawaited(
        ref.read(hadithRecentSearchesProvider.notifier).persistQuery(value),
      );
    } catch (e) {
      if (generation != _searchGeneration) return;
      state = state.copyWith(
        query: value,
        isLoading: false,
        isLoadingMore: false,
        error: '$e',
      );
    }
  }

  /// Fetches the next page of search results and appends them.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    final generation = _searchGeneration;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final repository = await ref.read(hadithRepositoryProvider.future);
      final response = await repository.searchDetailed(
        _toSearchParams(query: state.query, page: nextPage),
      );

      if (generation != _searchGeneration) return;

      state = state.copyWith(
        page: nextPage,
        results: [...state.results, ...response.data],
        metadata: response.metadata,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      if (generation != _searchGeneration) return;
      state = state.copyWith(isLoadingMore: false, error: '$e');
    }
  }

  /// Toggles a hadith between favorite and non-favorite state.
  Future<void> toggleFavorite(HadithBase hadith) async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.toggleFavorite(hadith);
    ref.invalidate(hadithFavoritesProvider);
  }

  /// Selects a hadith and optionally opens the details tab.
  Future<void> selectHadith(
    DetailedHadith hadith, {
    bool openDetailsTab = true,
  }) async {
    state = state.copyWith(selectedHadith: hadith);
    if (openDetailsTab) {
      ref
          .read(hadithScreenSettingsProvider.notifier)
          .setActiveTab(HadithPanelTab.details);
    }
  }

  /// Clears the current hadith selection.
  void clearSelection() {
    state = state.copyWith(clearSelectedHadith: true);
  }

  /// Moves the current selection by [delta] within the visible results list.
  Future<void> selectAdjacentResult(int delta) async {
    if (delta == 0) return;

    final results = hadithVisibleResultsList(ref, state);
    if (results == null || results.isEmpty) return;

    final current = state.selectedHadith;
    var index = current == null
        ? (delta > 0 ? 0 : results.length - 1)
        : results.indexWhere(
            (hadith) => hadithStableKey(hadith) == hadithStableKey(current),
          );

    if (index < 0) {
      index = delta > 0 ? 0 : results.length - 1;
    } else {
      index = (index + delta).clamp(0, results.length - 1);
    }

    final next = results[index];
    if (current != null &&
        hadithStableKey(next) == hadithStableKey(current)) {
      return;
    }

    await selectHadith(next);
  }

  /// Switches to bookmarks mode and selects the first favorite when possible.
  Future<void> openBookmarks() async {
    await _enterSpecificMode(mode: HadithViewMode.bookmarks);
    final favorites = await ref.read(hadithFavoritesProvider.future);

    if (state.mode != HadithViewMode.bookmarks) return;

    if (favorites.isEmpty) {
      clearSelection();
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
    state = HadithSessionState(
      query: snapshot?.query ?? '',
      filters: snapshot?.filters ?? const HadithFilters(),
    );

    await search();

    if ((snapshot?.query ?? '').trim().isEmpty) {
      clearSelection();
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
      filters: const HadithFilters(),
    );

    await search();
    ref
        .read(hadithScreenSettingsProvider.notifier)
        .setActiveTab(HadithPanelTab.details);

    final target = selected ?? (hadiths.isEmpty ? null : hadiths.first);
    if (target == null) {
      clearSelection();
      return;
    }

    await selectHadith(target, openDetailsTab: false);
  }

  HadithSearchSnapshot _captureSearchSnapshot() {
    return HadithSearchSnapshot(
      query: state.query,
      filters: state.filters,
    );
  }

  HadithSearchParams _toSearchParams({
    required String query,
    required int page,
  }) {
    final filters = state.filters;
    return HadithSearchParams(
      value: query,
      page: page,
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

  void _cancelDebounces() {
    _filtersDebounce?.cancel();
    _filtersDebounce = null;
  }
}

/// Returns the user's persisted recent-search queries.
@riverpod
class HadithRecentSearches extends _$HadithRecentSearches {
  static const _defaultLimit = 12;

  @override
  Future<List<String>> build() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    final entries = await repository.getRecentSearches();
    return entries.map((entry) => entry.query).toList(growable: false);
  }

  /// Optimistically prepends a query to the visible recents list.
  void prepend(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final current = state.asData?.value ?? const <String>[];
    final next = <String>[
      normalized,
      ...current.where((entry) => entry != normalized),
    ].take(_defaultLimit).toList(growable: false);
    state = AsyncData(next);
  }

  /// Persists a query through the repository.
  Future<void> persistQuery(String query) async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.addRecentSearch(query);
  }

  /// Optimistically removes one query and persists the change.
  Future<void> removeQuery(String query) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncData(
      current.where((entry) => entry != query).toList(growable: false),
    );
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.removeRecentSearch(query);
  }

  /// Optimistically clears recents and persists the change.
  Future<void> clearAll() async {
    state = const AsyncData(<String>[]);
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.clearRecentSearches();
  }
}

/// Searches lookup entries for hadith filter autocomplete.
@riverpod
Future<List<HadithLookupRef>> hadithLookup(
  Ref ref,
  HadithLookupKind kind,
  String query,
) async {
  final q = query.trim();
  if (q.length < 2) return const [];

  final repository = await ref.read(hadithRepositoryProvider.future);
  return switch (kind) {
    HadithLookupKind.scholars => (await repository.searchScholars(q))
        .map((item) => HadithLookupRef(id: item.id, name: item.name))
        .toList(growable: false),
    HadithLookupKind.books => (await repository.searchBooks(q))
        .data
        .map((item) => HadithLookupRef(id: item.id, name: item.name))
        .toList(growable: false),
    HadithLookupKind.rawi => (await repository.searchRawi(q))
        .map((item) => HadithLookupRef(id: item.id, name: item.name))
        .toList(growable: false),
  };
}

/// Kind of remote detail payload for a hadith accordion section.
enum HadithDetailKind {
  /// Sharh explanation by sharh id.
  sharh,

  /// Similar narrations by hadith id.
  similar,

  /// Alternate authentic narration by hadith id.
  alternate,

  /// Usul sources by hadith id.
  usul,
}

/// Loads a remote hadith detail payload for the accordion sections.
///
/// Auto-dispose family: disposes when the detail pane stops watching this key.
@riverpod
Future<Object?> hadithDetail(
  Ref ref,
  HadithDetailKind kind,
  String id,
) async {
  final client = await ref.watch(dorarClientProvider.future);
  return switch (kind) {
    HadithDetailKind.sharh => client.getSharhById(id),
    HadithDetailKind.similar => client.getSimilarHadith(id),
    HadithDetailKind.alternate => client.getAlternateHadith(id),
    HadithDetailKind.usul => (await client.getUsulHadith(id)).data,
  };
}
