import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/utils/cancellation_token.dart';
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

  /// Resolves the playable URI for [surah] in [moshaf], optionally streaming
  /// download progress.
  ///
  /// Returns a record of `uri` and a nullable `progress` stream:
  /// - When the surah is already cached, returns the cached `file://` URI and
  ///   a `null` progress stream (no download occurs).
  /// - Otherwise the download is attempted (honoring [cancellationToken]);
  ///   the `progress` stream carries the emitted [DownloadProgress] events.
  ///   - On success the cached `file://` URI is returned.
  ///   - On a mid-download failure, if the partial `.part` file is large
  ///     enough to play, its `file://` URI is handed to mpv so playback can
  ///     proceed from whatever was received.
  ///   - Otherwise (cancellation, or failure with no usable `.part`) the
  ///     network `url` is returned as a fallback.
  ///
  /// [reciter] and [surahName] are used only to build the human-readable,
  /// riwayah-scoped cache path.
  ///
  /// [onProgress], if given, is invoked for each [DownloadProgress] event as
  /// it arrives during the download (live), in addition to the events being
  /// replayed on the returned `progress` stream. Use it to drive a progress UI
  /// without awaiting this future.
  Future<({String uri, Stream<DownloadProgress>? progress})> resolveSurahUri({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
    required String surahName,
    CancellationToken? cancellationToken,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final cached = await _cache.cachedAudio(
      reciterId: reciter.id,
      moshafId: moshaf.id,
      surah: surah,
      reciterName: reciter.name,
      riwayahName: moshaf.name,
      surahName: surahName,
    );
    if (cached != null) {
      return (uri: cached.uri.toString(), progress: null);
    }

    final url = surahAudioUrl(moshaf.server, surah);
    final token = cancellationToken ?? CancellationToken();
    final events = <DownloadProgress>[];
    Object? failure;
    try {
      // Drain the download stream, collecting progress events to replay on the
      // returned `progress` stream. `Stream.forEach` propagates download
      // errors, which are caught below. [onProgress] is forwarded each event
      // live so callers (e.g. the recitation controller) can drive a progress
      // UI without waiting for the awaited resolution.
      await _cache.downloadAudio(
        reciterId: reciter.id,
        moshafId: moshaf.id,
        surah: surah,
        reciterName: reciter.name,
        riwayahName: moshaf.name,
        surahName: surahName,
        url: url,
        cancellationToken: token,
      ).forEach((event) {
        events.add(event);
        onProgress?.call(event);
      });
    } on Object catch (error, stack) {
      failure = error;
      _logger.w(
        'Recitation download failed, evaluating fallback: $error',
        stackTrace: stack,
      );
    }

    final progressStream = Stream<DownloadProgress>.fromIterable(events);

    // Download succeeded -> play the cached file.
    final file = await _cache.cachedAudio(
      reciterId: reciter.id,
      moshafId: moshaf.id,
      surah: surah,
      reciterName: reciter.name,
      riwayahName: moshaf.name,
      surahName: surahName,
    );
    if (file != null) {
      return (uri: file.uri.toString(), progress: progressStream);
    }

    // Download failed mid-way -> hand mpv the partial .part if playable.
    if (failure != null) {
      final part = await _cache.partAudioIfLargeEnough(
        reciterId: reciter.id,
        moshafId: moshaf.id,
        surah: surah,
        reciterName: reciter.name,
        riwayahName: moshaf.name,
        surahName: surahName,
      );
      if (part != null) {
        _logger.i('Streaming from partial .part for surah $surah');
        return (uri: part.uri.toString(), progress: progressStream);
      }
    }

    // Cancelled, or failed with no usable .part -> fall back to network.
    return (uri: url, progress: progressStream);
  }

  /// Whether the audio for [surah] is already cached locally.
  Future<bool> isSurahCached({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
    required String surahName,
  }) async {
    final file = await _cache.cachedAudio(
      reciterId: reciter.id,
      moshafId: moshaf.id,
      surah: surah,
      reciterName: reciter.name,
      riwayahName: moshaf.name,
      surahName: surahName,
    );
    return file != null;
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
