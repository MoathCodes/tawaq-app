import 'dart:io';

import 'package:logger/logger.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/utils/lru_map.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_url_builder.dart';

/// Coordinates the mp3quran API and the on-disk cache for recitation data.
class RecitationRepository {
  /// Creates a [RecitationRepository].
  RecitationRepository({
    required this._api,
    required this._cache,
    required this._logger,
  });

  final Mp3QuranApi _api;
  final RecitationCache _cache;
  final Logger _logger;

  List<Reciter>? _memoryCatalog;
  final LruMap<String, SurahTiming> _timingLru = LruMap(32);

  /// Returns the reciter catalog with timing links merged in. Served from the
  /// in-memory copy, then the disk cache, then the network.
  Future<List<Reciter>> reciters() async {
    final memory = _memoryCatalog;
    if (memory != null) return memory;

    final cached = await _cache.readCatalog();
    if (cached != null) {
      final reciters = cached
          .whereType<Map<String, dynamic>>()
          .map(Reciter.fromJson)
          .toList();
      _memoryCatalog = reciters;
      return reciters;
    }

    final reciters = await _fetchAndMerge();
    _memoryCatalog = reciters;
    await _cache.writeCatalog(reciters.map((r) => r.toJson()).toList());
    return reciters;
  }

  Future<List<Reciter>> _fetchAndMerge() async {
    final reciters = await _api.fetchReciters();
    List<TimingRead> reads;
    try {
      reads = await _api.fetchTimingReads();
    } on Object catch (error) {
      // Timing is optional; degrade to audio-only when the reads call fails.
      _logger.w('Failed to load ayat_timing reads: $error');
      reads = const [];
    }
    final readByServer = {
      for (final r in reads) normalizeRecitationServerUrl(r.folderUrl): r.id,
    };

    return reciters
        .map(
          (reciter) => reciter.copyWith(
            moshaf: reciter.moshaf
                .map(
                  (m) => m.copyWith(
                    timingReadId: readByServer[normalizeRecitationServerUrl(
                      m.server,
                    )],
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Returns per-ayah timing for [surah] from [readId], or null on failure.
  Future<SurahTiming?> timing(int surah, int readId) async {
    final key = '$readId-$surah';
    final cachedTiming = _timingLru[key];
    if (cachedTiming != null) return cachedTiming;

    final cached = await _cache.readTiming(readId, surah);
    if (cached != null) {
      try {
        final timing = SurahTiming.fromJson(cached);
        _timingLru[key] = timing;
        return timing;
      } on Object catch (error) {
        _logger.w('Corrupt cached timing $readId/$surah: $error');
      }
    }
    try {
      final timing = await _api.fetchSurahTiming(surah, readId);
      await _cache.writeTiming(readId, surah, timing.toJson());
      _timingLru[key] = timing;
      return timing;
    } on Object catch (error) {
      _logger.w('Failed to load timing $readId/$surah: $error');
      return null;
    }
  }

  /// Resolves the playable URI for [surah] in [moshaf].
  ///
  /// Returns a `file://` URI after ensuring the audio is cached locally.
  /// [reciter] and [surahName] are used only to build the human-readable,
  /// riwayah-scoped cache path.
  Future<String> resolveSurahUri({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
    required String surahName,
  }) async {
    final cached = await _cache.cachedAudio(
      reciterId: reciter.id,
      moshafId: moshaf.id,
      surah: surah,
      reciterName: reciter.name,
      riwayahName: moshaf.name,
      surahName: surahName,
    );
    if (cached != null) return cached.uri.toString();

    final url = surahAudioUrl(moshaf.server, surah);
    await _cache.downloadAudio(
      reciterId: reciter.id,
      moshafId: moshaf.id,
      surah: surah,
      reciterName: reciter.name,
      riwayahName: moshaf.name,
      surahName: surahName,
      url: url,
    );

    final file = await _cache.cachedAudio(
      reciterId: reciter.id,
      moshafId: moshaf.id,
      surah: surah,
      reciterName: reciter.name,
      riwayahName: moshaf.name,
      surahName: surahName,
    );
    if (file != null) return file.uri.toString();

    return url;
  }

  /// Lists every cached surah audio file.
  Future<List<CachedRecitation>> listCached() => _cache.listCached();

  /// Total bytes used by cached surah audio.
  Future<int> totalCacheBytes() => _cache.totalCacheBytes();

  /// Deletes a cached audio file at [path].
  Future<void> deleteCached(String path) => _cache.deleteCached(path);

  /// The directory holding cached surah audio.
  Future<Directory> audioDirectory() => _cache.audioDirectory();
}
