import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/data/repository/translation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/quran_content_registry.dart';
import 'package:tawaq/feature/quran/domain/services/translation_service.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'translation_provider.g.dart';

/// Provides the [TranslationRepository] instance.
@Riverpod(keepAlive: true)
TranslationRepository translationRepository(Ref ref) {
  final dbService = ref.read(assetDatabaseServiceProvider);
  return TranslationRepository(dbService);
}

/// Provides the [TranslationService] instance.
@Riverpod(keepAlive: true)
TranslationService translationService(Ref ref) {
  final repository = ref.read(translationRepositoryProvider);
  return TranslationService(repository);
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
  return ref.read(translationServiceProvider).getTranslation(source, sura, aya);
}
