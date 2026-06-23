import 'package:flutter/foundation.dart';
import 'package:mushaf_reader/src/data/models/mushaf_page_info.dart';

/// Narrow listenable for ayah highlight / selection state.
///
/// Use with [ListenableBuilder] when only [selectedAyahId] affects the subtree
/// (for example ayah spans inside [MushafPage]).
abstract interface class MushafSelectionListenable implements Listenable {
  /// The currently selected global ayah id, or `null` when cleared.
  int? get selectedAyahId;
}

/// Narrow listenable for current page navigation and cached page metadata.
///
/// Use with [ListenableBuilder] for headers, juz/surah chips, and other chrome
/// that tracks [currentPage] / [currentPageInfo] without rebuilding on selection.
abstract interface class MushafPageListenable implements Listenable {
  /// The current page number (1–604).
  ///
  /// In two-page mode this is the first page of the viewport.
  int get currentPage;

  /// The current page numbers as `(first, second)`.
  (int, int) get currentPages;

  /// Cached metadata for the active page(s); may be briefly `null` after a jump.
  MushafPageInfo? get currentPageInfo;

  /// Cached metadata for both pages in a spread.
  (MushafPageInfo?, MushafPageInfo?) get currentPagesInfo;

  /// Pages shown per viewport (`1` or `2`).
  int get pagesPerViewport;
}

/// Merges multiple [Listenable]s so legacy `controller.addListener` hears all.
@visibleForTesting
class MergedListenable implements Listenable {
  MergedListenable(this._parts);

  final List<Listenable> _parts;

  @override
  void addListener(VoidCallback listener) {
    for (final part in _parts) {
      part.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final part in _parts) {
      part.removeListener(listener);
    }
  }
}

/// Internal [ChangeNotifier] backing [MushafSelectionListenable].
class MushafSelectionNotifier extends ChangeNotifier
    implements MushafSelectionListenable {
  int? _selectedAyahId;

  @override
  int? get selectedAyahId => _selectedAyahId;

  void update(int? ayahId) {
    if (_selectedAyahId == ayahId) return;
    _selectedAyahId = ayahId;
    notifyListeners();
  }

  void clear() => update(null);
}

/// Internal [ChangeNotifier] backing [MushafPageListenable].
class MushafPageNotifier extends ChangeNotifier
    implements MushafPageListenable {
  int _currentPage = 1;
  int _pagesPerViewport = 1;
  MushafPageInfo? _currentPageInfo;
  MushafPageInfo? _nextPageInfo;

  @override
  int get currentPage => _currentPage;

  @override
  (int, int) get currentPages => (_currentPage, _currentPage + 1);

  @override
  MushafPageInfo? get currentPageInfo =>
      _pagesPerViewport == 2 && _nextPageInfo != null
      ? _nextPageInfo
      : _currentPageInfo;

  @override
  (MushafPageInfo?, MushafPageInfo?) get currentPagesInfo =>
      (_currentPageInfo, _nextPageInfo);

  @override
  int get pagesPerViewport => _pagesPerViewport;

  void setPagesPerViewport(int value) {
    if (_pagesPerViewport == value) return;
    _pagesPerViewport = value;
  }

  void setCurrentPage(int page) {
    if (_currentPage == page) return;
    _currentPage = page;
    _currentPageInfo = null;
    _nextPageInfo = null;
  }

  void setPageInfo({
    required MushafPageInfo info,
    MushafPageInfo? nextInfo,
  }) {
    _currentPageInfo = info;
    _nextPageInfo = nextInfo;
  }

  void notifyPageChanged() => notifyListeners();
}
