import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// One loaded search page (results + Dorar pagination metadata).
class HadithSearchPage {
  /// Creates a search page.
  const HadithSearchPage({
    this.page = 1,
    this.results = const <DetailedHadith>[],
    this.metadata,
  });

  /// Empty page used for idle / cleared queries.
  static const empty = HadithSearchPage();

  /// Current search results page (1-based, Dorar convention).
  final int page;

  /// Loaded search results for this page.
  final List<DetailedHadith> results;

  /// Pagination metadata from the last successful response.
  final SearchMetadata? metadata;

  /// Total pages from metadata (0 when unknown).
  int get totalPages => metadata?.totalPages ?? 0;

  /// Returns a copy with updated page fields.
  HadithSearchPage copyWith({
    int? page,
    List<DetailedHadith>? results,
    SearchMetadata? metadata,
    bool clearMetadata = false,
  }) {
    return HadithSearchPage(
      page: page ?? this.page,
      results: results ?? this.results,
      metadata: clearMetadata ? null : metadata ?? this.metadata,
    );
  }
}

/// In-memory session state for the hadith screen.
///
/// Search results live in [searchOutcome] as a single [AsyncValue] so loading /
/// data / error cannot diverge.
///
/// **Pagination rule:** `goToPage` failures keep the prior [AsyncData] page
/// (no error transition — list stays). New-query `search()` failures are hard
/// [AsyncError]s with no retained list.
class HadithSessionState {
  /// Creates the session state.
  const HadithSessionState({
    this.mode = HadithViewMode.search,
    this.specificHadiths = const <DetailedHadith>[],
    this.searchSnapshot,
    this.query = '',
    this.filters = const HadithFilters(),
    this.selectedHadith,
    this.searchOutcome = const AsyncData(HadithSearchPage.empty),
    this.isPaginating = false,
    this.paginationError,
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

  /// Async search outcome for the current query.
  final AsyncValue<HadithSearchPage> searchOutcome;

  /// True while a page-change request is in flight (prior page still shown).
  final bool isPaginating;

  /// Soft pagination failure message (prior page retained). Cleared on success.
  final String? paginationError;

  /// Whether the screen is currently in search mode.
  bool get isSearchMode => mode == HadithViewMode.search;

  /// Whether a search or pagination request is in flight.
  bool get searchBusy => searchOutcome.isLoading || isPaginating;

  /// Alias for [searchBusy] (legacy call sites / tests).
  bool get isLoading => searchBusy;

  /// Last known page when the outcome still carries a value.
  HadithSearchPage? get searchPage => searchOutcome.value;

  /// Results from the retained search page, if any.
  List<DetailedHadith> get results =>
      searchPage?.results ?? const <DetailedHadith>[];

  /// Current page number (1 when unknown).
  int get page => searchPage?.page ?? 1;

  /// Total pages from the last retained response (0 when unknown).
  int get totalPages => searchPage?.totalPages ?? 0;

  /// Metadata from the last retained response.
  SearchMetadata? get metadata => searchPage?.metadata;

  /// Hard new-query error message (null when a prior page is still retained).
  String? get hardSearchError {
    final outcome = searchOutcome;
    if (!outcome.hasError || outcome.hasValue) return null;
    return '${outcome.error}';
  }

  /// Alias for [hardSearchError] (legacy call sites / tests).
  String? get error => hardSearchError;

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
    AsyncValue<HadithSearchPage>? searchOutcome,
    bool? isPaginating,
    String? paginationError,
    bool clearPaginationError = false,
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
      searchOutcome: searchOutcome ?? this.searchOutcome,
      isPaginating: isPaginating ?? this.isPaginating,
      paginationError: clearPaginationError
          ? null
          : paginationError ?? this.paginationError,
    );
  }
}
