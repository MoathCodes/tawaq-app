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

/// Mutable flow state for the hadith screen.
class HadithFlowState {
  /// Creates the flow state.
  const HadithFlowState({
    this.mode = HadithViewMode.search,
    this.specificHadiths = const <DetailedHadith>[],
    this.searchSnapshot,
    this.query = '',
  });

  /// The current screen mode.
  final HadithViewMode mode;

  /// The specific hadiths shown in specific-list mode.
  final List<DetailedHadith> specificHadiths;

  /// The search state saved before entering a specific mode.
  final HadithSearchSnapshot? searchSnapshot;

  /// The current session search query (not persisted).
  final String query;

  /// Whether the screen is currently in search mode.
  bool get isSearchMode => mode == HadithViewMode.search;

  /// Returns a copy with updated flow state values.
  HadithFlowState copyWith({
    HadithViewMode? mode,
    List<DetailedHadith>? specificHadiths,
    HadithSearchSnapshot? searchSnapshot,
    String? query,
    bool clearSnapshot = false,
  }) {
    return HadithFlowState(
      mode: mode ?? this.mode,
      specificHadiths: specificHadiths ?? this.specificHadiths,
      searchSnapshot: clearSnapshot
          ? null
          : searchSnapshot ?? this.searchSnapshot,
      query: query ?? this.query,
    );
  }
}
