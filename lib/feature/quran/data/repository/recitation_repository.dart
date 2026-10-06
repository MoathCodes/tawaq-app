import 'dart:async';

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
  new({required this._api, required this._cache, required this._logger});

  final Mp3QuranApi _api;
  final RecitationCache _cache;
  final Logger _logger;

  List<Reciter>? _memoryCatalog;
  Future<void>? _catalogRefresh;
  Future<List<Reciter>>? _catalogLoad;
  final LruMap<String, SurahTiming> _timingLru = LruMap(32);

  /// Returns the reciter catalog with timing links merged in. Served from the
  /// in-memory copy, then the disk cache, then the network.
  Future<List<Reciter>> reciters() {
    if (_memoryCatalog case final memory?) return Future.value(memory);
    return _catalogLoad ??= _loadCatalog().whenComplete(
      () => _catalogLoad = null,
    );
  }

  Future<List<Reciter>> _loadCatalog() async {
    final memory = _memoryCatalog;
    if (memory != null) return memory;

    final cached = await _cache.readCatalog(allowStale: true);
    if (cached != null) {
      try {
        final reciters = cached
            .map((entry) => Reciter.fromJson(entry as Map<String, dynamic>))
            .toList();
        _validateCatalog(reciters);
        _memoryCatalog = reciters;
        // Freshness controls refresh, never whether saved choices can restore.
        unawaited(_refreshIfStale());
        return reciters;
      } on Object catch (error) {
        _logger.w('Invalid cached reciter catalog: $error');
      }
    }

    final reciters = await _fetchAndMerge();
    _memoryCatalog = reciters;
    await _cache.writeCatalog(reciters.map((r) => r.toJson()).toList());
    return reciters;
  }

  Future<void> _refreshIfStale() async {
    if (await _cache.readCatalog() != null) return;
    await (_catalogRefresh ??= _refreshCatalog().whenComplete(() {
      _catalogRefresh = null;
    }));
  }

  Future<void> _refreshCatalog() async {
    try {
      final next = await _fetchAndMerge();
      if (next.isEmpty) return;
      await _cache.writeCatalog(next.map((r) => r.toJson()).toList());
      _memoryCatalog = next;
    } on Object catch (error) {
      _logger.w('Catalog refresh failed; retaining last-known catalog: $error');
    }
  }

  Future<List<Reciter>> _fetchAndMerge() async {
    final reciters = await _api.fetchReciters();
    _validateCatalog(reciters);
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
                    timingReadId:
                        readByServer[normalizeRecitationServerUrl(m.server)],
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  void _validateCatalog(List<Reciter> reciters) {
    final reciterIds = <int>{};
    if (reciters.isEmpty) throw const FormatException('Empty reciter catalog');
    for (final reciter in reciters) {
      if (reciter.id <= 0 ||
          reciter.name.trim().isEmpty ||
          !reciterIds.add(reciter.id) ||
          reciter.moshaf.isEmpty) {
        throw const FormatException('Invalid reciter identity');
      }
      final moshafIds = <int>{};
      for (final moshaf in reciter.moshaf) {
        final server = Uri.tryParse(moshaf.server);
        if (moshaf.id <= 0 ||
            !moshafIds.add(moshaf.id) ||
            moshaf.name.trim().isEmpty ||
            server == null ||
            !['http', 'https'].contains(server.scheme) ||
            server.host.isEmpty ||
            moshaf.surahList.isEmpty ||
            moshaf.surahList.any((s) => s < 1 || s > 114)) {
          throw const FormatException(
            'Invalid moshaf identity or audio source',
          );
        }
      }
    }
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
  /// - When [persist] is false and the surah is not cached, returns the
  ///   network URL immediately without writing any files.
  /// - Otherwise the download is attempted (honoring [cancellationToken]);
  ///   the `progress` stream carries the emitted [DownloadProgress] events.
  ///   - On success the cached `file://` URI is returned.
  ///   - A failed or cancelled save returns the stream URL. Partial files are
  ///     never used for playback.
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
    bool persist = true,
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
    if (!persist) {
      return (uri: url, progress: null);
    }

    final token = cancellationToken ?? CancellationToken();
    final events = <DownloadProgress>[];
    try {
      // Drain the download stream, collecting progress events to replay on the
      // returned `progress` stream. `Stream.forEach` propagates download
      // errors, which are caught below. [onProgress] is forwarded each event
      // live so callers (e.g. the recitation controller) can drive a progress
      // UI without waiting for the awaited resolution.
      await _cache
          .downloadAudio(
            reciterId: reciter.id,
            moshafId: moshaf.id,
            surah: surah,
            reciterName: reciter.name,
            riwayahName: moshaf.name,
            surahName: surahName,
            url: url,
            cancellationToken: token,
          )
          .forEach((event) {
            events.add(event);
            onProgress?.call(event);
          });
    } on Object catch (error, stack) {
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

    // Cancelled, or failed with no usable .part -> fall back to network.
    return (uri: url, progress: progressStream);
  }

  /// Downloads [surah] audio into the on-disk cache for offline playback.
  ///
  /// No-ops when the file is already cached. Does not start or stop playback.
  Future<void> saveSurahAudio({
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
      final size = cached.lengthSync();
      onProgress?.call(DownloadProgress(receivedBytes: size, totalBytes: size));
      return;
    }

    final url = surahAudioUrl(moshaf.server, surah);
    final token = cancellationToken ?? CancellationToken();
    await _cache
        .downloadAudio(
          reciterId: reciter.id,
          moshafId: moshaf.id,
          surah: surah,
          reciterName: reciter.name,
          riwayahName: moshaf.name,
          surahName: surahName,
          url: url,
          cancellationToken: token,
        )
        .forEach((event) => onProgress?.call(event));
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
}
