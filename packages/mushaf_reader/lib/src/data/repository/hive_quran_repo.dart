import 'dart:async';

import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/line_model.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/quran_page_model.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';
import 'package:mushaf_reader/src/data/models/surah_model.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// Hive-based implementation of [IQuranRepository].
///
/// This repository provides efficient access to Quran data stored in
/// pre-populated Hive boxes. Boxes are bundled as assets and copied
/// to the app directory on first launch.
///
/// ## Box Structure
///
/// - **surahs**: `Box<SurahModel>` keyed by surah number (1-114)
/// - **ayahs**: `LazyBox<AyahModel>` keyed by ayah ID (1-6236)
/// - **juzs**: `Box<JuzModel>` keyed by juz number (1-30)
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
/// - [MushafController], which uses this repository
/// - [HiveBoxManager], which manages the underlying boxes
class HiveQuranRepository implements IQuranRepository {
  /// The singleton instance of the repository.
  static HiveQuranRepository? _instance;

  /// Reference count for automatic cleanup.
  static int _refCount = 0;

  /// Maximum number of pages to keep in the LRU cache.
  static const int _kMaxCacheSize = 10;

  /// The Hive box manager.
  HiveBoxManager? _boxManager;

  /// Whether initialization is in progress.
  Completer<void>? _initCompleter;

  /// LRU cache for recently accessed page models.
  final _pageCache = <int, QuranPageModel>{};

  /// Cached Surah data for quick access.
  final _surahCache = <int, SurahModel>{};

  /// Cached Juz data for quick access.
  final _juzCache = <int, JuzModel>{};

  /// Cached Basmalah glyph.
  String? _basmalahCache;

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
      _boxManager = HiveBoxManager();
      await _boxManager!.init();

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

      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    await _ensureReady();
    return _surahCache.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Future<AyahModel> getAyah(int ayahId, [bool removeNewLines = true]) async {
    await _ensureReady();
    final ayah = await _boxManager!.ayahsBox.get(ayahId);
    if (ayah == null) throw ArgumentError('Ayah $ayahId not found');
    if (removeNewLines) {
      return ayah.copyWith(text: ayah.text.replaceAll('\n', ''));
    }
    return ayah;
  }

  @override
  Future<AyahModel> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async {
    await _ensureReady();
    // We need to search for the ayah by surah and number within surah
    // This requires scanning since we're keyed by global ID
    // For efficiency, we can calculate the approximate range

    // Calculate starting ayah ID for this surah (need surah order)
    // For now, do a scan - could be optimized with a lookup table
    for (int id = 1; id <= 6236; id++) {
      final ayah = await _boxManager!.ayahsBox.get(id);
      if (ayah != null &&
          ayah.surah == surah &&
          ayah.numberInSurah == ayahInSurah) {
        if (removeNewLines) {
          return ayah.copyWith(text: ayah.text.replaceAll('\n', ''));
        }
        return ayah;
      }
    }
    throw ArgumentError('Ayah $surah:$ayahInSurah not found');
  }

  @override
  Future<String> getBasmalah() async {
    await _ensureReady();
    return _basmalahCache ?? '';
  }

  @override
  String? getBasmalahSync() => _basmalahCache;

  @override
  Future<JuzModel> getJuz(int number) async {
    await _ensureReady();
    final juz = _juzCache[number];
    if (juz == null) throw ArgumentError('Juz $number not found');
    return juz;
  }

  @override
  Future<List<JuzModel>> getJuzs() async {
    await _ensureReady();
    return _juzCache.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Map<int, JuzModel> getJuzsSync() => Map.unmodifiable(_juzCache);

  @override
  Future<int> getJuzStartPage(int juzNumber) async {
    await _ensureReady();
    // Use pre-computed startPage from JuzModel (O(1))
    final juz = _juzCache[juzNumber];
    if (juz?.startPage != null) {
      return juz!.startPage!;
    }
    // Fallback: find the first ayah of this juz (O(n))
    for (int id = 1; id <= 6236; id++) {
      final ayah = await _boxManager!.ayahsBox.get(id);
      if (ayah != null && ayah.juz == juzNumber) {
        return ayah.page;
      }
    }
    throw ArgumentError('Juz $juzNumber not found');
  }

  @override
  JuzModel? getJuzSync(int number) => _juzCache[number];

  @override
  Future<QuranPageModel> getPage(int page) async {
    await _ensureReady();

    // Check cache first (LRU)
    if (_pageCache.containsKey(page)) {
      final data = _pageCache.remove(page)!;
      _pageCache[page] = data;
      return data;
    }

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
    // Fallback: find first ayah of this surah
    for (int id = 1; id <= 6236; id++) {
      final ayah = await _boxManager!.ayahsBox.get(id);
      if (ayah != null && ayah.surah == surahNumber) {
        return ayah.page;
      }
    }
    throw ArgumentError('Surah $surahNumber not found');
  }

  @override
  Future<SurahModel?> getSurah(int surahNumber) async {
    await _ensureReady();
    return _surahCache[surahNumber];
  }

  @override
  List<SurahModel> getSurahsSync() {
    return _surahCache.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  /// Builds a complete [QuranPageModel] from Hive data.
  Future<QuranPageModel> _buildPage(int page) async {
    // Get page layouts using the helper method
    final layouts = _boxManager!.getLayoutsForPage(page);
    if (layouts.isEmpty) {
      return QuranPageModel(
        pageNumber: page,
        glyphText: '',
        lines: [],
        surahs: [],
        juzNumber: 1,
      );
    }

    // Fetch all ayahs for this page
    final ayahMap = <int, AyahModel>{};
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

    // Build lines
    final lineMap = <int, List<PageLayouts>>{};
    for (final layout in sortedLayouts) {
      (lineMap[layout.lineStart] ??= []).add(layout);
    }

    final sortedLineStarts = lineMap.keys.toList()..sort();
    final lines = <LineModel>[];
    var lineIndex = 0;

    for (final lineStart in sortedLineStarts) {
      final lineLayouts = lineMap[lineStart]!;
      final lineEnd = lineLayouts.first.lineEnd;

      // Filter fragments for this line
      final frags = ayahFragments
          .where((f) => f.start >= lineStart && f.end <= lineEnd)
          .toList();

      lines.add(
        LineModel(
          index: lineIndex++,
          start: lineStart,
          end: lineEnd,
          fragments: frags,
        ),
      );
    }

    // Build Surah blocks
    final surahBlocks = <SurahBlock>[];
    if (ayahFragments.isNotEmpty) {
      var currentStart = 0;
      var firstAyah = ayahMap[ayahFragments.first.ayahId]!;
      var currentSurahId = firstAyah.surah;
      var firstNumInSurah = firstAyah.numberInSurah;
      var currentBlockFragments = <AyahFragment>[];
      var currentSurah = _surahCache[currentSurahId];

      for (final frag in ayahFragments) {
        final ayah = ayahMap[frag.ayahId]!;

        if (ayah.surah != currentSurahId) {
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
          currentSurahId = ayah.surah;
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

    return QuranPageModel(
      pageNumber: page,
      glyphText: buf.toString(),
      lines: lines,
      surahs: surahBlocks,
      juzNumber: juz,
    );
  }

  void _closeAndReset() {
    _boxManager?.dispose();
    _boxManager = null;
    _initCompleter = null;
    _surahCache.clear();
    _juzCache.clear();
    _basmalahCache = null;
    _instance = null;
    _refCount = 0;
  }

  Future<void> _ensureReady() async {
    if (_boxManager == null) await ensureReady();
  }
}
