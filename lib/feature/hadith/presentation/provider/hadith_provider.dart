import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_local_provider.dart';
export 'package:tawaq/feature/hadith/presentation/provider/hadith_local_provider.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';

part 'hadith_provider.g.dart';

/// Selected record derived from the current collection or a reader drill-down.
@riverpod
DetailedHadith? selectedHadith(Ref ref) {
  ref.watch(
    hadithSessionControllerProvider.select(
      (s) => (s.context, s.reader?.selection, s.results),
    ),
  );
  final session = ref.read(hadithSessionControllerProvider);
  final selection = session.reader?.selection;
  if (selection is! RecordSelection) return null;
  if (selection.related != null) return selection.related;
  if (session.context is SavedCollection) {
    return ref
        .watch(hadithFavoritesStoreProvider)
        .value?[selection.key]
        ?.hadith;
  }
  final records = session.context is SavedCollection
      ? ref.watch(hadithFavoritesProvider).value
      : session.results;
  return records?.where((r) => hadithStableKey(r) == selection.key).firstOrNull;
}

/// Owns requests, committed pages and reader navigation, never durable storage.
@riverpod
class HadithSessionController extends _$HadithSessionController {
  Timer? _filtersDebounce;
  int _generation = 0;
  @override
  HadithSessionState build() {
    ref.onDispose(_cancel);
    return const HadithSessionState();
  }

  void retryInitialization() => retryFailedHadithInitialization(ref);
  void _cancel() {
    _filtersDebounce?.cancel();
    _filtersDebounce = null;
  }

  void _invalidate() {
    _cancel();
    ++_generation;
  }

  /// Opens the study desk and cancels requests while preserving filter drafts.
  void openSearchHome() {
    _invalidate();
    state = HadithSessionState(
      context: const SearchCollection(home: true),
      filters: state.filters,
    );
  }

  void returnToSearch() {
    if (state.isSearchMode) return;
    returnToWorkspace();
    if (!state.isSearchMode)
      state = HadithSessionState(filters: state.filters, target: state.target);
  }

  Future<void> setQuery(String query) async {
    _invalidate();
    state = state.copyWith(
      context: const SearchCollection(),
      query: query.trim(),
      topicPath: const [],
      clearOrigin: true,
      readerTrail: const [],
      resultsOffset: 0,
    );
    await search();
  }

