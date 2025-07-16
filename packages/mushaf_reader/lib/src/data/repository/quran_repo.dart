import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/line_model.dart';
import 'package:mushaf_reader/src/data/models/quran_page_model.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';

class QuranRepository {
  /// ---------------------------------------------------------------------------
  /// Cached state kept in memory once the JSON payloads are parsed.
  /// ---------------------------------------------------------------------------

  /// Page-level cache so that callers requesting the same page don't pay the
  /// parsing cost twice.
  final _pageCache = <int, QuranPageModel>{};

  /// Raw JSON structures decoded from the asset files.  The generics help us
  /// avoid repeated casts later on.
  List<Map<String, dynamic>>? _v4Surahs; // quran.json (code_v4)
  Map<int, List<Map<String, dynamic>>>?
  _hafsByPage; // quran_hafs.json (line info) indexed by page to avoid linear scans.

  /// Quick-look-up maps built during [ensureReady]. These make subsequent reads
  /// O(1) instead of a linear scan through the JSON.
  Map<int, String>? _codeV4ByAyahId;
  Map<int, _AyahMeta>? _ayahMetaById;
  Map<(int surah, int ayahInSurah), int>? _pair2Id;
  List<JuzModel>? _juzs;
  String? _basmalahGlyph;
  Map<int, String>? _surahGlyphByNumber;
  Map<int, bool>? _surahHasBasmalah;

  // Use a Completer to handle concurrent initialization requests
  Completer<void>? _initCompleter;

