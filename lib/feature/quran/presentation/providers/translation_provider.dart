import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/core/utils/lru_ayah_cache.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/data/repository/translation_repository.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';

part 'translation_provider.g.dart';

/// Bounded session cache for recently fetched translation rows.
final _ayahTranslationLru = LruAyahCache<Translation>();

/// Provides the [TranslationRepository] instance.
///
/// Intentionally keepAlive: SQLite-backed infrastructure singleton.
@Riverpod(keepAlive: true)
TranslationRepository translationRepository(Ref ref) {
  final dbService = ref.read(assetDatabaseServiceProvider);
  return TranslationRepository(dbService);
}

/// Translation row for a specific ayah and source, with LRU row caching.
///
/// Auto-dispose family: disposes when no widget listens to this ayah/source.
/// Call sites should watch the selected [TranslationId] from settings and
/// pass it here — there is no settings-wrapping alias.
@riverpod
Future<Translation?> ayahTranslationRow(
  Ref ref,
  TranslationId source,
  int sura,
  int aya,
) async {
  final cached = _ayahTranslationLru.lookup(source.name, sura, aya);
  if (cached.hit) return cached.value;

  final result = await ref
      .read(translationRepositoryProvider)
      .getTranslation(source, sura, aya);
  _ayahTranslationLru.store(source.name, sura, aya, result);
  return result;
}
