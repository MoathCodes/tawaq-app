import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/core/utils/lru_ayah_cache.dart';
import 'package:tawaq/core/utils/lru_map.dart';
import 'package:tawaq/feature/quran/data/models/tafsir.dart';
import 'package:tawaq/feature/quran/data/repository/tafsir_repository.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_parse_result.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_service.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

part 'tafsir_provider.g.dart';

/// Provides the [TafsirRepository] instance.
///
/// Intentionally keepAlive: SQLite-backed infrastructure singleton shared by
/// all tafsir fetches for the app lifetime.
@Riverpod(keepAlive: true)
TafsirRepository tafsirRepository(Ref ref) {
  final dbService = ref.read(assetDatabaseServiceProvider);
  return TafsirRepository(dbService);
}

/// Provides the [TafsirService] instance.
///
/// Intentionally keepAlive: thin service wrapper over
/// [tafsirRepositoryProvider].
@Riverpod(keepAlive: true)
TafsirService tafsirService(Ref ref) {
  final repository = ref.read(tafsirRepositoryProvider);
  return TafsirService(repository);
}

/// In-memory LRU for recently fetched tafsir database rows.
///
/// Intentionally keepAlive: bounded session cache (see [LruAyahCache]).
/// Auto-dispose [ayahTafsirRowProvider] families consult this layer so per-ayah
/// provider state can drop without unbounded family growth.
@Riverpod(keepAlive: true)
LruAyahCache<Tafsir> ayahTafsirRowLru(Ref ref) => LruAyahCache<Tafsir>();

/// Raw tafsir row for a specific ayah and source, with LRU row caching.
///
/// Auto-dispose family: disposes when no widget listens to this ayah/source.
@riverpod
Future<Tafsir?> ayahTafsirRow(
  Ref ref,
  TafsirId source,
  int sura,
  int aya,
) async {
  final lru = ref.read(ayahTafsirRowLruProvider);
  final cached = lru.lookup(source.name, sura, aya);
  if (cached.hit) return cached.value;

  final result = await ref
      .read(tafsirServiceProvider)
      .getTafsir(source, sura, aya);
  lru.store(source.name, sura, aya, result);
  return result;
}

/// In-memory LRU for parsed tafsir commentary.
///
/// Intentionally keepAlive: bounded parse-result cache. Auto-dispose
/// [parsedTafsirProvider] families read and write through this layer.
@Riverpod(keepAlive: true)
ParsedTafsirLru parsedTafsirLru(Ref ref) => ParsedTafsirLru();

/// LRU cache for [TafsirParseResult] keyed by source/ayah or raw text.
class ParsedTafsirLru {
  /// Maximum number of cached parse results.
  static const maxSize = 256;

  final _byAyah = LruMap<String, TafsirParseResult>(maxSize);
  final _byText = LruMap<String, TafsirParseResult>(maxSize);

  static String _ayahKey(TafsirId source, int sura, int aya) =>
      '${source.name}-$sura-$aya';

  static String _textKey(String text, TafsirId? tafsirId) =>
      '${tafsirId?.name ?? ''}|$text';

  /// Returns a cached parse result for [source]/[sura]/[aya], if present.
  TafsirParseResult? lookupAyah(TafsirId source, int sura, int aya) =>
      _byAyah[_ayahKey(source, sura, aya)];

  /// Stores a parse result for [source]/[sura]/[aya].
  void storeAyah(
    TafsirId source,
    int sura,
    int aya,
    TafsirParseResult result,
  ) {
    _byAyah[_ayahKey(source, sura, aya)] = result;
  }

  /// Parses [text] with LRU caching for tests and direct text entry.
  TafsirParseResult parseText(String text, {TafsirId? tafsirId}) {
    final key = _textKey(text, tafsirId);
    final cached = _byText[key];
    if (cached != null) return cached;

    final result = TafsirTextParser.parse(text, tafsirId: tafsirId);
    _byText[key] = result;
    return result;
  }
}

/// Parsed tafsir segments for a specific ayah and source.
///
/// Auto-dispose family. Watches [ayahTafsirRowProvider] synchronously before
/// awaiting its future (Riverpod 3 async-gap safe).
@riverpod
Future<TafsirParseResult?> parsedTafsir(
  Ref ref,
  TafsirId source,
  int sura,
  int aya,
) async {
  final lru = ref.read(parsedTafsirLruProvider);
  final cached = lru.lookupAyah(source, sura, aya);
  if (cached != null) return cached;

  final row = await ref.watch(ayahTafsirRowProvider(source, sura, aya).future);
  if (row == null) return null;

  final result = TafsirTextParser.parse(row.ayaTafseer, tafsirId: source);
  lru.storeAyah(source, sura, aya, result);
  return result;
}
