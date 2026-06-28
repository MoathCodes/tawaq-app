import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

part 'recitation_data_providers.g.dart';

/// Shared HTTP client for recitation API + downloads.
@Riverpod(keepAlive: true)
http.Client recitationHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// mp3quran.net API client.
@Riverpod(keepAlive: true)
Mp3QuranApi mp3QuranApi(Ref ref) => Mp3QuranApi(
  client: ref.watch(recitationHttpClientProvider),
  logger: ref.watch(loggerProvider),
);

/// On-disk recitation cache.
@Riverpod(keepAlive: true)
RecitationCache recitationCache(Ref ref) => RecitationCache(
  client: ref.watch(recitationHttpClientProvider),
  logger: ref.watch(loggerProvider),
);

/// Recitation repository (API + cache).
@Riverpod(keepAlive: true)
RecitationRepository recitationRepository(Ref ref) => RecitationRepository(
  api: ref.watch(mp3QuranApiProvider),
  cache: ref.watch(recitationCacheProvider),
  logger: ref.watch(loggerProvider),
);

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