  Future<void> setFilters(
    HadithFilters filters, {
    bool debounced = true,
  }) async {
    if (filters == state.filters && debounced) return;
    if (!state.isSearchMode || state.target == HadithSearchTarget.prose) {
      state = state.copyWith(filters: filters);
      return;
    }
    _invalidate();
    state = state.copyWith(filters: filters);
    state = state.copyWith(
      clearEmptyNextPage: true,
      committedPage: state.searchPage,
      clearCommittedPage: state.searchPage?.isEmpty != false,
      searchOutcome: const AsyncLoading<HadithSearchPage>(),
      isPaginating: false,
    );
    if (!debounced) {
      await search();
      return;
    }
    _filtersDebounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(search()),
    );
  }

  Future<void> clearFilters() =>
      setFilters(const HadithFilters(), debounced: false);
  Future<void> setTarget(HadithSearchTarget target) async {
    if (target == state.target && state.isSearchMode) return;
    _invalidate();
    state = state.copyWith(
      context: const SearchCollection(),
      target: target,
      clearOrigin: true,
      readerTrail: const [],
      resultsOffset: 0,
    );
    await search();
  }

  Future<HadithSearchPage> _fetch(HadithSessionState request, int page) async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    if (!ref.mounted) throw StateError('Session disposed');
    if (request.context case CategoryCollection(
      :final category,
      :final specialist,
    )) {
      final response = await repository.browseCategory(
        CategoryBrowseParams(
          categoryId: CategoryId(category.id),
          page: page,
          specialist: specialist,
        ),
      );
      return HadithCategoryPage(
        page: page,
        results: response.data,
        metadata: response.metadata,
      );
    }
    if (request.target == HadithSearchTarget.prose) {
      final response = await repository.searchProse(
        SharhTextSearchParams(value: request.query, page: page),
      );
      return HadithSearchPage.prose(
        page: page,
        snippets: response.data,
        metadata: response.metadata,
      );
    }
    final f = request.filters;
    final response = await repository.searchDetailed(
      HadithSearchParams(
        value: request.query,
        page: page,
        specialist: f.specialist,
        exclude: f.exclude.trim().isEmpty ? null : f.exclude,
        optionalPhrases: f.optionalPhrases
            .where((p) => p.trim().isNotEmpty)
            .toList(),
        sort: f.sort,
        searchMethod: f.searchMethod,
        types: f.types,
        degrees: f.degrees.isEmpty ? null : f.degrees,
        scholarIds: f.scholars.map((e) => ScholarId(e.id)).toList(),
        bookIds: f.books.map((e) => BookId(e.id)).toList(),
        narratorChoiceIds: f.rawi.map((e) => NarratorChoiceId(e.id)).toList(),
      ),
    );
    return HadithSearchPage(
      page: page,
      results: response.data,
      metadata: response.metadata,
    );
  }

  Future<void> search() async {
    _invalidate();
    final generation = _generation;
    if (state.context is SavedCollection || state.context is TopicsCollection)
      return;
    final request = state.copyWith(
      context: state.isSearchMode ? const SearchCollection() : state.context,
      query: state.query.trim(),
    );
    final refinement =
        (state.committedQuery == null ||
            state.committedQuery == request.query) &&
        (state.searchPage == null ||
            state.searchPage!.target == request.target);
    final hasPhrase =
        request.target == HadithSearchTarget.records &&
        request.filters.optionalPhrases.any((p) => p.trim().isNotEmpty);
    if (request.context is SearchCollection &&
        request.query.isEmpty &&
        !hasPhrase) {
      state = request.copyWith(
        searchOutcome: const AsyncData(HadithSearchPage.empty),
        readerTrail: const [],
        clearEmptyNextPage: true,
        isPaginating: false,
        clearPaginationError: true,
      );
      return;
    }
    state = request.copyWith(
      committedPage: refinement ? state.searchPage : null,
      clearCommittedPage: !refinement || state.searchPage?.isEmpty != false,
      searchOutcome: const AsyncLoading<HadithSearchPage>(),
      clearEmptyNextPage: true,
      isPaginating: false,
      clearPaginationError: true,
    );
    retryInitialization();
    try {
      final page = await _fetch(request, 1);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        committedPage: page,
        searchOutcome: AsyncData(page),
        committedQuery: request.query,
        committedFilters: request.filters,
        resultsOffset: 0,
      );
      if (request.context is SearchCollection && request.query.isNotEmpty) {
        // A local recents failure must not turn a successful search into an error.
        unawaited(
          ref
              .read(hadithRecentSearchesStoreProvider.notifier)
              .add(request.query)
              .catchError((Object _) {}),
        );
      }
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          searchOutcome: AsyncError<HadithSearchPage>(error, stack),
        );
      }
    }
  }

  Future<void> goToPage(int page) async {
    final current = state.searchPage;
    if (state.searchBusy ||
        current == null ||
        page == current.page ||
        page < 1 ||
        (current.reachablePages != null && page > current.reachablePages!) ||
        (current is HadithRecordPage &&
            page > SearchCapabilities.detailed.pageLimit!) ||
        state.emptyNextPage == page ||
        state.context is SavedCollection ||
        state.context is TopicsCollection)
      return;
    _invalidate();
    final generation = _generation;
    final request = state.copyWith(
      query: state.committedQuery,
      filters: state.committedFilters,
    );
    state = state.copyWith(
      isPaginating: true,
      paginationRequestedPage: page,
      clearPaginationError: true,
    );
    retryInitialization();
    try {
      final response = await _fetch(request, page);
      if (!ref.mounted || generation != _generation) return;
      if (response.isEmpty && page > current.page) {
        state = state.copyWith(isPaginating: false, emptyNextPage: page);
        return;
      }
      state = state.copyWith(
        searchOutcome: AsyncData(response),
        isPaginating: false,
        readerTrail: const [],
        resultsOffset: 0,
        clearPaginationError: true,
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(isPaginating: false, paginationError: error);
      }
    }
  }

  void _enter(HadithCollectionContext context) {
    _invalidate();
    final origin =
        state.origin ??
        state.copyWith(
          clearOrigin: true,
          isPaginating: false,
          clearPaginationError: true,
        );
    final suspended =
        origin.searchOutcome.isLoading && !origin.searchOutcome.hasValue
        ? origin.copyWith(
            searchOutcome: AsyncError(
              HadithRequestInterruption.collectionChanged,
              StackTrace.empty,
            ),
          )
        : origin;
    state = state.copyWith(
      context: context,
      origin: suspended,
      readerTrail: const [],
      resultsOffset: 0,
      isPaginating: false,
      searchOutcome: const AsyncData(HadithSearchPage.empty),
      clearCommittedPage: true,
      clearPaginationError: true,
      clearEmptyNextPage: true,
    );
  }

  Future<void> openBookmarks() async {
    _enter(const SavedCollection());
  }

  void openTopics() {
    _enter(const TopicsCollection());
    state = state.copyWith(topicPath: const []);
  }

  void navigateTopics(List<HadithTopicStep> path) {
    if (state.context is! TopicsCollection) _enter(const TopicsCollection());
    state = state.copyWith(topicPath: List.unmodifiable(path));
  }

  Future<void> openCategory(ThematicCategory category) async {
    final path = state.context is TopicsCollection
        ? state.topicPath
        : const <HadithTopicStep>[];
    _enter(CategoryCollection(category));
    state = state.copyWith(topicPath: path);
    await search();
  }

  void returnToReader(int index) {
    if (index < 0 || index >= state.readerTrail.length) return;
    state = state.copyWith(
      readerTrail: state.readerTrail.take(index + 1).toList(),
    );
  }

  Future<void> setCategorySpecialist(bool specialist) async {
    if (state.context case CategoryCollection(:final category)) {
      state = state.copyWith(
        context: CategoryCollection(category, specialist: specialist),
      );
      await search();
    }
  }

  void returnToWorkspace() {
    _invalidate();
    state =
        state.origin ??
        HadithSessionState(filters: state.filters, target: state.target);
  }

  void selectSavedEntry(String key) {
    state = state.copyWith(
      readerTrail: [HadithReaderEntry(RecordSelection(key))],
    );
  }

  Future<void> removeSavedEntry(String key) async {
    await ref.read(hadithFavoritesStoreProvider.notifier).remove(key);
    if (ref.mounted &&
        state.context is SavedCollection &&
        state.selectedHadithKey == key)
      clearSelection();
  }

  Future<void> selectHadith(DetailedHadith hadith) async {
    state = state.copyWith(
      readerTrail: [
        HadithReaderEntry(
          RecordSelection(hadithStableKey(hadith), related: hadith),
        ),
      ],
    );
  }

  void selectSharh(SharhSnippet snippet) {
    state = state.copyWith(
      readerTrail: [HadithReaderEntry(ProseSelection(SharhId(snippet.id)))],
    );
  }

  void pushReader(DetailedHadith hadith) {
    state = state.copyWith(
      readerTrail: [
        ...state.readerTrail,
        HadithReaderEntry(
          RecordSelection(hadithStableKey(hadith), related: hadith),
        ),
      ],
    );
  }

  void readerBack() {
    if (state.readerTrail.isEmpty) return;
    state = state.copyWith(
      readerTrail: state.readerTrail
          .take(state.readerTrail.length - 1)
          .toList(),
    );
  }

  void clearSelection() => state = state.copyWith(readerTrail: const []);
  void setReaderPosition({String? section, double? offset}) {
    final current = state.reader;
    if (current == null) return;
    state = state.copyWith(
      readerTrail: [
        ...state.readerTrail.take(state.readerTrail.length - 1),
        HadithReaderEntry(
          current.selection,
          section: section ?? current.section,
          offset: offset ?? current.offset,
        ),
      ],
    );
  }

  void setResultsOffset(double offset) =>
      state = state.copyWith(resultsOffset: offset);
  Future<void> selectAdjacentResult(int delta) async {
    if (delta == 0) return;
    if (state.searchPage case HadithProsePage(:final snippets)) {
      if (snippets.isEmpty) return;
      final index = snippets.indexWhere((s) => s.id == state.selectedSharhId);
      selectSharh(
        snippets[index < 0
            ? (delta > 0 ? 0 : snippets.length - 1)
            : (index + delta).clamp(0, snippets.length - 1)],
      );
      return;
    }
    if (state.context is SavedCollection) {
      final entries =
          ref
              .read(hadithFavoritesStoreProvider)
              .value
              ?.values
              .where((e) => e.hadith != null)
              .toList() ??
          [];
      if (entries.isEmpty) return;
      final current = entries.indexWhere(
        (e) => e.key == state.selectedHadithKey,
      );
      final next = current < 0
          ? (delta > 0 ? 0 : entries.length - 1)
          : (current + delta).clamp(0, entries.length - 1);
      selectSavedEntry(entries[next].key);
      return;
    }
    final results = state.results;
    if (results.isEmpty) return;
    final index = results.indexWhere(
      (r) => hadithStableKey(r) == state.selectedHadithKey,
    );
    await selectHadith(
      results[index < 0
          ? (delta > 0 ? 0 : results.length - 1)
          : (index + delta).clamp(0, results.length - 1)],
    );
  }

  Future<void> toggleFavorite(DetailedHadith hadith) async {
    final selection = state.reader?.selection;
    if (state.context is SavedCollection &&
        selection is RecordSelection &&
        state.readerTrail.length == 1) {
      final key = selection.key;
      final entry = ref.read(hadithFavoritesStoreProvider).value?[key];
      if (entry?.hadith != null &&
          hadithStableKey(entry!.hadith!) == hadithStableKey(hadith)) {
        await removeSavedEntry(key);
        return;
      }
    }
    await ref.read(hadithFavoritesStoreProvider.notifier).toggle(hadith);
  }
}

