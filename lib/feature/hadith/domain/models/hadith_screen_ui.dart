import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';

/// Read-only snapshot of Hadith screen UI state for presentation widgets.
///
/// Built by `hadithScreenUiProvider` from session, persisted settings, and
/// favorites. Mutations go through `hadithSessionControllerProvider`.
class HadithScreenUi {
  /// Creates a Hadith screen UI snapshot.
  const HadithScreenUi({
    required this.filters,
    required this.query,
    required this.viewMode,
    required this.isSearchMode,
    required this.searchBusy,
    required this.activeTab,
    required this.visibleResults,
    required this.filterInteractionsEnabled,
    required this.sidePanelCollapsed,
    required this.sidePanelRatio,
    required this.recentSearches,
    required this.selectedHadith,
    required this.searchResults,
    required this.searchError,
    required this.searchLoading,
    required this.searchLoadingMore,
    required this.searchHasNextPage,
  });

  /// Active search filters.
  final HadithFilters filters;

  /// Committed session search query.
  final String query;

  /// Current view mode (search, bookmarks, or specific list).
  final HadithViewMode viewMode;

  /// Whether the search view is active.
  final bool isSearchMode;

  /// True while a search or pagination request is in flight.
  final bool searchBusy;

  /// Persisted side-panel tab selection.
  final HadithPanelTab activeTab;

  /// Results list for the active view mode.
  final AsyncValue<List<DetailedHadith>> visibleResults;

  /// Whether filter chips and panel controls accept input.
  final bool filterInteractionsEnabled;

  /// Whether the side panel is collapsed.
  final bool sidePanelCollapsed;

  /// Persisted side-panel width ratio.
  final double sidePanelRatio;

  /// Recent searches when the search view should show them.
  final AsyncValue<List<String>> recentSearches;

  /// Currently selected hadith for the detail pane.
  final DetailedHadith? selectedHadith;

  /// Search-mode result list (empty in other modes).
  final List<DetailedHadith> searchResults;

  /// Search-mode error message.
  final String? searchError;

  /// Whether the initial search request is in flight.
  final bool searchLoading;

  /// Whether a pagination request is in flight.
  final bool searchLoadingMore;

  /// Whether another page of search results is available.
  final bool searchHasNextPage;
}
