import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';
import 'package:mushaf_reader/src/logic/mushaf_reader_listenables.dart';

/// The unified controller for the Mushaf reader.
///
/// This controller provides everything needed to build a Quran reader:
/// - **Navigation**: Jump to pages, surahs, ayahs, or juzs
/// - **Selection**: Highlight and select ayahs
/// - **Data Access**: Fetch pages, surahs, ayahs, and juzs
/// - **Page State**: Track current page and get page info
///
/// ## Narrow listenables
///
/// Prefer [selection] and [page] with [ListenableBuilder] instead of listening
/// to the whole controller when only one concern changes:
///
/// ```dart
/// ListenableBuilder(
///   listenable: controller.page,
///   builder: (context, _) => Text('Page ${controller.currentPage}'),
/// );
/// ```
///
/// See also:
/// - [MushafSelectionListenable], [MushafPageListenable]
/// - [MushafReader], the convenience widget that uses this controller
/// - [MushafPage], the single-page widget
class MushafReaderController implements Listenable {
  /// The underlying repository for data access.
  final IQuranRepository _repo;

  /// The PageController for the PageView.
  ///
  /// If not provided, one is created and owned by this controller.
  PageController? _pageController;

  /// Whether this controller owns the PageController.
  final bool _ownsPageController;

  /// Whether to require [MushafReaderLibrary.ensureInitialized] before init.
  final bool _checkLibraryInit;

  /// The initial page to display (1-604).
  final int initialPage;

  /// Selection-only notifications.
  final MushafSelectionNotifier selection = MushafSelectionNotifier();

  /// Page navigation and metadata notifications.
  final MushafPageNotifier page = MushafPageNotifier();

  late final Listenable _merged = MergedListenable([selection, page]);

  /// Whether the controller is initialized and [ensureReady] has completed.
  bool _isInitialized = false;

  /// Completes when [_doInit] finishes successfully.
  Future<void>? _initFuture;

  /// Cached Basmalah glyph.
  String? _cachedBasmalah;

  /// Cached Juz data (populated during init).
  Map<int, Juz>? _juzCache;
  Map<int, Hizb>? _hizbCache;

  /// Cached Surah data (populated during init).
  Map<int, Surah>? _surahCache;

  /// Whether a notification is already scheduled.
  bool _pageNotificationScheduled = false;

  /// In-flight page info load generation (drops stale async results).
  int _pageInfoLoadGeneration = 0;

  /// Set in [dispose]; guards async init/page loads from notifying after teardown.
  bool _disposed = false;

  /// Creates a MushafReaderController.
  MushafReaderController({
    PageController? pageController,
    this.initialPage = 1,
    int pagesPerViewport = 1,
    IQuranRepository? repository,
  }) : _pageController = pageController,
       _ownsPageController = pageController == null,
       _repo = repository ?? HiveQuranRepository.acquire(),
       _checkLibraryInit = repository == null {
    page.setCurrentPage(
      ((initialPage - 1) ~/ pagesPerViewport) * pagesPerViewport + 1,
    );
    page.setPagesPerViewport(pagesPerViewport);
    _syncRepoPageCacheCapacity();
    _init(checkInit: _checkLibraryInit);
  }

  /// Creates a MushafReaderController with a custom repository.
  @visibleForTesting
  MushafReaderController.withRepository({
    required IQuranRepository repository,
    PageController? pageController,
    this.initialPage = 1,
    int pagesPerViewport = 1,
  }) : _pageController = pageController,
       _ownsPageController = pageController == null,
       _repo = repository,
       _checkLibraryInit = false {
    page.setCurrentPage(
      ((initialPage - 1) ~/ pagesPerViewport) * pagesPerViewport + 1,
    );
    page.setPagesPerViewport(pagesPerViewport);
    _syncRepoPageCacheCapacity();
    _init(checkInit: false);
  }

  void _init({required bool checkInit}) {
    unawaited(ensureReady(checkInit: checkInit));
  }

  /// Waits until the repository is ready and reference data is cached.
  Future<void> ensureReady({bool? checkInit}) {
    if (_isInitialized) return Future.value();
    return _initFuture ??= _doInit(checkInit: checkInit ?? _checkLibraryInit);
  }