/// Searches lookup entries for hadith filter autocomplete.
@riverpod
Future<List<ReferenceChoice>> hadithLookup(
  Ref ref,
  HadithLookupKind kind,
  String query,
) async {
  final q = query.trim();
  if (q.length < 2) return const [];

  final repository = await ref.read(hadithRepositoryProvider.future);
  return switch (kind) {
    HadithLookupKind.scholars => repository.searchScholars(q),
    HadithLookupKind.books => repository.searchBooks(q),
    HadithLookupKind.rawi => repository.searchRawi(q),
  };
}

/// Loads an explanation without discarding its provenance.
@riverpod
Future<Sharh> hadithSharh(Ref ref, SharhId id) async {
  final client = await ref.watch(dorarClientProvider.future);
  return client.getSharhById(id.value);
}

/// Loads source documents and retains the SDK response diagnostics.
@riverpod
Future<ApiResponse<UsulHadith>> hadithUsul(Ref ref, HadithRecordId id) async {
  final client = await ref.watch(dorarClientProvider.future);
  return client.getUsulHadith(id.value);
}

/// Loads the complete ordered collection, with its independent seed context.
@riverpod
Future<ApiResponse<RelatedHadithResult>> hadithRelated(
  Ref ref,
  HadithRecordId id,
  RelatedHadithKind kind,
) async {
  final client = await ref.watch(dorarClientProvider.future);
  return switch (kind) {
    RelatedHadithKind.alternate => client.getAlternates(id.value),
    RelatedHadithKind.similar => client.getSimilarResult(id.value),
  };
}

@riverpod
Future<ApiResponse<AsbabResult>> hadithAsbab(
  Ref ref,
  HadithRecordId id,
) async => (await ref.watch(dorarClientProvider.future)).getAsbab(id.value);
@riverpod
Future<ApiResponse<List<ThematicRoot>>> hadithTopicRoots(Ref ref) async =>
    (await ref.watch(dorarClientProvider.future)).categories.getRoots();
@riverpod
Future<ApiResponse<List<ThematicCategory>>> hadithTopicChildren(
  Ref ref,
  CategorySelector parent,
) async =>
    (await ref.watch(dorarClientProvider.future)).categories
        .getChildren(parent);
@riverpod
Future<ApiResponse<List<ThematicCategory>>> hadithTopicSearch(
  Ref ref,
  String query,
) async =>
    (await ref.watch(dorarClientProvider.future)).categories.search(query);
