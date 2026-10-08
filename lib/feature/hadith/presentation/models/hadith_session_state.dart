import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';

/// The independent search endpoints supported by the desk.
enum HadithSearchTarget { records, prose }

enum HadithRequestInterruption { collectionChanged }

enum HadithViewMode { search, bookmarks, topics, category }

sealed class HadithCollectionContext {
  const HadithCollectionContext();
}

class SearchCollection extends HadithCollectionContext {
  const SearchCollection();
}

class SavedCollection extends HadithCollectionContext {
  const SavedCollection();
}

class TopicsCollection extends HadithCollectionContext {
  const TopicsCollection();
}

/// Exact source selectors and labels for the current thematic branch.
class HadithTopicStep {
  const HadithTopicStep(this.selector, this.label);
  final CategorySelector selector;
  final String label;
}

class CategoryCollection extends HadithCollectionContext {
  const CategoryCollection(this.category, {this.specialist = false});
  final ThematicCategory category;
  final bool specialist;
}

/// One committed response, with endpoint-specific paging semantics.
sealed class HadithSearchPage {
  const HadithSearchPage._({this.page = 1, this.metadata});
  const factory HadithSearchPage({
    int page,
    List<DetailedHadith> results,
    SearchMetadata? metadata,
  }) = HadithRecordPage;
  const factory HadithSearchPage.prose({
    int page,
    required List<SharhSnippet> snippets,
    SearchMetadata? metadata,
  }) = HadithProsePage;
  static const empty = HadithRecordPage();
  final int page;
  final SearchMetadata? metadata;
  List<DetailedHadith> get results => const [];
  List<SharhSnippet> get snippets => const [];
  HadithSearchTarget get target => this is HadithProsePage
      ? HadithSearchTarget.prose
      : HadithSearchTarget.records;
  int? get reachablePages {
    final displayed =
        metadata?.pagination?.displayedTotalPages ?? metadata?.totalPages;
    if (displayed == null || displayed <= 0) return null;
    final cap = this is HadithRecordPage
        ? SearchCapabilities.detailed.pageLimit
        : null;
    return cap == null || displayed < cap ? displayed : cap;
  }

  bool get hasNextPage =>
      metadata?.pagination?.hasNextPage ??
      metadata?.hasNextPage ??
      (reachablePages != null && page < reachablePages!);
  bool get isEmpty => results.isEmpty && snippets.isEmpty;
}

class HadithRecordPage extends HadithSearchPage {
  const HadithRecordPage({
    super.page = 1,
    this.results = const [],
    super.metadata,
  }) : super._();
  @override
  final List<DetailedHadith> results;
}

class HadithCategoryPage extends HadithSearchPage {
  const HadithCategoryPage({
    super.page = 1,
    this.results = const [],
    super.metadata,
  }) : super._();
  @override
  final List<DetailedHadith> results;
}

class HadithProsePage extends HadithSearchPage {
  const HadithProsePage({
    super.page = 1,
    required this.snippets,
    super.metadata,
  }) : super._();
  @override
  final List<SharhSnippet> snippets;
}

sealed class HadithReaderSelection {
  const HadithReaderSelection();
  String get key;
}

/// Root selections refer to the loaded collection. Only drill-downs carry data.
class RecordSelection extends HadithReaderSelection {
  const RecordSelection(this.key, {this.related});
  @override
  final String key;
  final DetailedHadith? related;
}

class ProseSelection extends HadithReaderSelection {
  const ProseSelection(this.id);
  final SharhId id;
  @override
  String get key => 'prose:${id.value}';
}

class HadithReaderEntry {
  const HadithReaderEntry(this.selection, {this.section, this.offset = 0});
  final HadithReaderSelection selection;
  final String? section;
  final double offset;
}

