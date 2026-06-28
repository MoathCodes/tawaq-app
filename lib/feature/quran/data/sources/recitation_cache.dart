import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tawaq/core/utils/cancellation_token.dart';

/// A cached surah audio file on disk.
class CachedRecitation {
  /// Creates a [CachedRecitation].
  const CachedRecitation({
    required this.reciterId,
    required this.moshafId,
    required this.surah,
    required this.file,
    required this.sizeBytes,
  });

  /// The reciter the audio belongs to.
  final int reciterId;

  /// The moshaf (riwayah) the audio belongs to.
  final int moshafId;

  /// The surah number (1-114).
  final int surah;

  /// The on-disk file.
  final File file;

  /// File size in bytes.
  final int sizeBytes;
}

/// Progress of an in-flight surah download.
class DownloadProgress {
  /// Creates [DownloadProgress].
  const DownloadProgress({required this.receivedBytes, this.totalBytes});

  /// Bytes received so far.
  final int receivedBytes;

  /// Total bytes to receive, or null when unknown (no Content-Length).
  final int? totalBytes;

  /// Completion fraction in `[0, 1]`, or null when [totalBytes] is unknown.
  double? get fraction {
    final total = totalBytes;
    if (total == null || total == 0) return null;
    return receivedBytes / total;
  }
}

/// Plain scan result reconstructed into [CachedRecitation] on the main isolate.
typedef _CachedScanEntry = ({
  int reciterId,
  int moshafId,
  int surah,
  String path,
  int sizeBytes,
});

List<_CachedScanEntry> _scanCachedRecitations(String audioDirPath) {
  final result = <_CachedScanEntry>[];
  final dir = Directory(audioDirPath);
  if (!dir.existsSync()) return result;
  for (final entity in dir.listSync()) {
    if (entity is! Directory) continue;
    final ids = RegExp(
      r'^(\d+)-(\d+)\b',
    ).firstMatch(p.basename(entity.path));
    if (ids == null) continue;
    final reciterId = int.parse(ids.group(1)!);
    final moshafId = int.parse(ids.group(2)!);
    for (final file in entity.listSync()) {
      if (file is! File || !file.path.endsWith('.mp3')) continue;
      final surahMatch = RegExp(
        r'^(\d{1,3})\b',
      ).firstMatch(p.basenameWithoutExtension(file.path));
      if (surahMatch == null) continue;
      result.add(
        (
          reciterId: reciterId,
          moshafId: moshafId,
          surah: int.parse(surahMatch.group(1)!),
          path: file.path,
          sizeBytes: file.lengthSync(),
        ),
      );
    }
  }
  result.sort((a, b) {
    final r = a.reciterId.compareTo(b.reciterId);
    if (r != 0) return r;
    final m = a.moshafId.compareTo(b.moshafId);
    return m != 0 ? m : a.surah.compareTo(b.surah);
  });
  return result;
}

/// On-disk cache for recitation audio plus the reciter catalog and ayah-timing
/// JSON, so playback never re-hits the network for the same content.
///
/// Layout (under the app support directory). Audio folders/files carry both
/// machine ids (a leading `<reciterId>-<moshafId>` / `<NNN>` token, for
/// deterministic lookup) and a human-readable label so the cache is browsable
/// and copyable in a file manager:
/// ```text
/// tawaq/recitations/
///   catalog.json                  // reciter catalog (+ timing links)
///   timing/<readId>_<surah>.json  // per-surah ayah timing
///   audio/<reciterId>-<moshafId> <ReciterName> — <Riwayah>/<NNN> <SurahName>.mp3
/// ```
class RecitationCache {
  /// Creates a [RecitationCache]. [rootOverride] is for tests; production code
  /// leaves it null so the app-support directory is used.
  RecitationCache({
    required this._client,
    required this._logger,
    this.rootOverride,
  });

  final http.Client _client;
  final Logger _logger;

  /// When non-null, used as the cache root instead of the app-support dir.
  /// Test-only.
  final Directory? rootOverride;

  /// Catalog entries older than this are refetched.
  static const catalogTtl = Duration(days: 7);

  /// Schema version of the cached catalog. Bump to invalidate catalogs written
  /// by older builds (e.g. v2 fixed missing ayah-timing links).
  static const catalogVersion = 2;

  Directory? _root;
  final Set<String> _inFlight = {};

