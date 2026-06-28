import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/data/sources/translation_data_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/domain/services/translation_text_normalizer.dart';

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
    final row = dataSource.getTranslation(sura, aya);
    return _decorate(row, source);
  }

  /// Gets all translations for a surah from the given source.
  Future<List<Translation>> getTranslationsForSura(
    TranslationId source,
    int sura,
  ) async {
    final dataSource = await _getOrCreateDataSource(source);
    final rows = dataSource.getTranslationsForSura(sura);
    return rows.map((row) => _decorate(row, source)!).toList();
  }

  Translation? _decorate(Translation? translation, TranslationId source) {
    if (translation == null) return null;
    return Translation(
      id: translation.id,
      sura: translation.sura,
      aya: translation.aya,
      translation: TranslationTextNormalizer.normalize(translation.translation),
      footnotes: translation.footnotes == null
          ? null
          : TranslationTextNormalizer.normalize(translation.footnotes!),
      fontFamily: source.fontFamily,
    );
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
