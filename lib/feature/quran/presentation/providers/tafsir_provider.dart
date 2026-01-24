import 'package:hasanat/core/database/asset_database_service.dart';
import 'package:hasanat/feature/quran/data/repository/tafsir_repository.dart';
import 'package:hasanat/feature/quran/data/services/tafsir_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