  /// ---------- INIT ----------
  Future<void> ensureReady() async {
    // If already initialized, return immediately
    if (_v4Surahs != null) return;

    // If initialization is in progress, wait for it to complete
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Start initialization
    _initCompleter = Completer<void>();

    try {
      // ---------------- Load & decode JSON asset ----------------
      final raw = await rootBundle.loadString(
        'packages/mushaf_reader/assets/jsons/quran.json',
      );
      final data =
          (json.decode(raw) as Map<String, dynamic>)['data']
              as Map<String, dynamic>;

      _v4Surahs = (data['surahs'] as List).cast<Map<String, dynamic>>();
      _juzs = (data['juzs'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (e) => JuzModel(
              number: e['number'] as int,
              codeV4: _toGlyph(e['code_v4'] as String),
            ),
          )
          .toList();
      _basmalahGlyph = (data['basmalah'] as List).reversed
          .cast<String>()
          .map(_toGlyph)
          .join();

      final hRaw = await rootBundle.loadString(
        'packages/mushaf_reader/assets/jsons/quran_hafs.json',
      );
      final rawHafs = (json.decode(hRaw) as List).cast<Map<String, dynamic>>();

      // Group HAFS entries by page and sort each list once.
      _hafsByPage = <int, List<Map<String, dynamic>>>{};
      for (final e in rawHafs) {
        final page = e['page'] as int;
        final list = _hafsByPage!.putIfAbsent(page, () => []);
        list.add(e);
      }
      for (final list in _hafsByPage!.values) {
        list.sort(
          (a, b) => (a['line_start'] as int).compareTo(b['line_start'] as int),
        );
      }

      // ---------------- Build helper indexes ----------------
      _codeV4ByAyahId = {};
      _ayahMetaById = {};
      _pair2Id = {};
      _surahGlyphByNumber = {};
      _surahHasBasmalah = {};

      for (final surah in _v4Surahs!) {
        final surahNumber = surah['number'] as int;
        for (final ayah in (surah['ayahs'] as List<dynamic>).cast<Map>()) {
          final id = ayah['number'] as int;
          _pair2Id![(surahNumber, ayah['numberInSurah'] as int)] = id;
          _codeV4ByAyahId![id] = ayah['code_v4'] as String;
          _ayahMetaById![id] = _AyahMeta(
            surah: surah['number'] as int,
            numberInSurah: ayah['numberInSurah'] as int,
            page: ayah['page'] as int,
          );

          // surah-level glyph (if present)
          final surahCode = surah['code_v4'];
          if (surahCode != null) {
            _surahGlyphByNumber![surahNumber] = _toGlyphIfNeeded(surahCode);
          }

          _surahHasBasmalah![surahNumber] = surah['hasBasmalah'] ?? true;
        }
      }

      // Free raw JSON to lower memory footprint – indexes are enough now.
      _v4Surahs = null;
      // rawHafs list can be GC'ed; we only keep indexed version.

      // Complete the initialization
      _initCompleter!.complete();
    } catch (error) {
      // Complete with error and reset completer
      _initCompleter!.completeError(error);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<AyahModel> getAyah(int ayahId) async {
    await ensureReady();
    final meta = _ayahMetaById![ayahId];
    if (meta == null) {
      throw ArgumentError('Ayah $ayahId not found');
    }

    return AyahModel(
      id: ayahId,
      surah: meta.surah,
      numberInSurah: meta.numberInSurah,
      page: meta.page,
      codeV4: _codeV4ByAyahId![ayahId]!,
    );
  }

  Future<AyahModel> getAyahBySurah(int surah, int ayahInSurah) async {
    await ensureReady();
    final id = _pair2Id![(surah, ayahInSurah)];
    if (id == null) {
      throw ArgumentError('Ayah $surah:$ayahInSurah not found');
    }
    return getAyah(id);
  }

  Future<String> getBasmalah() async {
    await ensureReady();
    return _basmalahGlyph!;
  }

  Future<JuzModel> getJuz(int number) async {
    await ensureReady();
    return _juzs!.firstWhere((j) => j.number == number);
  }

  /// ---------- JUZ & BASMALAH APIs ----------

  Future<List<JuzModel>> getJuzs() async {
    await ensureReady();
    return _juzs!;
  }

  /// ---------- PUBLIC READ APIs ----------
  Future<QuranPageModel> getPage(int page) async {
    await ensureReady();
    return _pageCache.putIfAbsent(page, () => _buildPage(page));
  }

  /// ---------- PRIVATE HELPERS ----------
  QuranPageModel _buildPage(int page) {
    // Use cached entries filtered once
    final pageEntries = _hafsByPage![page] ?? const <Map<String, dynamic>>[];

    if (pageEntries.isEmpty) {
      return QuranPageModel(
        pageNumber: page,
        glyphText: '',
        lines: [],
        surahs: [],
        juzNumber: 1,
      );
    }

    final buf = StringBuffer();
    final ayahFragments = <AyahFragment>[];

    // Build fragments in single pass
    for (final entry in pageEntries) {
      final start = buf.length;
      buf.write(_codeV4ByAyahId![entry['id']] ?? '');
      final end = buf.length;

      ayahFragments.add(
        AyahFragment(ayahId: entry['id'] as int, start: start, end: end),
      );
    }

    // Build lines more efficiently
    final lineMap = <int, List<Map<String, dynamic>>>{};
    for (final entry in pageEntries) {
      final lineStart = entry['line_start'] as int;
      lineMap.putIfAbsent(lineStart, () => []).add(entry);
    }

    final lines = <LineModel>[];
    final sortedLineEntries = lineMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    var lineIdx = 0;
    for (final entry in sortedLineEntries) {
      final lineData = entry.value.first;
      final start = lineData['line_start'] as int;
      final end = lineData['line_end'] as int;

      final frags = ayahFragments
          .where((f) => f.start >= start && f.end <= end)
          .toList();

      lines.add(
        LineModel(index: lineIdx++, start: start, end: end, fragments: frags),
      );
    }

    // Build surah blocks efficiently
    final surahBlocks = <SurahBlock>[];
    if (ayahFragments.isNotEmpty) {
      var currentStart = 0;
      var currentSurah = _ayahMetaById![ayahFragments.first.ayahId]!.surah;
      var firstNumInSurah =
          _ayahMetaById![ayahFragments.first.ayahId]!.numberInSurah;

      for (int i = 0; i < ayahFragments.length; i++) {
        final frag = ayahFragments[i];
        final surahNo = _ayahMetaById![frag.ayahId]!.surah;

        if (surahNo != currentSurah) {
          // Close previous block
          surahBlocks.add(
            SurahBlock(
              surahNumber: currentSurah,
              glyph: _surahGlyphByNumber![currentSurah] ?? '',
              start: currentStart,
              end: frag.start,
              hasBasmalah:
                  _surahHasBasmalah![currentSurah]! && firstNumInSurah == 1,
              ayahs: ayahFragments
                  .where((f) => f.start >= currentStart && f.end <= frag.start)
                  .toList(),
            ),
          );

          currentSurah = surahNo;
          currentStart = frag.start;
          firstNumInSurah = _ayahMetaById![frag.ayahId]!.numberInSurah;
        }
      }

      // Close final block
      surahBlocks.add(
        SurahBlock(
          surahNumber: currentSurah,
          glyph: _surahGlyphByNumber![currentSurah] ?? '',
          start: currentStart,
          end: buf.length,
          hasBasmalah:
              _surahHasBasmalah![currentSurah]! && firstNumInSurah == 1,
          ayahs: ayahFragments.where((f) => f.start >= currentStart).toList(),
        ),
      );
    }

    return QuranPageModel(
      pageNumber: page,
      glyphText: buf.toString(),
      lines: lines,
      surahs: surahBlocks,
      juzNumber: pageEntries.first['jozz'] as int,
    );
  }

  // ---------- UTIL ----------

  String _toGlyph(String code) {
    final hex = code.toUpperCase().replaceAll('U+', '');
    return String.fromCharCode(int.parse(hex, radix: 16));
  }

  // Helper converts code starting with U+ to glyph otherwise returns input
  String _toGlyphIfNeeded(String code) {
    if (code.startsWith('U+')) {
      return _toGlyph(code);
    }
    return code;
  }
}

// Lightweight immutable holder for frequently-looked-up ayah information.
class _AyahMeta {
  final int surah;
  final int numberInSurah;
  final int page;
  const _AyahMeta({
    required this.surah,
    required this.numberInSurah,
    required this.page,
  });
}
