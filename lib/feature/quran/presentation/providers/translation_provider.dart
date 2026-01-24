import 'package:hasanat/core/database/asset_database_service.dart';
import 'package:hasanat/feature/quran/data/repository/translation_repository.dart';
import 'package:hasanat/feature/quran/data/services/translation_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