  Future<void> _doInit({required bool checkInit}) async {
    if (_isInitialized) return;

    if (checkInit && !MushafReaderLibrary.isInitialized) {
      throw StateError(
        'MushafReaderLibrary.ensureInitialized() must be called before using '
        'MushafReaderController. Add it to your main() function:\n\n'
        'void main() async {\n'
        '  WidgetsFlutterBinding.ensureInitialized();\n'
        '  await MushafReaderLibrary.ensureInitialized();\n'
        '  runApp(MyApp());\n'
        '}',
      );
    }

    await _repo.ensureReady();
    if (_disposed) return;

    _cachedBasmalah = await _repo.getBasmalah();
    if (_disposed) return;

    final juzs = await _repo.getJuzs();
    if (_disposed) return;
    _juzCache = {for (final j in juzs) j.number: j};

    final hizbs = await _repo.getHizbs();
    if (_disposed) return;
    _hizbCache = {for (final h in hizbs) h.number: h};

    final surahs = await _repo.getAllSurahs();
    if (_disposed) return;
    _surahCache = {for (final s in surahs) s.number: s};

    final info = await getPageInfo(currentPage);
    if (_disposed) return;
    MushafPageInfo? nextInfo;
    if (pagesPerViewport == 2 &&
        currentPage + 1 <= MushafConstants.pageCount) {
      nextInfo = await getPageInfo(currentPage + 1);
    }
    if (_disposed) return;
    page.setPageInfo(info: info, nextInfo: nextInfo);

    _isInitialized = true;
    if (_disposed) return;
    page.notifyPageChanged();
  }

