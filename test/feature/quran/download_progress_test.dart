import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:logger/logger.dart';
import 'package:tawaq/core/utils/cancellation_token.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

/// Builds a fake streaming http.Client whose handler returns a fixed
/// [http.StreamedResponse] built from [responseBuilder].
http.Client _client(
  http.StreamedResponse Function(http.BaseRequest) responseBuilder,
) {
  return http_testing.MockClient.streaming(
    (request, bodyStream) async => responseBuilder(request),
  );
}

/// Builds a [http.StreamedResponse] that yields [chunks] then completes.
http.StreamedResponse _response({
  required List<List<int>> chunks,
  int? contentLength,
  int statusCode = 200,
}) {
  final total = contentLength ?? chunks.fold<int>(0, (s, c) => s + c.length);
  final stream = Stream<List<int>>.fromIterable(chunks);
  return http.StreamedResponse(stream, statusCode, contentLength: total);
}

RecitationCache _cache(Directory root, http.Client client) {
  return RecitationCache(
    client: client,
    logger: Logger(),
    rootOverride: root,
  );
}

RecitationRepository _repo(Directory root, http.Client client) {
  return RecitationRepository(
    api: Mp3QuranApi(client: client, logger: Logger()),
    cache: _cache(root, client),
    logger: Logger(),
  );
}

/// A fixed reciter fixture whose cache path is stable across calls.
Reciter _reciter() => const Reciter(
      id: 1,
      name: 'Test',
      moshaf: [
        Moshaf(
          id: 1,
          name: 'Hafs',
          server: 'https://example.com/akdr/',
          surahList: [1, 2],
          surahTotal: 2,
        ),
      ],
    );

