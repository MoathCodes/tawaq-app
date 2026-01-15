import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// The unified controller for the Mushaf reader.
///
/// This controller provides everything needed to build a Quran reader:
/// - **Navigation**: Jump to pages, surahs, ayahs, or juzs
/// - **Selection**: Highlight and select ayahs
/// - **Data Access**: Fetch pages, surahs, ayahs, and juzs
/// - **Page State**: Track current page and get page info
///
/// ## Quick Start
///
/// ```dart
/// class MyReaderScreen extends StatefulWidget {
///   @override
///   State<MyReaderScreen> createState() => _MyReaderScreenState();
/// }
///
/// class _MyReaderScreenState extends State<MyReaderScreen> {
///   late final MushafReaderController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = MushafReaderController();
///     _initReader();
///   }
///
///   Future<void> _initReader() async {
///     await _controller.init();
///     setState(() {});
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return MushafReader(
///       controller: _controller,
///       onAyahTap: (info) => print('Tapped ${info.reference}'),
///     );
///   }
/// }
/// ```
///
/// ## Navigation
///
/// ```dart
/// // Jump to a specific page
/// controller.jumpToPage(100);
///
/// // Jump to a surah
/// await controller.jumpToSurah(2); // Al-Baqarah
///
/// // Jump to a specific ayah
/// await controller.jumpToAyah(255); // Ayat Al-Kursi
///
/// // Navigate forward/backward
/// controller.nextPage();
/// controller.previousPage();
/// ```
///
/// ## Selection
///
/// ```dart
/// // Select an ayah
/// controller.selectAyah(1);
///
/// // Clear selection
/// controller.clearSelection();
/// ```
///
/// ## Data Access
///
/// ```dart
/// // Get all surahs (sync after init)
/// final surahs = controller.getSurahsSync();
///
/// // Get page info
/// final info = await controller.getPageInfo(1);
///
/// // Get ayah by reference
/// final ayah = await controller.getAyahBySurah(2, 255);
/// ```
///
/// See also:
/// - [MushafReader], the convenience widget that uses this controller
/// - [MushafPage], the single-page widget
/// - [AyahInfo], for ayah tap callback info
/// - [MushafPageInfo], for current page info
class MushafReaderController extends ChangeNotifier {
  /// The underlying repository for data access.
  final IQuranRepository _repo;

  /// The PageController for the PageView.
  ///
  /// If not provided, one is created and owned by this controller.
  PageController? _pageController;

  /// Whether this controller owns the PageController.
  final bool _ownsPageController;

  /// The initial page to display (1-604).
  final int initialPage;

  /// Number of pages to display per viewport (1 or 2).
  int _pagesPerViewport;

  /// Current page number (1-604).
  ///
  /// In 2-page mode, this is always the start page of the viewport.
  int _currentPage = 1;

  /// The currently selected Ayah ID, or null if none selected.
  int? _selectedAyahId;

  /// Whether the controller is initialized.
  bool _isInitialized = false;

  /// Cached Basmalah glyph.
  String? _cachedBasmalah;

  /// Cached Juz data (populated during init).
  Map<int, JuzModel>? _juzCache;

  /// Cached Surah data (populated during init).
  List<SurahModel>? _surahCache;

  /// Cached page info for the current page.
  MushafPageInfo? _currentPageInfo;

  /// Cached page info for the next page (in 2-page mode).
  MushafPageInfo? _nextPageInfo;

  /// Creates a MushafReaderController.
  ///
  /// [pageController] - Optional external PageController. If not provided,
  /// one will be created and managed internally.
  ///
  /// [initialPage] - The page to start on (1-604). Defaults to 1.
  ///
  /// [pagesPerViewport] - How many pages to show at once. Defaults to 1.
  MushafReaderController({
    PageController? pageController,
    this.initialPage = 1,
    int pagesPerViewport = 1,
  }) : _pageController = pageController,
       _ownsPageController = pageController == null,
       _repo = HiveQuranRepository(),
       _pagesPerViewport = pagesPerViewport,
       _currentPage =
           ((initialPage - 1) ~/ pagesPerViewport) * pagesPerViewport + 1 {
    _init(checkInit: true);
  }

  /// Creates a MushafReaderController with a custom repository.
  ///
  /// Use this constructor for testing or when using a custom data source.
  @visibleForTesting
  MushafReaderController.withRepository({
    required IQuranRepository repository,
    PageController? pageController,
    this.initialPage = 1,
    int pagesPerViewport = 1,
  }) : _pageController = pageController,
       _ownsPageController = pageController == null,
       _repo = repository,
       _pagesPerViewport = pagesPerViewport,
       _currentPage =
           ((initialPage - 1) ~/ pagesPerViewport) * pagesPerViewport + 1 {
    _init(checkInit: false);
  }

  void _init({required bool checkInit}) {
    if (_isInitialized) return;

    // Ensure the library was initialized (only if using default repo)
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
    // Pre-cache basmalah
    _repo.getBasmalah().then((value) => _cachedBasmalah = value);

    // Pre-cache all juzs
    _repo.getJuzs().then(
      (value) => _juzCache = {for (var j in value) j.number: j},
    );

    // Pre-cache all surahs
    _repo.getAllSurahs().then((value) => _surahCache = value);

    // Load initial page info
    getPageInfo(_currentPage).then((value) {
      _currentPageInfo = value;
    });

    _isInitialized = true;
    notifyListeners();
  }

  // ============================================================
  // Getters
  // ============================================================

  /// The cached Basmalah glyph (null before init).
  String? get basmalah => _cachedBasmalah;

  /// The current page number (1-604).
  ///
  /// In 2-page mode, this is the first page of the viewport.
  int get currentPage => _currentPage;

  /// The current pages numbers.
  ///
  /// Returns a record `(first, second)`. In 1-page mode, `second` is `first + 1`
  /// but typically only `first` is displayed.
  (int, int) get currentPages => (_currentPage, _currentPage + 1);

  /// The current page info (sync access, may be null before first page load).
  MushafPageInfo? get currentPageInfo => _currentPageInfo;

  /// The current pages info (sync access).
  (MushafPageInfo?, MushafPageInfo?) get currentPagesInfo =>
      (_currentPageInfo, _nextPageInfo);

  /// Whether the controller is initialized and ready for use.
  bool get isInitialized => _isInitialized;

  /// The PageController for binding to a PageView.
  ///
  /// Created lazily on first access.
  PageController get pageController {
    if (_pageController == null) {
      final viewportIndex = (_currentPage - 1) ~/ pagesPerViewport;
      _pageController = PageController(initialPage: viewportIndex);
    }
    return _pageController!;
  }

  /// The underlying repository for direct data access.
  ///
  /// Use this when you need to access the repository directly.
  IQuranRepository get repository => _repo;

  /// The currently selected Ayah ID, or null if none.
  int? get selectedAyahId => _selectedAyahId;

  /// Number of pages displayed per viewport (1 or 2).
  ///
  /// Use this setter when switching between single-page and two-page modes.
  int get pagesPerViewport => _pagesPerViewport;
  set pagesPerViewport(int value) {
    if (_pagesPerViewport != value && (value == 1 || value == 2)) {
      // Remember the current page before changing viewport mode
      final currentPage = _currentPage;
      _pagesPerViewport = value;
      // Recalculate current page position for the new viewport mode
      final normalizedPage = ((currentPage - 1) ~/ value) * value + 1;
      _currentPage = normalizedPage;
      // Jump the PageController to the correct viewport index after frame completes
      final viewportIndex = (normalizedPage - 1) ~/ value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController?.hasClients ?? false) {
          _pageController!.jumpToPage(viewportIndex);
        }
      });
      notifyListeners();
    }
  }

  // ============================================================
  // Initialization
  // ============================================================

  /// Animates to a specific page (1-604).
  Future<void> animateToPage(
    int page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (page < 1 || page > 604) return;

    final normalizedPage =
        ((page - 1) ~/ pagesPerViewport) * pagesPerViewport + 1;
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
  void clearSelection() {
    selectAyah(null);
  }

  // ============================================================
  // Navigation
  // ============================================================

  @override
  void dispose() {
    if (_ownsPageController) {
      _pageController?.dispose();
    }
    _repo.dispose();
    _juzCache = null;
    _surahCache = null;
    _cachedBasmalah = null;
    super.dispose();
  }

  /// Gets all Surahs.
  Future<List<SurahModel>> getAllSurahs() => _repo.getAllSurahs();

  /// Gets an Ayah by its global ID.
  Future<AyahModel> getAyah(int ayahId, [bool removeNewLines = true]) =>
      _repo.getAyah(ayahId, removeNewLines);

  /// Gets an Ayah by Surah and verse number.
  Future<AyahModel> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) => _repo.getAyahBySurah(surah, ayahInSurah, removeNewLines);

  /// Creates an [AyahInfo] from an ayah ID.
  ///
  /// Useful for building rich callback data.
  Future<AyahInfo> getAyahInfo(int ayahId) async {
    final ayah = await getAyah(ayahId);
    return AyahInfo(
      ayahId: ayah.id,
      surahNumber: ayah.surah,
      verseNumber: ayah.numberInSurah,
      page: ayah.page,
      juz: ayah.juz,
    );
  }

  /// Gets the Basmalah glyph.
  Future<String> getBasmalah() async {
    _cachedBasmalah ??= await _repo.getBasmalah();
    return _cachedBasmalah!;
  }

  /// Gets a Juz by number.
  Future<JuzModel> getJuz(int number) => _repo.getJuz(number);

  /// Gets all Juzs.
  Future<List<JuzModel>> getJuzs() => _repo.getJuzs();

  /// Gets all 30 Juzs (sync, requires init).
  List<JuzModel> getJuzsSync() {
    if (_juzCache == null) return [];
    return _juzCache!.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  // ============================================================
  // Selection
  // ============================================================

  /// Gets the start page for a Juz.
  Future<int> getJuzStartPage(int juzNumber) =>
      _repo.getJuzStartPage(juzNumber);

  /// Gets a Juz by number (sync, requires init).
  JuzModel? getJuzSync(int juzNumber) => _juzCache?[juzNumber];

  // ============================================================
  // Data Access - Sync (after init)
  // ============================================================

  /// Gets a complete page model.
  Future<QuranPageModel> getPage(int page) => _repo.getPage(page);

  /// Gets the page number for a specific Ayah.
  Future<int> getPageForAyah(int ayahId) => _repo.getPageForAyah(ayahId);

  /// Gets the info for a specific page.
  ///
  /// This builds a [MushafPageInfo] from the page model.
  Future<MushafPageInfo> getPageInfo(int page) async {
    final pageModel = await getPage(page);
    return _buildPageInfo(pageModel);
  }

  /// Gets the info for two pages (starting from [page]).
  Future<(MushafPageInfo, MushafPageInfo?)> getTwoPagesInfo(int page) async {
    final first = await getPageInfo(page);
    MushafPageInfo? second;
    if (page + 1 <= 604) {
      second = await getPageInfo(page + 1);
    }
    return (first, second);
  }

  /// Gets the start page for a Surah.
  Future<int> getStartPageForSurah(int surahNumber) =>
      _repo.getStartPageForSurah(surahNumber);

  /// Gets the start page for a Surah (sync, requires init).
  int? getStartPageForSurahSync(int surahNumber) {
    final surah = getSurahSync(surahNumber);
    return surah?.startPage;
  }

  // ============================================================
  // Data Access - Async
  // ============================================================

  /// Gets a Surah by number.
  Future<SurahModel?> getSurah(int surahNumber) => _repo.getSurah(surahNumber);

  /// Gets all 114 Surahs (sync, requires init).
  List<SurahModel> getSurahsSync() => _surahCache ?? [];

  /// Gets a Surah by number (sync, requires init).
  SurahModel? getSurahSync(int surahNumber) {
    if (_surahCache == null) return null;
    return _surahCache!.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () => throw ArgumentError('Surah $surahNumber not found'),
    );
  }

  /// Initializes the controller.
  ///
  /// This must be called before using most methods. It:
  /// - Pre-caches essential data (surahs, juzs, basmalah)
  /// - Loads the initial page info
  ///
  /// **Important**: You must call `MushafReaderLibrary.ensureInitialized()` in your
  /// `main()` function before using this controller.
  ///
  /// This method is idempotent - subsequent calls return immediately.
  ///
  /// Throws [StateError] if `MushafReaderLibrary.ensureInitialized()` was not called.
  // Future<void> init() async {
  //   if (_isInitialized) return;

  //   // Ensure the library was initialized
  //   if (!MushafReaderLibrary.isInitialized) {
  //     throw StateError(
  //       'MushafReaderLibrary.ensureInitialized() must be called before using '
  //       'MushafReaderController. Add it to your main() function:\n\n'
  //       'void main() async {\n'
  //       '  WidgetsFlutterBinding.ensureInitialized();\n'
  //       '  await MushafReaderLibrary.ensureInitialized();\n'
  //       '  runApp(MyApp());\n'
  //       '}',
  //     );
  //   }

  //   // Pre-cache basmalah
  //   _cachedBasmalah = await _repo.getBasmalah();

  //   // Pre-cache all juzs
  //   final juzs = await _repo.getJuzs();
  //   _juzCache = {for (var j in juzs) j.number: j};

  //   // Pre-cache all surahs
  //   _surahCache = await _repo.getAllSurahs();

  //   // Load initial page info
  //   _currentPageInfo = await getPageInfo(_currentPage);

  //   _isInitialized = true;
  //   notifyListeners();
  // }

  /// Jumps to the page containing a specific Ayah.
  ///
  /// Optionally selects the ayah after navigation.
  Future<void> jumpToAyah(int ayahId, {bool select = false}) async {
    final page = await _repo.getPageForAyah(ayahId);
    jumpToPage(page);
    if (select) {
      selectAyah(ayahId);
    }
  }

  /// Jumps to the start of a Juz.
  Future<void> jumpToJuz(int juzNumber) async {
    final page = await _repo.getJuzStartPage(juzNumber);
    jumpToPage(page);
  }

  /// Jumps to a specific page (1-604).
  ///
  /// Updates the current page and navigates the PageView.
  void jumpToPage(int page) {
    if (page < 1 || page > 604) return;

    final normalizedPage =
        ((page - 1) ~/ pagesPerViewport) * pagesPerViewport + 1;
    _setCurrentPage(normalizedPage);

    final viewportIndex = (normalizedPage - 1) ~/ pagesPerViewport;
    if (pageController.hasClients) {
      pageController.jumpToPage(viewportIndex);
    }
  }

  /// Jumps to the start of a Surah.
  Future<void> jumpToSurah(int surahNumber) async {
    final page = await _repo.getStartPageForSurah(surahNumber);
    jumpToPage(page);
  }

  /// Loads and caches the current page info.
  ///
  /// Call this after navigation to update [currentPageInfo].
  Future<MushafPageInfo> loadCurrentPageInfo() async {
    _currentPageInfo = await getPageInfo(_currentPage);
    if (pagesPerViewport == 2 && _currentPage + 1 <= 604) {
      _nextPageInfo = await getPageInfo(_currentPage + 1);
    }
    return _currentPageInfo!;
  }

  /// Navigates to the next page.
  void nextPage() {
    final next = _currentPage + pagesPerViewport;
    if (next <= 604) {
      jumpToPage(next);
    }
  }

  /// Called when the page changes (from PageView onPageChanged).
  ///
  /// Use this to sync the controller with the PageView:
  /// ```dart
  /// PageView.builder(
  ///   controller: controller.pageController,
  ///   onPageChanged: controller.onPageChanged,
  ///   ...
  /// )
  /// ```
  void onPageChanged(int pageIndex) {
    final page = pageIndex * pagesPerViewport + 1;
    _setCurrentPage(page);
  }

  // ============================================================
  // Page Info
  // ============================================================

  /// Preloads pages around the current page.
  Future<void> preloadAdjacentPages({int count = 2}) async {
    final pages = <int>[];
    for (int i = 1; i <= count; i++) {
      if (_currentPage - i >= 1) pages.add(_currentPage - i);
      if (_currentPage + i <= 604) pages.add(_currentPage + i);
    }
    await preloadPages(pages);
  }

  /// Pre-loads pages into the cache for better performance.
  Future<void> preloadPages(List<int> pageNumbers) async {
    const batchSize = 10;
    for (int i = 0; i < pageNumbers.length; i += batchSize) {
      final batch = pageNumbers.skip(i).take(batchSize);
      await Future.wait(batch.map((page) => getPage(page)));
    }
  }

  /// Navigates to the previous page.
  void previousPage() {
    final prev = _currentPage - pagesPerViewport;
    if (prev >= 1) {
      jumpToPage(prev);
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Selects (highlights) an Ayah.
  ///
  /// Pass null to clear the selection.
  void selectAyah(int? ayahId) {
    if (_selectedAyahId != ayahId) {
      _selectedAyahId = ayahId;
      notifyListeners();
    }
  }

  MushafPageInfo _buildPageInfo(QuranPageModel page) {
    final surahNumbers = <int>[];
    final surahNames = <String>[];
    final ayahIds = <int>[];

    for (final surah in page.surahs) {
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
      pageNumber: page.pageNumber,
      juzNumber: page.juzNumber,
      surahNumbers: surahNumbers,
      surahNames: surahNames,
      firstAyahId: ayahIds.isNotEmpty ? ayahIds.first : 0,
      lastAyahId: ayahIds.isNotEmpty ? ayahIds.last : 0,
      ayahIds: ayahIds,
    );
  }

  /// Loads page info asynchronously and notifies listeners when ready.
  Future<void> _loadPageInfoAsync() async {
    final page = _currentPage;
    final info = await getPageInfo(page);
    MushafPageInfo? nextInfo;
    if (pagesPerViewport == 2 && page + 1 <= 604) {
      nextInfo = await getPageInfo(page + 1);
    }

    // Only update if we're still on the same page
    if (_currentPage == page) {
      _currentPageInfo = info;
      _nextPageInfo = nextInfo;
      notifyListeners();
    }
  }

  void _setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      _currentPageInfo = null; // Invalidate cache
      _nextPageInfo = null;
      notifyListeners();
      // Load page info asynchronously
      _loadPageInfoAsync();
    }
  }
}
