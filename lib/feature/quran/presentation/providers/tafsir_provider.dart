import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/feature/quran/data/models/tafsir.dart';
import 'package:tawaq/feature/quran/data/repository/tafsir_repository.dart';
import 'package:tawaq/feature/quran/data/sources/quran_content_registry.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_service.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'tafsir_provider.g.dart';

/// Provides the [TafsirRepository] instance.
@Riverpod(keepAlive: true)
TafsirRepository tafsirRepository(Ref ref) {
  final dbService = ref.read(assetDatabaseServiceProvider);
  return TafsirRepository(dbService);
}

/// Provides the [TafsirService] instance.
@Riverpod(keepAlive: true)
TafsirService tafsirService(Ref ref) {
  final repository = ref.read(tafsirRepositoryProvider);
  return TafsirService(repository);
}

/// Tafsir text for a specific ayah using the persisted source selection.
@riverpod
Future<Tafsir?> ayahTafsir(Ref ref, int sura, int aya) {
  final source = ref.watch(
    quranScreenSettingsProvider.select(
      (settings) =>
          settings.value?.selectedTafsir ?? QuranContentRegistry.defaultTafsir,
    ),
  );
  return ref.read(tafsirServiceProvider).getTafsir(source, sura, aya);
}
