import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';

/// The available high-level views in the hadith screen.
enum HadithViewMode {
  /// Search results mode.
  search,

  /// Bookmarked hadiths mode.
  bookmarks,

  /// Specific list mode.
  specificList,
}

/// Snapshot of a hadith search query and its active filters.
class HadithSearchSnapshot {
  /// Creates a search snapshot.
  const HadithSearchSnapshot({required this.query, required this.filters});

  /// The saved query text.
  final String query;

  /// The saved search filters.
  final HadithFilters filters;
}

/// In-memory session state for the hadith screen.
class HadithSessionState {
  /// Creates the session state.
  const HadithSessionState({
    this.mode = HadithViewMode.search,
    this.specificHadiths = const <DetailedHadith>[],
    this.searchSnapshot,
    this.query = '',
    this.filters = const HadithFilters(),
    this.selectedHadith,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.metadata,
    this.results = const <DetailedHadith>[],
  });

  /// The current screen mode.
  final HadithViewMode mode;

  /// The specific hadiths shown in specific-list mode.
  final List<DetailedHadith> specificHadiths;

  /// The search state saved before entering a specific mode.
  final HadithSearchSnapshot? searchSnapshot;

  /// The committed session search query (not persisted).
  final String query;

  /// Active search filters (session-only).
  final HadithFilters filters;

  /// Currently selected hadith for the detail pane.
  final DetailedHadith? selectedHadith;

  /// Current search results page.
  final int page;

  /// Whether the initial search request is in flight.
  final bool isLoading;

  /// Whether a pagination request is in flight.
  final bool isLoadingMore;

  /// Last search error message, if any.
  final String? error;

  /// Pagination metadata from the last search response.
  final SearchMetadata? metadata;

  /// Loaded search results for the current query.
  final List<DetailedHadith> results;

  /// Whether the screen is currently in search mode.
  bool get isSearchMode => mode == HadithViewMode.search;

  /// Whether a search or pagination request is in flight.
  bool get searchBusy => isLoading || isLoadingMore;

  /// Whether another page of results is available.
  bool get hasNextPage => metadata?.hasNextPage ?? false;

  /// Whether filter chips and panel controls accept input.
  bool get filterInteractionsEnabled =>
      !searchBusy && isSearchMode && query.trim().isNotEmpty;

  /// Returns a copy with updated session values.
  HadithSessionState copyWith({
    HadithViewMode? mode,
    List<DetailedHadith>? specificHadiths,
    HadithSearchSnapshot? searchSnapshot,
    String? query,
    HadithFilters? filters,
    DetailedHadith? selectedHadith,
    bool clearSelectedHadith = false,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    SearchMetadata? metadata,
    bool clearMetadata = false,
    List<DetailedHadith>? results,
    bool clearSnapshot = false,
  }) {
    return HadithSessionState(
      mode: mode ?? this.mode,
      specificHadiths: specificHadiths ?? this.specificHadiths,
      searchSnapshot: clearSnapshot
          ? null
          : searchSnapshot ?? this.searchSnapshot,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      selectedHadith: clearSelectedHadith
          ? null
          : selectedHadith ?? this.selectedHadith,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      metadata: clearMetadata ? null : metadata ?? this.metadata,
      results: results ?? this.results,
    );
  }
}