/// The network fallback URL for surah 1 of [_reciter].
const kSurah1Url = 'https://example.com/akdr/001.mp3';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recitation_cache_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('downloadAudio progress + cancellation', () {
    test('emits 0% then 50% then 100% and atomically renames .part', () async {
      // Two equal chunks of 5 bytes each -> 0, 5/10, 10/10, then a final
      // post-rename progress event == 10/10.
      const total = 10;
      final chunks = [
        Uint8List.fromList([1, 2, 3, 4, 5]),
        Uint8List.fromList([6, 7, 8, 9, 10]),
      ];
      final client = _client(
        (_) => _response(chunks: chunks, contentLength: total),
      );
      final cache = _cache(tempDir, client);

      final progress = await cache
          .downloadAudio(
            reciterId: 1,
            moshafId: 1,
            surah: 1,
            reciterName: 'Test',
            riwayahName: 'Hafs',
            surahName: 'Al-Fatiha',
            url: 'https://example.com/001.mp3',
            cancellationToken: CancellationToken(),
          )
          .toList();

      // initial(0) + chunk1(5) + chunk2(10) + final-after-rename(10)
      expect(progress.length, 4);
      expect(progress[0].receivedBytes, 0);
      expect(progress[0].totalBytes, total);
      expect(progress[1].fraction, closeTo(0.5, 0.001));
      expect(progress[2].fraction, closeTo(1.0, 0.001));
      expect(progress[3].receivedBytes, total);
      expect(progress[3].fraction, closeTo(1.0, 0.001));

      // Atomic rename: final .mp3 exists, .part does not.
      final audioDir = Directory('${tempDir.path}/audio');
      final files = audioDir.listSync(recursive: true);
      final mp3s = files
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp3'));
      expect(mp3s, hasLength(1));
      expect(
        files.where((f) => f.path.endsWith('.part')),
        isEmpty,
        reason: '.part must be renamed away on success',
      );
    });

    test('deletes .part and does not rename on cancellation', () async {
      // A stream that yields one chunk then stays open (controller not closed)
      // so the download hangs until cancellation closes the controller.
      final controller = StreamController<List<int>>()
        ..add(Uint8List.fromList([1, 2, 3, 4, 5]));
      final client = _client(
        (_) => http.StreamedResponse(
          controller.stream,
          200,
          contentLength: 100,
        ),
      );
      final cache = _cache(tempDir, client);
      final token = CancellationToken();

      final received = <DownloadProgress>[];
      final done = Completer<void>();
      final sub = cache
          .downloadAudio(
            reciterId: 1,
            moshafId: 1,
            surah: 1,
            reciterName: 'Test',
            riwayahName: 'Hafs',
            surahName: 'Al-Fatiha',
            url: 'https://example.com/001.mp3',
            cancellationToken: token,
          )
          .listen(received.add, onDone: done.complete);

      // Give the consumer a tick to receive the first chunk + initial event.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      token.cancel();
      // Closing the controller unblocks the `await for` so the loop observes
      // cancellation and returns without renaming.
      await controller.close();
      await done.future.timeout(const Duration(seconds: 2));
      await sub.cancel();

      // initial(0) then the first chunk(5). No final post-rename event.
      expect(received.first.receivedBytes, 0);
      expect(received.last.receivedBytes, 5);

      // .part must be deleted; no final .mp3 produced.
      final audioDir = Directory('${tempDir.path}/audio');
      if (audioDir.existsSync()) {
        final partFiles = audioDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.part'));
        expect(partFiles, isEmpty, reason: '.part must be deleted on cancel');
        final mp3s = audioDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.mp3'));
        expect(mp3s, isEmpty, reason: 'no final .mp3 after cancellation');
      }
    });

    test('non-200 emits an error and deletes .part', () async {
      final client = _client(
        (_) => http.StreamedResponse(
          const Stream<List<int>>.empty(),
          404,
        ),
      );
      final cache = _cache(tempDir, client);

      await expectLater(
        cache.downloadAudio(
          reciterId: 1,
          moshafId: 1,
          surah: 1,
          reciterName: 'Test',
          riwayahName: 'Hafs',
          surahName: 'Al-Fatiha',
          url: 'https://example.com/001.mp3',
          cancellationToken: CancellationToken(),
        ),
        emitsError(isA<HttpException>()),
      );

      // Assert no .part lingers after the failure.
      final audioDir = Directory('${tempDir.path}/audio');
      if (audioDir.existsSync()) {
        final partFiles = audioDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.part'));
        expect(partFiles, isEmpty, reason: '.part must be deleted on error');
      }
    });
  });

  group('resolveSurahUri uri + progress', () {
    test('cached surah returns file:// uri and null progress', () async {
      // Populate the cache with a successful download first.
      final okClient = _client(
        (_) => _response(chunks: [Uint8List.fromList([1, 2, 3, 4, 5])]),
      );
      final repo = _repo(tempDir, okClient);
      final reciter = _reciter();
      final moshaf = reciter.moshaf.first;

      // First call downloads and caches.
      await repo.resolveSurahUri(
        reciter: reciter,
        moshaf: moshaf,
        surah: 1,
        surahName: 'Al-Fatiha',
      );

      // Second call hits the cache.
      final result = await repo.resolveSurahUri(
        reciter: reciter,
        moshaf: moshaf,
        surah: 1,
        surahName: 'Al-Fatiha',
      );
      expect(result.progress, isNull);
      expect(result.uri, startsWith('file://'));
      expect(result.uri, endsWith('.mp3'));
    });

    test('successful download returns file:// uri and progress events', () async {
      final client = _client(
        (_) => _response(
          chunks: [
            Uint8List.fromList([1, 2, 3, 4, 5]),
            Uint8List.fromList([6, 7, 8, 9, 10]),
          ],
          contentLength: 10,
        ),
      );
      final repo = _repo(tempDir, client);
      final reciter = _reciter();
      final moshaf = reciter.moshaf.first;

      final result = await repo.resolveSurahUri(
        reciter: reciter,
        moshaf: moshaf,
        surah: 1,
        surahName: 'Al-Fatiha',
      );

      expect(result.progress, isNotNull);
      final events = await result.progress!.toList();
      // initial(0) + chunk1(5) + chunk2(10) + final-after-rename(10)
      expect(events.length, 4);
      expect(events.first.receivedBytes, 0);
      expect(events.last.fraction, closeTo(1.0, 0.001));
      expect(result.uri, startsWith('file://'));
      expect(result.uri, endsWith('.mp3'));
    });

    test('non-200 download returns the network url fallback', () async {
      final client = _client(
        (_) => http.StreamedResponse(const Stream<List<int>>.empty(), 404),
      );
      final repo = _repo(tempDir, client);
      final reciter = _reciter();
      final moshaf = reciter.moshaf.first;

      final result = await repo.resolveSurahUri(
        reciter: reciter,
        moshaf: moshaf,
        surah: 1,
        surahName: 'Al-Fatiha',
      );

      expect(result.uri, kSurah1Url);
      expect(result.progress, isNotNull);
      expect(await result.progress!.toList(), isEmpty);
    });

    test(
      'mid-download failure with large .part hands mpv the .part path',
      () async {
        // >1024 bytes then a stream error: the .part is large enough to play.
        final controller = StreamController<List<int>>()
          ..add(Uint8List.fromList(List.filled(2048, 1)))
          ..addError(Exception('network drop'));
        final client = _client(
          (_) => http.StreamedResponse(
            controller.stream,
            200,
            contentLength: 4096,
          ),
        );
        final repo = _repo(tempDir, client);
        final reciter = _reciter();
        final moshaf = reciter.moshaf.first;

        final result = await repo.resolveSurahUri(
          reciter: reciter,
          moshaf: moshaf,
          surah: 1,
          surahName: 'Al-Fatiha',
        );

        expect(result.uri, startsWith('file://'));
        expect(result.uri, endsWith('.mp3.part'));
        expect(result.progress, isNotNull);
        final events = await result.progress!.toList();
        // initial(0) then chunk(2048). No final-after-rename event.
        expect(events.first.receivedBytes, 0);
        expect(events.last.receivedBytes, 2048);
      },
    );

    test(
      'mid-download failure with small .part falls back to network and '
      'cleans up',
      () async {
        // 10 bytes (<1024) then a stream error: .part too small to play.
        final controller = StreamController<List<int>>()
          ..add(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
          ..addError(Exception('network drop'));
        final client = _client(
          (_) => http.StreamedResponse(
            controller.stream,
            200,
            contentLength: 4096,
          ),
        );
        final repo = _repo(tempDir, client);
        final reciter = _reciter();
        final moshaf = reciter.moshaf.first;

        final result = await repo.resolveSurahUri(
          reciter: reciter,
          moshaf: moshaf,
          surah: 1,
          surahName: 'Al-Fatiha',
        );

        expect(result.uri, kSurah1Url);
        // The undersized .part must be deleted.
        final audioDir = Directory('${tempDir.path}/audio');
        if (audioDir.existsSync()) {
          final parts = audioDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.part'));
          expect(parts, isEmpty, reason: 'undersized .part must be deleted');
        }
      },
    );

    test(
      'onProgress fires live during the download and matches replayed events',
      () async {
        final client = _client(
          (_) => _response(
            chunks: [
              Uint8List.fromList([1, 2, 3, 4, 5]),
              Uint8List.fromList([6, 7, 8, 9, 10]),
            ],
            contentLength: 10,
          ),
        );
        final repo = _repo(tempDir, client);
        final reciter = _reciter();
        final moshaf = reciter.moshaf.first;

        final live = <DownloadProgress>[];
        final result = await repo.resolveSurahUri(
          reciter: reciter,
          moshaf: moshaf,
          surah: 1,
          surahName: 'Al-Fatiha',
          onProgress: live.add,
        );

        // The live callback received the same events the replayed stream
        // surfaces: 0/10, 5/10, 10/10, then a final 10/10 post-rename.
        final replayed = await result.progress!.toList();
        expect(live.length, replayed.length);
        expect(
          live.map((p) => p.receivedBytes),
          replayed.map((p) => p.receivedBytes),
        );
        expect(live.first.receivedBytes, 0);
        expect(live.last.receivedBytes, 10);
        expect(result.uri, startsWith('file://'));
      },
    );

    test(
      'cancel mid-download deletes .part and falls back to network url',
      () async {
        // A stream that yields one chunk then hangs (controller not closed)
        // so resolveSurahUri's await-for blocks until cancellation.
        final controller = StreamController<List<int>>()
          ..add(Uint8List.fromList([1, 2, 3, 4, 5]));
        final client = _client(
          (_) => http.StreamedResponse(
            controller.stream,
            200,
            contentLength: 100,
          ),
        );
        final repo = _repo(tempDir, client);
        final reciter = _reciter();
        final moshaf = reciter.moshaf.first;
        final token = CancellationToken();

        // resolveSurahUri awaits the full download, so kick it off and
        // cancel mid-stream once the first chunk has been consumed.
        final future = repo.resolveSurahUri(
          reciter: reciter,
          moshaf: moshaf,
          surah: 1,
          surahName: 'Al-Fatiha',
          cancellationToken: token,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        token.cancel();
        // Closing the controller unblocks the await-for so the loop observes
        // cancellation and resolves to the network fallback.
        await controller.close();

        final result = await future.timeout(const Duration(seconds: 2));

        // Cancelled download produced no .mp3, so resolveSurahUri falls back
        // to the network url instead of erroring.
        expect(result.uri, kSurah1Url);
        expect(result.progress, isNotNull);
        // initial(0) then the first chunk(5); no final post-rename event.
        final events = await result.progress!.toList();
        expect(events.first.receivedBytes, 0);
        expect(events.last.receivedBytes, 5);

        // The partial .part must be deleted on cancellation.
        final audioDir = Directory('${tempDir.path}/audio');
        if (audioDir.existsSync()) {
          final parts = audioDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.part'));
          expect(parts, isEmpty, reason: '.part must be deleted on cancel');
        }
      },
    );
  });
}
