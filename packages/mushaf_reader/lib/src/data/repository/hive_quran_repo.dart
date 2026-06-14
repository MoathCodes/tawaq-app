import 'dart:async';

import 'package:mushaf_reader/src/core/arabic_search_normalize.dart';
import 'package:mushaf_reader/src/core/search_index_entry.dart';
import 'package:mushaf_reader/src/data/ayah_id_resolver.dart';
import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/juz.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/quran_page.dart';
import 'package:mushaf_reader/src/data/models/surah.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// Hive-based implementation of [IQuranRepository].
///
/// This repository provides efficient access to Quran data stored in
/// pre-populated Hive boxes. Boxes are bundled as assets and copied
/// to the app directory on first launch.
///
/// ## Box Structure
///
/// - **surahs**: `Box<Surah>` keyed by surah number (1-114)
/// - **ayahs**: `LazyBox<Ayah>` keyed by ayah ID (1-6236)
/// - **search_index**: `Box<String>` keyed by ayah ID — pre-normalized plain text;
///   opened on first search via [HiveBoxManager.ensureSearchIndexBoxOpen]
/// - **juzs**: `Box<Juz>` keyed by juz number (1-30)
/// - **pageLayouts**: `Box<List<PageLayouts>>` keyed by page number (1-604)
/// - **metadata**: `Box<String>` for key-value data (e.g., "basmalah")
///
/// ## Memory Efficiency
///
/// - Surahs, Juzs, and Metadata are loaded into memory (small footprint)
/// - Ayahs use LazyBox - only loaded on demand
/// - Page layouts are loaded per-page as needed
///
/// ## Example
///
/// ```dart
/// final repository = HiveQuranRepository();
/// await repository.ensureReady();
///
/// final page = await repository.getPage(1);
/// print('Page 1 has ${page.surahs.length} surahs');
///
/// repository.dispose(); // Clean up when done
/// ```
///
/// See also:
/// - [IQuranRepository], the abstract interface
/// - [MushafReaderController], which uses this repository
/// - [HiveBoxManager], which manages the underlying boxes
class HiveQuranRepository implements IQuranRepository {
  /// The singleton instance of the repository.
  static HiveQuranRepository? _instance;

  /// Reference count for automatic cleanup.
  static int _refCount = 0;

  /// Maximum number of pages to keep in the LRU cache.
  static const int _kMaxCacheSize = 10;

  /// Total number of ayahs in the Quran.
  static const int _kAyahCount = 6236;

  /// The Hive box manager.
  HiveBoxManager? _boxManager;

  /// Whether initialization is in progress.
  Completer<void>? _initCompleter;

  /// LRU cache for recently accessed page models.
  final _pageCache = <int, QuranPage>{};

  /// Cached Surah data for quick access.
  final _surahCache = <int, Surah>{};

  /// Cached Juz data for quick access.
  final _juzCache = <int, Juz>{};

  /// Cached Basmalah glyph.
  String? _basmalahCache;

  /// Global ayah id of the first verse in each surah (index 1–114).
  List<int>? _globalAyahIdStartBySurah;

  /// Factory constructor that returns the singleton instance.
  factory HiveQuranRepository() {
    _refCount++;
    return _instance ??= HiveQuranRepository._internal();
  }

  HiveQuranRepository._internal();

  /// Forcefully closes all boxes and clears caches.
  void closeAll() {
    _closeAndReset();
  }

  @override
  void dispose() {
    _refCount--;
    _pageCache.clear();

    if (_refCount <= 0) {
      _closeAndReset();
    }
  }

