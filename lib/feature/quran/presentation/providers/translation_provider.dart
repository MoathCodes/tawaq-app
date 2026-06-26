import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/core/utils/lru_ayah_cache.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/data/repository/translation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/quran_content_registry.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/domain/services/translation_service.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'translation_provider.g.dart';

/// Provides the [TranslationRepository] instance.
///
/// Intentionally keepAlive: SQLite-backed infrastructure singleton.
@Riverpod(keepAlive: true)
TranslationRepository translationRepository(Ref ref) {
  final dbService = ref.read(assetDatabaseServiceProvider);
  return TranslationRepository(dbService);
}

/// Provides the [TranslationService] instance.
///
/// Intentionally keepAlive: thin service wrapper over
/// [translationRepositoryProvider].
@Riverpod(keepAlive: true)
TranslationService translationService(Ref ref) {
  final repository = ref.read(translationRepositoryProvider);
  return TranslationService(repository);
}

/// In-memory LRU for recently fetched translation database rows.
///
/// Intentionally keepAlive: bounded session cache. Auto-dispose
/// [ayahTranslationRowProvider] families consult this layer.
@Riverpod(keepAlive: true)
LruAyahCache<Translation> ayahTranslationRowLru(Ref ref) =>
    LruAyahCache<Translation>();

/// Raw translation row for a specific ayah and source, with LRU row caching.
///
/// Auto-dispose family: disposes when no widget listens to this ayah/source.
@riverpod
Future<Translation?> ayahTranslationRow(
  Ref ref,
  TranslationId source,
  int sura,
  int aya,
) async {
  final lru = ref.read(ayahTranslationRowLruProvider);
  final cached = lru.lookup(source.name, sura, aya);
  if (cached.hit) return cached.value;

  final result = await ref
      .read(translationServiceProvider)
      .getTranslation(source, sura, aya);
  lru.store(source.name, sura, aya, result);
  return result;
}

/// Translation text for a specific ayah using the persisted source selection.
@riverpod
Future<Translation?> ayahTranslation(Ref ref, int sura, int aya) {
  final source = ref.watch(
    quranScreenSettingsProvider.select(
      (settings) =>
          settings.value?.selectedTranslation ??
          QuranContentRegistry.defaultTranslation,
    ),
  );
  return ref.watch(ayahTranslationRowProvider(source, sura, aya).future);
}
