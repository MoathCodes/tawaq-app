import 'package:hasanat/core/database/asset_database_service.dart';
import 'package:hasanat/feature/quran/data/sources/translation_data_source.dart';
import 'package:hasanat/feature/quran/domain/models/translation.dart';
import 'package:hasanat/feature/quran/domain/models/translation_source.dart';

/// Repository for accessing Quran translations.
///
/// Manages multiple translation data sources and provides a unified API
/// for querying translations by source.
class TranslationRepository {
  /// Creates a translation repository.
  TranslationRepository(this._dbService);

  final AssetDatabaseService _dbService;
  final Map<TranslationId, ITranslationDataSource> _dataSources = {};

  /// Gets a translation for a specific ayah from the given source.
  Future<Translation?> getTranslation(
    TranslationId source,
    int sura,
    int aya,
  ) async {
    final dataSource = await _getOrCreateDataSource(source);
    return dataSource.getTranslation(sura, aya);
  }

  /// Gets all translations for a surah from the given source.
  Future<List<Translation>> getTranslationsForSura(
    TranslationId source,
    int sura,
  ) async {
    final dataSource = await _getOrCreateDataSource(source);
    return dataSource.getTranslationsForSura(sura);
  }

  Future<ITranslationDataSource> _getOrCreateDataSource(
    TranslationId source,
  ) async {
    // Return cached data source if available
    if (_dataSources.containsKey(source)) {
      return _dataSources[source]!;
    }

    // Open the database and create data source
    final database = await _dbService.openDatabase(source.databasePath);
    final dataSource = SqliteTranslationDataSource(database);
    _dataSources[source] = dataSource;

    return dataSource;
  }
}
