import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/core/utils/lru_ayah_cache.dart';
import 'package:tawaq/core/utils/lru_map.dart';
import 'package:tawaq/feature/quran/data/models/tafsir.dart';
import 'package:tawaq/feature/quran/data/repository/tafsir_repository.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
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

/// Bounded in-memory cache for parsed tafsir per ayah/source.
@Riverpod(keepAlive: true)
_TafsirAyahCache tafsirAyahCache(Ref ref) => _TafsirAyahCache();

class _TafsirAyahCache {
  static const _maxSize = 256;

  final _rows = LruAyahCache<Tafsir>();
  final _parsed = LruMap<String, TafsirParseResult>(_maxSize);

  static String _parseKey(TafsirId source, int sura, int aya) =>
      '${source.name}-$sura-$aya';

  TafsirParseResult? lookup(TafsirId source, int sura, int aya) =>
      _parsed[_parseKey(source, sura, aya)];

  void store(TafsirId source, int sura, int aya, TafsirParseResult result) {
    _parsed[_parseKey(source, sura, aya)] = result;
  }

  /// Parses [text] with LRU caching for tests and direct text entry.
  TafsirParseResult parseText(String text, {TafsirId? tafsirId}) {
    final key = '${tafsirId?.name ?? ''}|$text';
    final cached = _parsed[key];
    if (cached != null) return cached;

    final result = TafsirTextParser.parse(text, tafsirId: tafsirId);
    _parsed[key] = result;
    return result;
  }

  LruAyahCache<Tafsir> get rows => _rows;
}

/// Parsed tafsir for a specific ayah and source (row fetch + parse, LRU cached).
///
/// Auto-dispose family: disposes when no widget listens to this ayah/source.
@riverpod
Future<TafsirParseResult?> tafsirForAyah(
  Ref ref,
  TafsirId source,
  int sura,
  int aya,
) async {
  final cache = ref.read(tafsirAyahCacheProvider);
  final cached = cache.lookup(source, sura, aya);
  if (cached != null) return cached;

  final rowLru = cache.rows;
  final rowHit = rowLru.lookup(source.name, sura, aya);
  final row = rowHit.hit
      ? rowHit.value
      : await ref.read(tafsirRepositoryProvider).getTafsir(source, sura, aya);
  if (!rowHit.hit) {
    rowLru.store(source.name, sura, aya, row);
  }
  if (row == null) return null;

  final result = TafsirTextParser.parse(row.ayaTafseer, tafsirId: source);
  cache.store(source, sura, aya, result);
  return result;
}