  void _safeNotifyPageListeners() {
    if (_disposed) return;
    final SchedulerPhase? phase = _schedulerPhaseOrNull;
    final isBuildPhase =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (isBuildPhase) {
      if (!_pageNotificationScheduled) {
        _pageNotificationScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageNotificationScheduled = false;
          if (_disposed) return;
          page.notifyPageChanged();
        });
      }
    } else {
      page.notifyPageChanged();
    }
  }

  SchedulerPhase? get _schedulerPhaseOrNull {
    try {
      return SchedulerBinding.instance.schedulerPhase;
    } on Object {
      return null;
    }
  }

  @override
  void addListener(VoidCallback listener) => _merged.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _merged.removeListener(listener);

  // ============================================================
  // Getters (facade over [selection] + [page])
  // ============================================================

  /// The cached Basmalah glyph (null before init).
  String? get basmalah => _cachedBasmalah;

  /// The current page number (1-604).
  int get currentPage => page.currentPage;

  /// The current pages numbers.
  (int, int) get currentPages => page.currentPages;

  /// The current page info (sync access, may be null before first page load).
  MushafPageInfo? get currentPageInfo => page.currentPageInfo;

  /// The current pages info (sync access).
  (MushafPageInfo?, MushafPageInfo?) get currentPagesInfo =>
      page.currentPagesInfo;

  /// Whether [ensureReady] has completed and cached data is available.
  bool get isInitialized => _isInitialized;

  /// The PageController for binding to a PageView.
  PageController get pageController {
    if (_pageController == null) {
      final viewportIndex = (currentPage - 1) ~/ pagesPerViewport;
      _pageController = PageController(initialPage: viewportIndex);
    }
    return _pageController!;
  }

  /// The underlying repository for direct data access.
  IQuranRepository get repository => _repo;

  /// The currently selected Ayah ID, or null if none.
  int? get selectedAyahId => selection.selectedAyahId;

  /// Number of pages displayed per viewport (1 or 2).
  int get pagesPerViewport => page.pagesPerViewport;
  set pagesPerViewport(int value) {
    if (pagesPerViewport != value && (value == 1 || value == 2)) {
      final previousPage = currentPage;
      page.setPagesPerViewport(value);
      _syncRepoPageCacheCapacity();
      final normalizedPage = ((previousPage - 1) ~/ value) * value + 1;
      page.setCurrentPage(normalizedPage);
      final viewportIndex = (normalizedPage - 1) ~/ value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        if (_pageController?.hasClients ?? false) {
          _pageController!.jumpToPage(viewportIndex);
        }
      });
      _loadPageInfoAsync();
      _safeNotifyPageListeners();
    }
  }

  void _syncRepoPageCacheCapacity() {
    final repo = _repo;
    if (repo is HiveQuranRepository) {
      repo.pageCacheCapacity = pagesPerViewport == 2 ? 20 : 16;
    }
  }

  /// Animates to a specific page (1-604).
  Future<void> animateToPage(
    int pageNumber, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (pageNumber < 1 || pageNumber > MushafConstants.pageCount) return;

    final normalizedPage =
        ((pageNumber - 1) ~/ pagesPerViewport) * pagesPerViewport + 1;
    _setCurrentPage(normalizedPage);

    final viewportIndex = (normalizedPage - 1) ~/ pagesPerViewport;
    if (pageController.hasClients) {
      await pageController.animateToPage(
        viewportIndex,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Clears the current Ayah selection.
  void clearSelection() => selectAyah(null);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pageInfoLoadGeneration++;
    if (_ownsPageController) {
      _pageController?.dispose();
    }
    _repo.dispose();
    _juzCache = null;
    _hizbCache = null;
    _surahCache = null;
    _cachedBasmalah = null;
    selection.dispose();
    page.dispose();
  }

  /// Gets all Surahs.
  Future<List<Surah>> getAllSurahs() async {
    if (_surahCache != null) {
      return _surahCache!.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
    }
    final surahs = await _repo.getAllSurahs();
    _surahCache = {for (final s in surahs) s.number: s};
    return surahs;
  }

  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) =>
      _repo.getAyah(ayahId, removeNewLines);

  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) => _repo.getAyahBySurah(surah, ayahInSurah, removeNewLines);

  Future<String> getBasmalah() async {
    _cachedBasmalah ??= await _repo.getBasmalah();
    return _cachedBasmalah!;
  }

  Future<Juz> getJuz(int number) => _repo.getJuz(number);

  Future<List<Juz>> getJuzs() async {
    if (_juzCache != null) {
      return _juzCache!.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
    }
    final juzs = await _repo.getJuzs();
    _juzCache = {for (var j in juzs) j.number: j};
    return juzs;
  }

  Future<int> getJuzStartPage(int juzNumber) =>
      _repo.getJuzStartPage(juzNumber);

  Juz? getJuzSync(int juzNumber) => _juzCache?[juzNumber];

  ({int startAyahId, int endAyahId})? juzAyahBounds(int juzNumber) =>
      _repo.juzAyahBounds(juzNumber);

  Future<Hizb> getHizb(int number) => _repo.getHizb(number);

  Future<List<Hizb>> getHizbs() async {
    if (_hizbCache != null) {
      return _hizbCache!.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));
    }
    final hizbs = await _repo.getHizbs();
    _hizbCache = {for (final h in hizbs) h.number: h};
    return hizbs;
  }

  Future<int> getHizbStartPage(int hizbNumber) =>
      _repo.getHizbStartPage(hizbNumber);

  Hizb? getHizbSync(int hizbNumber) => _hizbCache?[hizbNumber];

  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) =>
      _repo.hizbAyahBounds(hizbNumber);

  Future<QuranPage> getPage(int pageNumber) => _repo.getPage(pageNumber);

  Future<List<int>> orderedAyahIdsOnPage(int pageNumber) async {
    final pageModel = await getPage(pageNumber);
    return MushafPageRangeLayout.orderedAyahIdsOnPage(pageModel);
  }

  Future<int> getPageForAyah(int ayahId) => _repo.getPageForAyah(ayahId);

  Future<MushafPageInfo> getPageInfo(int pageNumber) async {
    final pageModel = await getPage(pageNumber);
    return _buildPageInfo(pageModel);
  }

  Future<(MushafPageInfo, MushafPageInfo?)> getTwoPagesInfo(int pageNumber) async {
    final first = await getPageInfo(pageNumber);
    MushafPageInfo? second;
    if (pageNumber + 1 <= MushafConstants.pageCount) {
      second = await getPageInfo(pageNumber + 1);
    }
    return (first, second);
  }

  Future<int> getStartPageForSurah(int surahNumber) =>
      _repo.getStartPageForSurah(surahNumber);

  int? getStartPageForSurahSync(int surahNumber) {
    final surah = getSurahSync(surahNumber);
    return surah?.startPage;
  }

  Future<Surah?> getSurah(int surahNumber) => _repo.getSurah(surahNumber);

  Surah? getSurahSync(int surahNumber) => _surahCache?[surahNumber];

  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) {
    return _repo.searchAyahs(
      query,
      surahNumber: surahNumber,
      maxResults: maxResults,
    );
  }

  Future<void> warmUpSearchIndex() => _repo.warmUpSearchIndex();

  Future<void> jumpToAyah(int ayahId, {bool select = false}) async {
    final pageNumber = await _repo.getPageForAyah(ayahId);
    jumpToPage(pageNumber);
    if (select) {
      selectAyah(ayahId);
    }
  }

  Future<void> jumpToJuz(int juzNumber) async {
    final pageNumber = await _repo.getJuzStartPage(juzNumber);
    jumpToPage(pageNumber);
  }

  Future<void> jumpToHizb(int hizbNumber) async {
    final pageNumber = await _repo.getHizbStartPage(hizbNumber);
    jumpToPage(pageNumber);
  }

  void jumpToPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > MushafConstants.pageCount) return;

    final normalizedPage =
        ((pageNumber - 1) ~/ pagesPerViewport) * pagesPerViewport + 1;

    final pagesToWarm = <int>[normalizedPage];
    if (pagesPerViewport == 2 &&
        normalizedPage + 1 <= MushafConstants.pageCount) {
      pagesToWarm.add(normalizedPage + 1);
    }
    for (final p in pagesToWarm) {
      _repo.getPage(p);
    }

    _setCurrentPage(normalizedPage);

    final viewportIndex = (normalizedPage - 1) ~/ pagesPerViewport;
    if (pageController.hasClients) {
      pageController.jumpToPage(viewportIndex);
    }
  }

  Future<void> jumpToSurah(int surahNumber) async {
    final pageNumber = await _repo.getStartPageForSurah(surahNumber);
    jumpToPage(pageNumber);
  }

  Future<MushafPageInfo> loadCurrentPageInfo() async {
    final info = await getPageInfo(currentPage);
    MushafPageInfo? nextInfo;
    if (pagesPerViewport == 2 &&
        currentPage + 1 <= MushafConstants.pageCount) {
      nextInfo = await getPageInfo(currentPage + 1);
    }
    page
      ..setPageInfo(info: info, nextInfo: nextInfo)
      ..notifyPageChanged();
    return info;
  }

  void nextPage() {
    final next = currentPage + pagesPerViewport;
    if (next <= MushafConstants.pageCount) {
      jumpToPage(next);
    }
  }

  void onPageChanged(int pageIndex) {
    final pageNumber = pageIndex * pagesPerViewport + 1;
    if (pageNumber == currentPage) return;
    _setCurrentPage(pageNumber);
  }

  Future<void> preloadAdjacentPages({int? count}) async {
    final radius = count ?? pagesPerViewport + 1;
    final pages = <int>[];
    for (int i = 1; i <= radius; i++) {
      if (currentPage - i >= 1) pages.add(currentPage - i);
      if (currentPage + i <= MushafConstants.pageCount) {
        pages.add(currentPage + i);
      }
    }
    await preloadPages(pages);
  }

  Future<void> preloadPages(List<int> pageNumbers) async {
    const batchSize = 10;
    for (int i = 0; i < pageNumbers.length; i += batchSize) {
      final batch = pageNumbers.skip(i).take(batchSize);
      await Future.wait(batch.map((p) => getPage(p)));
    }
  }

  void previousPage() {
    final prev = currentPage - pagesPerViewport;
    if (prev >= 1) {
      jumpToPage(prev);
    }
  }

  void selectAyah(int? ayahId) => selection.update(ayahId);

  MushafPageInfo _buildPageInfo(QuranPage pageModel) {
    final surahNumbers = <int>[];
    final surahNames = <String>[];
    final ayahIds = <int>[];

    for (final surah in pageModel.surahs) {
      if (!surahNumbers.contains(surah.surahNumber)) {
        surahNumbers.add(surah.surahNumber);
        final cached = getSurahSync(surah.surahNumber);
        surahNames.add(
          cached?.nameArabic ?? cached?.nameEnglish ?? surah.glyph,
        );
      }
      for (final ayah in surah.ayahs) {
        if (!ayahIds.contains(ayah.ayahId)) {
          ayahIds.add(ayah.ayahId);
        }
      }
    }

    return MushafPageInfo(
      pageNumber: pageModel.pageNumber,
      juzNumber: pageModel.juzNumber,
      surahNumbers: surahNumbers,
      surahNames: surahNames,
      firstAyahId: ayahIds.isNotEmpty ? ayahIds.first : 0,
      lastAyahId: ayahIds.isNotEmpty ? ayahIds.last : 0,
      ayahIds: ayahIds,
    );
  }

  Future<void> _loadPageInfoAsync() async {
    final generation = ++_pageInfoLoadGeneration;
    final pageNumber = currentPage;

    final info = await getPageInfo(pageNumber);
    if (_disposed) return;
    MushafPageInfo? nextInfo;
    if (pagesPerViewport == 2 &&
        pageNumber + 1 <= MushafConstants.pageCount) {
      nextInfo = await getPageInfo(pageNumber + 1);
    }
    if (_disposed) return;

    if (_disposed ||
        generation != _pageInfoLoadGeneration ||
        currentPage != pageNumber) {
      return;
    }

    page.setPageInfo(info: info, nextInfo: nextInfo);
    _safeNotifyPageListeners();
  }

  void _setCurrentPage(int pageNumber) {
    if (currentPage == pageNumber) return;
    page.setCurrentPage(pageNumber);
    _loadPageInfoAsync();
  }
}