  Future<Directory> _ensureRoot() async {
    final cached = _root;
    if (cached != null) return cached;
    final Directory dir;
    if (rootOverride != null) {
      dir = rootOverride!;
    } else {
      final support = await getApplicationSupportDirectory();
      dir = Directory(p.join(support.path, 'tawaq', 'recitations'));
    }
    await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  // ---- Audio -------------------------------------------------------------

  /// Strips path-unsafe characters so a label is safe as a file/dir name.
  /// Arabic and other UTF-8 text is preserved.
  static String _sanitize(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? '_' : cleaned;
  }

  String _surahFileName(int surah, String surahName) =>
      '${surah.toString().padLeft(3, '0')} ${_sanitize(surahName)}.mp3';

  String _reciterDirName(
    int reciterId,
    int moshafId,
    String reciterName,
    String riwayahName,
  ) =>
      '$reciterId-$moshafId ${_sanitize(reciterName)} '
      '— ${_sanitize(riwayahName)}';

  Future<File> _audioFile({
    required int reciterId,
    required int moshafId,
    required int surah,
    required String reciterName,
    required String riwayahName,
    required String surahName,
  }) async {
    final root = await _ensureRoot();
    return File(
      p.join(
        root.path,
        'audio',
        _reciterDirName(reciterId, moshafId, reciterName, riwayahName),
        _surahFileName(surah, surahName),
      ),
    );
  }

  /// Returns the cached surah audio file, or null when not yet downloaded.
  Future<File?> cachedAudio({
    required int reciterId,
    required int moshafId,
    required int surah,
    required String reciterName,
    required String riwayahName,
    required String surahName,
  }) async {
    final file = await _audioFile(
      reciterId: reciterId,
      moshafId: moshafId,
      surah: surah,
      reciterName: reciterName,
      riwayahName: riwayahName,
      surahName: surahName,
    );
    return file.existsSync() ? file : null;
  }

  /// Minimum `.part` size considered playable when a download fails mid-way.
  ///
  /// Anything smaller is almost certainly not a decodable MP3 frame sequence,
  /// so it is deleted and the caller falls back to the network URL.
  static const kMinPlayablePartBytes = 1024;

  /// Returns the partially-downloaded `.part` file for [surah] when it exists
  /// and is at least [minBytes] large, else null.
  ///
  /// Used after a failed download to hand mpv the partial file so playback can
  /// still proceed from whatever was received. An undersized `.part` is
  /// deleted (cleaned up) so it does not accumulate.
  Future<File?> partAudioIfLargeEnough({
    required int reciterId,
    required int moshafId,
    required int surah,
    required String reciterName,
    required String riwayahName,
    required String surahName,
    int minBytes = kMinPlayablePartBytes,
  }) async {
    final file = await _audioFile(
      reciterId: reciterId,
      moshafId: moshafId,
      surah: surah,
      reciterName: reciterName,
      riwayahName: riwayahName,
      surahName: surahName,
    );
    final part = File('${file.path}.part');
    if (!part.existsSync()) return null;
    final size = await part.length();
    if (size < minBytes) {
      try {
        await part.delete();
      } on Object catch (_) {}
      return null;
    }
    return part;
  }

  /// Downloads the surah audio, streaming [DownloadProgress].
  ///
  /// Streams to a `.part` file and atomically renames on success so a partial
  /// file is never treated as cached. Safe to call repeatedly; concurrent
  /// duplicates are ignored (the stream completes immediately with no events).
  ///
  /// On [cancellationToken] cancellation the `.part` file is deleted and the
  /// stream ends without renaming. On other errors the error is added to the
  /// stream and the `.part` file is deleted.
  Stream<DownloadProgress> downloadAudio({
    required int reciterId,
    required int moshafId,
    required int surah,
    required String reciterName,
    required String riwayahName,
    required String surahName,
    required String url,
    required CancellationToken cancellationToken,
  }) async* {
    final file = await _audioFile(
      reciterId: reciterId,
      moshafId: moshafId,
      surah: surah,
      reciterName: reciterName,
      riwayahName: riwayahName,
      surahName: surahName,
    );
    if (file.existsSync()) {
      final size = file.lengthSync();
      yield DownloadProgress(receivedBytes: size, totalBytes: size);
      return;
    }
    final key = file.path;
    if (_inFlight.contains(key)) {
      // Another download is already reporting progress elsewhere.
      return;
    }
    _inFlight.add(key);
    final part = File('${file.path}.part');
    try {
      await file.parent.create(recursive: true);
      final request = http.Request('GET', Uri.parse(url));
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw HttpException('GET $url failed with ${response.statusCode}');
      }
      final totalBytes = response.contentLength;
      yield DownloadProgress(receivedBytes: 0, totalBytes: totalBytes);
      final sink = part.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          if (cancellationToken.isCancelled) break;
          sink.add(chunk);
          received += chunk.length;
          yield DownloadProgress(
            receivedBytes: received,
            totalBytes: totalBytes,
          );
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (cancellationToken.isCancelled) {
        if (part.existsSync()) {
          try {
            await part.delete();
          } on Object catch (_) {}
        }
        _logger.i('Download canceled $reciterId/$surah');
        return;
      }
      await part.rename(file.path);
      _logger.i('Cached recitation $reciterId/$surah');
      yield DownloadProgress(
        receivedBytes: received,
        totalBytes: totalBytes ?? received,
      );
    } on Object catch (error, stack) {
      _logger.w(
        'Failed to cache recitation $reciterId/$surah',
        error: error,
        stackTrace: stack,
      );
      // NOTE: the `.part` file is intentionally KEPT on error (not deleted)
      // so a caller can hand mpv the partially-downloaded file when it is
      // large enough to play. Callers inspect it via
      // [partAudioIfLargeEnough], which cleans up undersized parts. Only
      // explicit cancellation deletes the `.part` (handled above).
      rethrow;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// The directory holding cached surah audio (`audio/<reciterId>/<NNN>.mp3`).
  Future<Directory> audioDirectory() async {
    final root = await _ensureRoot();
    final dir = Directory(p.join(root.path, 'audio'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Lists every cached surah audio file with its reciter id, surah, and size.
  Future<List<CachedRecitation>> listCached() async {
    final dir = await audioDirectory();
    final scanned = await Isolate.run(() => _scanCachedRecitations(dir.path));
    return [
      for (final entry in scanned)
        CachedRecitation(
          reciterId: entry.reciterId,
          moshafId: entry.moshafId,
          surah: entry.surah,
          file: File(entry.path),
          sizeBytes: entry.sizeBytes,
        ),
    ];
  }

  /// Total bytes used by cached audio.
  Future<int> totalCacheBytes() async {
    final files = await listCached();
    return files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
  }

  /// Deletes a cached audio file.
  Future<void> deleteCached(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object catch (error) {
      _logger.w('Failed to delete cached recitation $path: $error');
    }
  }

  // ---- Catalog -----------------------------------------------------------

  Future<File> _catalogFile() async {
    final root = await _ensureRoot();
    return File(p.join(root.path, 'catalog.json'));
  }

  /// Reads the cached reciter catalog as raw JSON, or null when missing/stale.
  Future<List<dynamic>?> readCatalog() async {
    try {
      final file = await _catalogFile();
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      if (json['version'] != catalogVersion) return null;
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > catalogTtl) {
        return null;
      }
      return json['reciters'] as List<dynamic>?;
    } on Object catch (error) {
      _logger.w('Failed to read recitation catalog: $error');
      return null;
    }
  }

  /// Persists the reciter catalog JSON.
  Future<void> writeCatalog(List<Map<String, dynamic>> reciters) async {
    try {
      final file = await _catalogFile();
      await file.writeAsString(
        jsonEncode({
          'version': catalogVersion,
          'savedAt': DateTime.now().toIso8601String(),
          'reciters': reciters,
        }),
      );
    } on Object catch (error) {
      _logger.w('Failed to write recitation catalog: $error');
    }
  }

  // ---- Timing ------------------------------------------------------------

  Future<File> _timingFile(int readId, int surah) async {
    final root = await _ensureRoot();
    return File(p.join(root.path, 'timing', '${readId}_$surah.json'));
  }

  /// Reads cached ayah timing JSON for a read+surah, or null when missing.
  Future<Map<String, dynamic>?> readTiming(int readId, int surah) async {
    try {
      final file = await _timingFile(readId, surah);
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      return json is Map<String, dynamic> ? json : null;
    } on Object catch (error) {
      _logger.w('Failed to read timing $readId/$surah: $error');
      return null;
    }
  }

  /// Persists ayah timing JSON for a read+surah.
  Future<void> writeTiming(
    int readId,
    int surah,
    Map<String, dynamic> json,
  ) async {
    try {
      final file = await _timingFile(readId, surah);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(json));
    } on Object catch (error) {
      _logger.w('Failed to write timing $readId/$surah: $error');
    }
  }
}