  @override
  Future<void> ensureReady() async {
    if (_boxManager != null) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      // Shares the [HiveBoxManager] singleton with [MushafReaderLibrary].
      // Prefer calling MushafReaderLibrary.ensureInitialized() first so
      // [subDirectory] is applied before any box access.
      _boxManager = HiveBoxManager();
      if (!_boxManager!.isInitialized) {
        await _boxManager!.init();
      }

      // Pre-cache all surahs (114 items - small memory footprint)
      for (final key in _boxManager!.surahsBox.keys) {
        final surah = _boxManager!.surahsBox.get(key);
        if (surah != null) {
          _surahCache[surah.number] = surah;
        }
      }

      // Pre-cache all juzs (30 items)
      for (final key in _boxManager!.juzsBox.keys) {
        final juz = _boxManager!.juzsBox.get(key);
        if (juz != null) {
          _juzCache[juz.number] = juz;
        }
      }

      // Pre-cache basmalah
      _basmalahCache = _boxManager!.metadataBox.get('basmalah');

      _globalAyahIdStartBySurah = AyahIdResolver.buildStarts(_surahCache);

      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  @override
  Future<List<Surah>> getAllSurahs() async {
    await _ensureReady();
    return _surahCache.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async {
    await _ensureReady();
    final ayah = await _boxManager!.ayahsBox.get(ayahId);
    if (ayah == null) throw ArgumentError('Ayah $ayahId not found');
    if (removeNewLines) {
      return ayah.copyWith(text: ayah.text.replaceAll('\n', ''));
    }
    return ayah;
  }

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    await _ensureReady();

    final ayahId = _globalAyahId(surah, ayahInSurah);
    if (ayahId == null) {
      throw ArgumentError('Ayah $surah:$ayahInSurah not found');
    }

    final ayah = await _boxManager!.ayahsBox.get(ayahId);
    if (ayah == null) throw ArgumentError('Ayah $surah:$ayahInSurah not found');

    if (removeNewLines) {
      return ayah.copyWith(text: ayah.text.replaceAll('\n', ''));
    }
    return ayah;
  }

  @override
  Future<String> getBasmalah() async {
    await _ensureReady();
    return _basmalahCache ?? '';
  }

  @override
  String? getBasmalahSync() {
    if (_basmalahCache != null) return _basmalahCache;

    // [MushafReaderLibrary.ensureInitialized] may open boxes before this
    // repository's [ensureReady] runs — hydrate the glyph synchronously when
    // the shared [HiveBoxManager] is already initialized.
    final manager = HiveBoxManager();
    if (manager.isInitialized) {
      _boxManager ??= manager;
      _basmalahCache = manager.metadataBox.get('basmalah');
    }
    return _basmalahCache;
  }

  @override
  Future<Juz> getJuz(int number) async {
    await _ensureReady();
    final juz = _juzCache[number];
    if (juz == null) throw ArgumentError('Juz $number not found');
    return juz;
  }

  @override
  Future<List<Juz>> getJuzs() async {
    await _ensureReady();
    return _juzCache.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Map<int, Juz> getJuzsSync() => Map.unmodifiable(_juzCache);

  @override
  Future<int> getJuzStartPage(int juzNumber) async {
    await _ensureReady();
    // Use pre-computed startPage from Juz (O(1))
    final juz = _juzCache[juzNumber];
    if (juz?.startPage != null) {
      return juz!.startPage!;
    }
    final startAyahId = juz?.startAyahId;
    if (startAyahId != null) {
      return getPageForAyah(startAyahId);
    }
    throw ArgumentError('Juz $juzNumber not found');
  }

  @override
  Juz? getJuzSync(int number) => _juzCache[number];

  @override
  QuranPage? peekCachedPage(int page) {
    if (_pageCache.containsKey(page)) {
      final data = _pageCache.remove(page)!;
      _pageCache[page] = data;
      return data;
    }
    return null;
  }

  @override
  Future<QuranPage> getPage(int page) async {
    await _ensureReady();

    final cached = peekCachedPage(page);
    if (cached != null) return cached;

    // Build page
    final data = await _buildPage(page);
    _pageCache[page] = data;

    // Evict oldest if cache is full
    if (_pageCache.length > _kMaxCacheSize) {
      _pageCache.remove(_pageCache.keys.first);
    }

    return data;
  }

  @override
  Future<int> getPageForAyah(int ayahId) async {
    await _ensureReady();
    final ayah = await _boxManager!.ayahsBox.get(ayahId);
    if (ayah == null) throw ArgumentError('Ayah $ayahId not found');
    return ayah.page;
  }

  @override
  Future<int> getStartPageForSurah(int surahNumber) async {
    await _ensureReady();
    final surah = _surahCache[surahNumber];
    if (surah?.startPage != null) {
      return surah!.startPage!;
    }
    final firstAyahId = _globalAyahId(surahNumber, 1);
    if (firstAyahId != null) {
      return getPageForAyah(firstAyahId);
    }
    throw ArgumentError('Surah $surahNumber not found');
  }

  @override
  Future<Surah?> getSurah(int surahNumber) async {
    await _ensureReady();
    return _surahCache[surahNumber];
  }

  @override
  List<Surah> getSurahsSync() {
    return _surahCache.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Surah? getSurahSync(int number) => _surahCache[number];

  /// Builds a complete [QuranPage] from Hive data.
  Future<QuranPage> _buildPage(int page) async {
    // Get page layouts using the helper method
    final layouts = _boxManager!.getLayoutsForPage(page);
    if (layouts.isEmpty) {
      return QuranPage(
        pageNumber: page,
        glyphText: '',
        lines: [],
        surahs: [],
        juzNumber: 1,
      );
    }

    // Fetch all ayahs for this page
    final ayahMap = <int, Ayah>{};
    for (final layout in layouts) {
      final ayah = await _boxManager!.ayahsBox.get(layout.ayahId);
      if (ayah != null) {
        ayahMap[layout.ayahId] = ayah;
      }
    }

    // Sort layouts by lineStart, then by ayahId for stable ordering
    final sortedLayouts = List<PageLayouts>.from(layouts)
      ..sort((a, b) {
        final lineCompare = a.lineStart.compareTo(b.lineStart);
        if (lineCompare != 0) return lineCompare;
        return a.ayahId.compareTo(b.ayahId);
      });

    // Build concatenated glyph text and fragments
    final buf = StringBuffer();
    final ayahFragments = <AyahFragment>[];

    for (final layout in sortedLayouts) {
      final start = buf.length;
      final ayah = ayahMap[layout.ayahId];
      final text = ayah?.text ?? '';
      buf.write(text);
      final end = buf.length;

      ayahFragments.add(
        AyahFragment(ayahId: layout.ayahId, start: start, end: end),
      );
    }

    // PageLayouts.lineStart/lineEnd are mushaf line numbers (1-based), not
    // character indices. Rendering uses [glyphText] and [surahBlocks] only.
    const lines = <Never>[];

    // Build Surah blocks
    final surahBlocks = <SurahBlock>[];
    if (ayahFragments.isNotEmpty) {
      var currentStart = 0;
      var firstAyah = ayahMap[ayahFragments.first.ayahId]!;
      var currentSurahId = firstAyah.surahNumber;
      var firstNumInSurah = firstAyah.numberInSurah;
      var currentBlockFragments = <AyahFragment>[];
      var currentSurah = _surahCache[currentSurahId];

      for (final frag in ayahFragments) {
        final ayah = ayahMap[frag.ayahId]!;

        if (ayah.surahNumber != currentSurahId) {
          // Close previous block
          surahBlocks.add(
            SurahBlock(
              surahNumber: currentSurahId,
              glyph: currentSurah?.glyph ?? '',
              start: currentStart,
              end: frag.start,
              hasBasmalah: firstNumInSurah == 1,
              ayahs: List.from(currentBlockFragments),
            ),
          );

          // Start new block
          currentSurahId = ayah.surahNumber;
          currentStart = frag.start;
          firstNumInSurah = ayah.numberInSurah;
          currentBlockFragments.clear();
          currentSurah = _surahCache[currentSurahId];
        }
        currentBlockFragments.add(frag);
      }

      // Close final block
      surahBlocks.add(
        SurahBlock(
          surahNumber: currentSurahId,
          glyph: currentSurah?.glyph ?? '',
          start: currentStart,
          end: buf.length,
          hasBasmalah: firstNumInSurah == 1,
          ayahs: List.from(currentBlockFragments),
        ),
      );
    }

    // Juz number from first ayah
    final firstAyahId = sortedLayouts.first.ayahId;
    final firstAyah = ayahMap[firstAyahId];
    final juz = firstAyah?.juz ?? 1;

    return QuranPage(
      pageNumber: page,
      glyphText: buf.toString(),
      lines: lines,
      surahs: surahBlocks,
      juzNumber: juz,
    );
  }

  @override
  Future<void> warmUpSearchIndex() async {
    await _ensureReady();
    await _boxManager!.ensureSearchIndexBoxOpen();
  }

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async {
    await _ensureReady();

    if (maxResults <= 0) return [];

    final normalizedQuery = normalizeArabicForSearch(query.trim());
    if (normalizedQuery.isEmpty) return [];

    final searchBox = await _boxManager!.ensureSearchIndexBoxOpen();

    final results = <Ayah>[];
    for (final ayahId in _searchAyahIds(surahNumber: surahNumber)) {
      final raw = searchBox.get(ayahId);
      if (raw == null) continue;

      final entry = parseSearchIndexEntry(raw);
      if (entry == null) continue;
      if (!entry.normalizedText.contains(normalizedQuery)) continue;

      final ayah = await _boxManager!.ayahsBox.get(ayahId);
      if (ayah == null) continue;

      results.add(ayah);
      if (results.length >= maxResults) break;
    }

    return results;
  }

  Iterable<int> _searchAyahIds({int? surahNumber}) {
    if (surahNumber == null) {
      return Iterable<int>.generate(_kAyahCount, (index) => index + 1);
    }

    final starts = _globalAyahIdStartBySurah;
    if (starts == null || surahNumber < 1 || surahNumber > 114) {
      return const Iterable<int>.empty();
    }

    final startId = starts[surahNumber];
    if (startId <= 0) return const Iterable<int>.empty();

    final count = _ayahCountForSurah(surahNumber);
    return Iterable<int>.generate(count, (index) => startId + index);
  }

  int _ayahCountForSurah(int surahNumber) {
    final fromCache = _surahCache[surahNumber]?.ayahCount;
    if (fromCache != null && fromCache > 0) return fromCache;
    return AyahIdResolver.ayahsPerSurah[surahNumber - 1];
  }

  int? _globalAyahId(int surah, int ayahInSurah) {
    final starts = _globalAyahIdStartBySurah;
    if (starts == null) return null;
    return AyahIdResolver.globalId(
      surah: surah,
      ayahInSurah: ayahInSurah,
      startsBySurah: starts,
      surahsByNumber: _surahCache,
    );
  }

  void _closeAndReset() {
    _boxManager?.dispose();
    _boxManager = null;
    _initCompleter = null;
    _surahCache.clear();
    _juzCache.clear();
    _basmalahCache = null;
    _globalAyahIdStartBySurah = null;
    _instance = null;
    _refCount = 0;
  }

  Future<void> _ensureReady() async {
    if (_boxManager == null) await ensureReady();
  }
}