/// Route session only; durable data has independent owners.
class HadithSessionState {
  const HadithSessionState({
    this.context = const SearchCollection(),
    this.target = HadithSearchTarget.records,
    this.query = '',
    this.topicPath = const [],
    this.filters = const HadithFilters(),
    this.committedPage,
    this.committedQuery,
    this.committedFilters,
    this.searchOutcome = const AsyncData(HadithSearchPage.empty),
    this.readerTrail = const [],
    this.origin,
    this.resultsOffset = 0,
    this.isPaginating = false,
    this.paginationError,
    this.paginationRequestedPage,
    this.emptyNextPage,
  });
  final HadithCollectionContext context;
  final HadithSearchTarget target;
  final String query;
  final List<HadithTopicStep> topicPath;
  final HadithFilters filters;
  final HadithSearchPage? committedPage;
  final String? committedQuery;
  final HadithFilters? committedFilters;
  bool get supportsFilters =>
      context is SearchCollection && target == HadithSearchTarget.records;
  final AsyncValue<HadithSearchPage> searchOutcome;
  final List<HadithReaderEntry> readerTrail;
  final HadithSessionState? origin;
  final double resultsOffset;
  final bool isPaginating;
  final Object? paginationError;
  final int? paginationRequestedPage;
  final int? emptyNextPage;
  HadithReaderEntry? get reader => readerTrail.lastOrNull;
  String? get selectedHadithKey => switch (readerTrail.firstOrNull?.selection) {
    RecordSelection(:final key) => key,
    _ => null,
  };
  String? get selectedSharhId => switch (reader?.selection) {
    ProseSelection(:final id) => id.value,
    _ => null,
  };
  HadithViewMode get mode => switch (context) {
    SearchCollection() => HadithViewMode.search,
    SavedCollection() => HadithViewMode.bookmarks,
    TopicsCollection() => HadithViewMode.topics,
    CategoryCollection() => HadithViewMode.category,
  };
  bool get isSearchMode => context is SearchCollection;
  bool get searchBusy => searchOutcome.isLoading || isPaginating;
  HadithSearchPage? get searchPage =>
      searchOutcome.asData?.value ?? committedPage;
  List<DetailedHadith> get results => searchPage?.results ?? const [];
  int get page => searchPage?.page ?? 1;
  SearchMetadata? get metadata => searchPage?.metadata;
  bool get canGoNext =>
      searchPage?.hasNextPage == true &&
      emptyNextPage != page + 1 &&
      (searchPage is! HadithRecordPage ||
          page < SearchCapabilities.detailed.pageLimit!) &&
      (searchPage?.reachablePages == null ||
          page < searchPage!.reachablePages!);
  String? get hardSearchError => searchOutcome.hasError && searchPage == null
      ? '${searchOutcome.error}'
      : null;

  HadithSessionState copyWith({
    HadithCollectionContext? context,
    HadithSearchTarget? target,
    String? query,
    List<HadithTopicStep>? topicPath,
    HadithFilters? filters,
    HadithSearchPage? committedPage,
    bool clearCommittedPage = false,
    String? committedQuery,
    HadithFilters? committedFilters,
    AsyncValue<HadithSearchPage>? searchOutcome,
    List<HadithReaderEntry>? readerTrail,
    HadithSessionState? origin,
    bool clearOrigin = false,
    double? resultsOffset,
    bool? isPaginating,
    Object? paginationError,
    int? paginationRequestedPage,
    bool clearPaginationError = false,
    int? emptyNextPage,
    bool clearEmptyNextPage = false,
  }) => HadithSessionState(
    context: context ?? this.context,
    target: target ?? this.target,
    query: query ?? this.query,
    topicPath: topicPath ?? this.topicPath,
    filters: filters ?? this.filters,
    committedPage: clearCommittedPage
        ? null
        : committedPage ?? this.committedPage,
    committedQuery: committedQuery ?? this.committedQuery,
    committedFilters: committedFilters ?? this.committedFilters,
    searchOutcome: searchOutcome ?? this.searchOutcome,
    readerTrail: readerTrail ?? this.readerTrail,
    origin: clearOrigin ? null : origin ?? this.origin,
    resultsOffset: resultsOffset ?? this.resultsOffset,
    isPaginating: isPaginating ?? this.isPaginating,
    paginationRequestedPage:
        paginationRequestedPage ?? this.paginationRequestedPage,
    paginationError: clearPaginationError
        ? null
        : paginationError ?? this.paginationError,
    emptyNextPage: clearEmptyNextPage
        ? null
        : emptyNextPage ?? this.emptyNextPage,
  );
}
