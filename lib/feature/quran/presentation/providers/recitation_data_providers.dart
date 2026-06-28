import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

part 'recitation_data_providers.g.dart';

/// Recitation repository (API + on-disk cache).
@Riverpod(keepAlive: true)
RecitationRepository recitationRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return RecitationRepository(
    api: Mp3QuranApi(
      client: client,
      logger: ref.watch(loggerProvider),
    ),
    cache: RecitationCache(
      client: client,
      logger: ref.watch(loggerProvider),
    ),
    logger: ref.watch(loggerProvider),
  );
}

/// The reciter catalog (timing links merged), cached on disk.
@Riverpod(keepAlive: true)
Future<List<Reciter>> reciters(Ref ref) =>
    ref.watch(recitationRepositoryProvider).reciters();

/// The recitation audio files currently cached on disk.
@Riverpod(keepAlive: true)
Future<List<CachedRecitation>> cachedRecitations(Ref ref) =>
    ref.watch(recitationRepositoryProvider).listCached();

/// Total bytes used by cached recitation audio files on disk.
@Riverpod(keepAlive: true)
Future<int> totalCacheBytes(Ref ref) =>
    ref.watch(recitationRepositoryProvider).totalCacheBytes();
