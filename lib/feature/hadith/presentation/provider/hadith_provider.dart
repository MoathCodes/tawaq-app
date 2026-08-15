import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';

part 'hadith_provider.g.dart';

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

DetailedHadith? _selectedFromVisible(Ref ref, HadithSessionState session) {
  final key = session.selectedHadithKey;
  if (key == null) return null;
  return hadithVisibleResultsList(
    ref,
    session,
  )?.where((hadith) => hadithStableKey(hadith) == key).firstOrNull;
}

/// Selected object derived from its stable key and the visible collection.
@riverpod
DetailedHadith? selectedHadith(Ref ref) {
  final session = ref.watch(hadithSessionControllerProvider);
  if (session.mode == HadithViewMode.bookmarks) {
    ref.watch(hadithFavoritesProvider);
  }
  return _selectedFromVisible(ref, session);
}

/// The only writable runtime authority for persisted Hadith favorites.
@Riverpod(keepAlive: true)
class HadithFavoritesStore extends _$HadithFavoritesStore {
  @override
  Future<Map<String, DetailedHadith>> build() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    final favorites = await repository.getFavorites();
    return Map.unmodifiable({
      for (final hadith in favorites) hadithStableKey(hadith): hadith,
    });
  }

  /// Toggles [hadith] on disk, then atomically publishes the stored snapshot.
  Future<void> toggle(HadithBase hadith) async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.toggleFavorite(hadith);
    final favorites = await repository.getFavorites();
    if (!ref.mounted) return;
    state = AsyncData(
      Map.unmodifiable({
        for (final favorite in favorites) hadithStableKey(favorite): favorite,
      }),
    );
  }
}

