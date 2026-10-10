import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:tawaq/core/storage/app_storage_paths.dart';
import 'package:tawaq/core/utils/cancellation_token.dart';

/// A cached surah audio file on disk.
class CachedRecitation {
  /// Creates a [CachedRecitation].
  const new({
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
  const new({required this.receivedBytes, this.totalBytes});

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

/// Explicit offline-save progress scoped to a surah identity.
class OfflineSaveSnapshot {
  /// Creates [OfflineSaveSnapshot].
  const new({
    required this.reciterId,
    required this.moshafId,
    required this.surah,
    required this.progress,
  });

  /// Reciter id for the surah being saved.
  final int reciterId;

  /// Moshaf id for the surah being saved.
  final int moshafId;

  /// Surah number (1-114) being saved.
  final int surah;

  /// Latest download progress for this save.
  final DownloadProgress progress;

  /// Whether this snapshot targets the given surah identity.
  bool matches({
    required int reciterId,
    required int moshafId,
    required int surah,
  }) =>
      this.reciterId == reciterId &&
      this.moshafId == moshafId &&
      this.surah == surah;
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
    final ids = RegExp(r'^(\d+)-(\d+)\b').firstMatch(p.basename(entity.path));
    if (ids == null) continue;
    final reciterId = int.parse(ids.group(1)!);
    final moshafId = int.parse(ids.group(2)!);
    for (final file in entity.listSync()) {
      if (file is! File || !file.path.endsWith('.mp3')) continue;
      final surahMatch = RegExp(r'^(\d{1,3})\b')
          .firstMatch(p.basenameWithoutExtension(file.path));
      if (surahMatch == null) continue;
      result.add((
        reciterId: reciterId,
        moshafId: moshafId,
        surah: int.parse(surahMatch.group(1)!),
        path: file.path,
        sizeBytes: file.lengthSync(),
      ));
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

class _AudioDownload {
  final progress = StreamController<DownloadProgress>.broadcast(sync: true);
  final done = Completer<void>();
  final token = CancellationToken();
  int owners = 0;
  DownloadProgress? latest;
  Object? error;
  StackTrace? stack;

  void publish(DownloadProgress event) {
    latest = event;
    progress.add(event);
  }
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
  new({required this._client, required this._logger, this.rootOverride});

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
  final Map<String, _AudioDownload> _inFlight = {};

  Future<Directory> _ensureRoot() async {
    final cached = _root;
    if (cached != null) return cached;
    final Directory dir;
    if (rootOverride != null) {
      dir = rootOverride!;
    } else {
      final storagePaths = await AppStoragePaths.resolve();
      dir = storagePaths.recitations;
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

  /// Saves a complete file. Callers share acquisition by exact cache path.
  /// Each active subscriber owns a share; only the final cancellation aborts
  /// the underlying request. Neither partial nor failed files become playable.
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
    if (cancellationToken.isCancelled) return;
    final file = await _audioFile(
      reciterId: reciterId,
      moshafId: moshafId,
      surah: surah,
      reciterName: reciterName,
      riwayahName: riwayahName,
      surahName: surahName,
    );
    if (cancellationToken.isCancelled) return;
    if (file.existsSync()) {
      final size = file.lengthSync();
      yield DownloadProgress(receivedBytes: size, totalBytes: size);
      return;
    }
    // A cancelled acquisition must finish cleaning its staging file before
    // another request for the same identity can take ownership of that path.
    final abandoned = _inFlight[file.path];
    if (abandoned != null && abandoned.token.isCancelled) {
      await abandoned.done.future;
    }
    if (cancellationToken.isCancelled) return;
    final existing = _inFlight[file.path];
    final download = existing ?? _AudioDownload();
    _inFlight[file.path] = download;
    download.owners++;
    var released = false;
    void release() {
      if (released) return;
      released = true;
      if (--download.owners == 0 && !download.done.isCompleted) {
        download.token.cancel();
      }
    }

    final removeCancel = cancellationToken.onCancel(release);
    final output = StreamController<DownloadProgress>();
    final subscription = download.progress.stream.listen(
      output.add,
      onDone: output.close,
    );
    final latest = download.latest;
    if (latest != null) output.add(latest);
    final stopForwarding = cancellationToken.onCancel(() {
      unawaited(subscription.cancel());
      unawaited(output.close());
    });
    if (existing == null) unawaited(_downloadFile(file, url, download));
    try {
      yield* output.stream;
      if (!cancellationToken.isCancelled && download.error != null) {
        Error.throwWithStackTrace(download.error!, download.stack!);
      }
    } finally {
      removeCancel();
      stopForwarding();
      release();
      await subscription.cancel();
      // The final subscriber acknowledges cancellation after actual cleanup.
      if (download.owners == 0) await download.done.future;
    }
  }

  Future<void> _downloadFile(
    File file,
    String url,
    _AudioDownload download,
  ) async {
    final part = File('${file.path}.part');
    final token = download.token;
    IOSink? sink;
    StreamSubscription<List<int>>? body;
    try {
      await file.parent.create(recursive: true);
      if (token.isCancelled) return;
      final request = http.AbortableRequest(
        'GET',
        Uri.parse(url),
        abortTrigger: token.whenCancelled,
      );
      final response = await Future.any([
        _client.send(request).then((response) {
          if (token.isCancelled)
            unawaited(response.stream.listen((_) {}).cancel());
          return response;
        }),
        token.whenCancelled.then<http.StreamedResponse>(
          (_) => throw http.RequestAbortedException(request.url),
        ),
      ]);
      if (token.isCancelled) return;
      if (response.statusCode != 200) {
        await response.stream.listen((_) {}).cancel();
        throw HttpException('GET $url failed with ${response.statusCode}');
      }
      final total = response.contentLength;
      var received = 0;
      sink = part.openWrite();
      final destination = sink;
      final complete = Completer<void>();
      download.publish(DownloadProgress(receivedBytes: 0, totalBytes: total));
      body = response.stream.listen(
        (chunk) {
          if (token.isCancelled) return;
          destination.add(chunk);
          received += chunk.length;
          download.publish(
            DownloadProgress(receivedBytes: received, totalBytes: total),
          );
        },
        onError: complete.completeError,
        onDone: complete.complete,
      );
      await Future.any([
        complete.future,
        token.whenCancelled,
        destination.done,
      ]);
      await body.cancel();
      body = null;
      await sink.flush();
      await sink.close();
      sink = null;
      if (token.isCancelled) return;
      if (total != null && received != total) {
        throw const HttpException('Incomplete recitation download');
      }
      await part.rename(file.path);
      download.publish(
        DownloadProgress(
          receivedBytes: received,
          totalBytes: total ?? received,
        ),
      );
    } on Object catch (error, stack) {
      if (!token.isCancelled) {
        download.error = error;
        download.stack = stack;
        _logger.w('Recitation save failed', error: error, stackTrace: stack);
      }
    } finally {
      try {
        await body?.cancel();
        await sink?.close();
        if (await part.exists()) await part.delete();
      } on Object catch (error, stack) {
        download.error ??= error;
        download.stack ??= stack;
        _logger.w('Recitation cleanup failed', error: error, stackTrace: stack);
      } finally {
        if (identical(_inFlight[file.path], download))
          _inFlight.remove(file.path);
        download.done.complete();
        await download.progress.close();
      }
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

  /// Deletes a cached audio file.
  Future<void> deleteCached(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object catch (error) {
      _logger.w('Failed to delete cached recitation $path: $error');
      rethrow;
    }
  }

  // ---- Catalog -----------------------------------------------------------

  Future<File> _catalogFile() async {
    final root = await _ensureRoot();
    return File(p.join(root.path, 'catalog.json'));
  }

  /// Reads the cached reciter catalog as raw JSON, or null when missing/stale.
  Future<List<dynamic>?> readCatalog({bool allowStale = false}) async {
    try {
      final file = await _catalogFile();
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      if (json['version'] != catalogVersion) return null;
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      if (savedAt == null ||
          (!allowStale && DateTime.now().difference(savedAt) > catalogTtl)) {
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
      final staging = File('${file.path}.staging');
      await staging.writeAsString(
        jsonEncode({
          'version': catalogVersion,
          'savedAt': DateTime.now().toIso8601String(),
          'reciters': reciters,
        }),
        flush: true,
      );
      await staging.rename(file.path);
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