/// Ordered view of the canonical favorites store.
@riverpod
Future<List<DetailedHadith>> hadithFavorites(Ref ref) async {
  final favorites = await ref.watch(hadithFavoritesStoreProvider.future);
  return List.unmodifiable(favorites.values);
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
  ///
  /// Query commits are ignored outside search mode so bookmarks / specific-list
  /// snapshots are not destroyed by accidental field commits.
  Future<void> setQuery(String query) async {
    if (!state.isSearchMode) {
      return;
    }

    if (query == state.query) {
      await search();
      return;
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

  /// Triggers a search using the current query and filters (always page 1).
  ///
  /// New-query failures are **hard** [AsyncError]s — prior page data is not
  /// retained (see [HadithSessionState] pagination rule for `goToPage`).
  Future<void> search() async {
    final generation = ++_searchGeneration;
    final value = state.query.trim();

    if (value.isEmpty) {
      state = state.copyWith(
        query: '',
        isPaginating: false,
        clearPaginationError: true,
        searchOutcome: const AsyncData(HadithSearchPage.empty),
      );
      return;
    }

    // Hard loading: drop any prior page so a failure cannot show a stale list.
    state = state.copyWith(
      query: value,
      isPaginating: false,
      clearPaginationError: true,
      searchOutcome: const AsyncLoading(),
    );

    try {
      final repository = await ref.read(hadithRepositoryProvider.future);
      final response = await repository.searchDetailed(
        _toSearchParams(query: value, page: 1),
      );

      if (!ref.mounted || generation != _searchGeneration) return;

      state = state.copyWith(
        query: value,
        searchOutcome: AsyncData(
          HadithSearchPage(
            results: response.data,
            metadata: response.metadata,
          ),
        ),
      );

      unawaited(
        ref.read(hadithRecentSearchesStoreProvider.notifier).add(value),
      );
    } catch (e, stackTrace) {
      if (!ref.mounted || generation != _searchGeneration) return;
      state = state.copyWith(
        query: value,
        searchOutcome: AsyncError(e, stackTrace),
      );
    }
  }

  /// Fetches [page] (1-based) and replaces the current results.
  ///
  /// **Pagination rule:** on failure, keep the prior [AsyncData] page (no
  /// error transition). Empty out-of-range pages clamp metadata without
  /// blanking the list. `isPaginating` drives the in-flight indicator while
  /// the prior page remains visible.
  Future<void> goToPage(int page) async {
    final value = state.query.trim();
    final totalPages = state.totalPages;
    if (state.isLoading ||
        value.isEmpty ||
        page == state.page ||
        page < 1 ||
        (totalPages > 0 && page > totalPages)) {
      return;
    }

    final generation = _searchGeneration;
    final previousPage = state.searchPage;
    state = state.copyWith(isPaginating: true, clearPaginationError: true);

    try {
      final repository = await ref.read(hadithRepositoryProvider.future);
      final response = await repository.searchDetailed(
        _toSearchParams(query: value, page: page),
      );

      if (!ref.mounted || generation != _searchGeneration) return;

      // Past Dorar's served range (or stale inflated totalPages) — don't blank
      // the list; clamp the pager to the last known good page.
      if (response.data.isEmpty && page > 1) {
        if (previousPage == null) {
          state = state.copyWith(
            isPaginating: false,
            searchOutcome: const AsyncData(HadithSearchPage.empty),
            clearPaginationError: true,
          );
          return;
        }
        state = state.copyWith(
          isPaginating: false,
          clearPaginationError: true,
          searchOutcome: AsyncData(
            previousPage.copyWith(
              metadata: previousPage.metadata?.copyWith(
                totalPages: previousPage.page,
                hasNextPage: false,
                page: previousPage.page,
              ),
            ),
          ),
        );
        return;
      }

      final selectedKey = state.selectedHadithKey;
      final keepSelection =
          selectedKey != null &&
          response.data.any(
            (hadith) => hadithStableKey(hadith) == selectedKey,
          );

      state = state.copyWith(
        isPaginating: false,
        clearPaginationError: true,
        searchOutcome: AsyncData(
          HadithSearchPage(
            page: page,
            results: response.data,
            metadata: response.metadata,
          ),
        ),
        clearSelectedHadith: !keepSelection,
      );
    } catch (error) {
      if (!ref.mounted || generation != _searchGeneration) return;
      // Soft: keep prior AsyncData; surface a recoverable pagination error.
      state = state.copyWith(
        isPaginating: false,
        paginationError: '$error',
      );
    }
  }

  /// Toggles a hadith between favorite and non-favorite state.
  ///
  /// Propagates repository failures so callers can surface a toast.
  Future<void> toggleFavorite(HadithBase hadith) async {
    final key = hadithStableKey(hadith);
    final wasFavorite =
        ref.read(hadithFavoritesStoreProvider).value?.containsKey(key) ?? false;
    await ref.read(hadithFavoritesStoreProvider.notifier).toggle(hadith);
    if (!ref.mounted) return;

    if (!wasFavorite || state.mode != HadithViewMode.bookmarks) {
      return;
    }

    if (state.selectedHadithKey != key) {
      return;
    }

    final favorites = await ref.read(hadithFavoritesProvider.future);
    if (!ref.mounted || state.mode != HadithViewMode.bookmarks) return;

    if (favorites.isEmpty) {
      clearSelection();
      return;
    }

    await selectHadith(favorites.first);
  }

  /// Selects a hadith and optionally opens the details tab.
  Future<void> selectHadith(
    DetailedHadith hadith, {
    bool openDetailsTab = true,
  }) async {
    state = state.copyWith(selectedHadithKey: hadithStableKey(hadith));
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

    final current = _selectedFromVisible(ref, state);
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
    if (current != null && hadithStableKey(next) == hadithStableKey(current)) {
      return;
    }

    await selectHadith(next);
  }

  /// Switches to bookmarks mode and selects the first favorite when possible.
  Future<void> openBookmarks() async {
    await _enterSpecificMode(mode: HadithViewMode.bookmarks);
    if (!ref.mounted) return;
    final favorites = await ref.read(hadithFavoritesProvider.future);
    if (!ref.mounted || state.mode != HadithViewMode.bookmarks) return;

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
    if (!ref.mounted) return;

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
    if (!ref.mounted) return;
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
@Riverpod(keepAlive: true)
class HadithRecentSearchesStore extends _$HadithRecentSearchesStore {
  static const _defaultLimit = 12;
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<List<String>> build() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    final entries = await repository.getRecentSearches();
    return entries.map((entry) => entry.query).toList(growable: false);
  }

  /// Persists and then publishes a recent query.
  Future<void> add(String query) => _serialize(() async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.addRecentSearch(normalized);
    await _reload(repository);
  });

  /// Removes one query on disk before publishing the new list.
  Future<void> removeQuery(String query) => _serialize(() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.removeRecentSearch(query);
    await _reload(repository);
  });

  /// Clears storage before publishing the empty list.
  Future<void> clearAll() => _serialize(() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.clearRecentSearches();
    if (!ref.mounted) return;
    state = const AsyncData(<String>[]);
  });

  Future<void> _reload(HadithRepository repository) async {
    final entries = await repository.getRecentSearches();
    if (!ref.mounted) return;
    state = AsyncData(
      entries
          .map((entry) => entry.query)
          .take(_defaultLimit)
          .toList(growable: false),
    );
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
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
    HadithLookupKind.scholars =>
      (await repository.searchScholars(q))
          .map((item) => HadithLookupRef(id: item.id, name: item.name))
          .toList(growable: false),
    HadithLookupKind.books =>
      (await repository.searchBooks(q)).data
          .map((item) => HadithLookupRef(id: item.id, name: item.name))
          .toList(growable: false),
    HadithLookupKind.rawi =>
      (await repository.searchRawi(q))
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
