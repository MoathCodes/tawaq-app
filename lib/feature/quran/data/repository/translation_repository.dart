import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
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
  final Map<TranslationId, Database> _databases = {};

  /// Gets a translation for a specific ayah from the given source.
  Future<Translation?> getTranslation(
    TranslationId source,
    int sura,
    int aya,
  ) async {
    final database = await _database(source);
    final result = database.select(
      'SELECT * FROM translation WHERE sura = ? AND aya = ?',
      [sura, aya],
    );
    final row = result.isEmpty ? null : _translationFromRow(result.first);
    return _decorate(row, source);
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

  Future<Database> _database(TranslationId source) async {
    final cached = _databases[source];
    if (cached != null) return cached;
    final database = await _dbService.openDatabase(source.databasePath);
    _databases[source] = database;
    return database;
  }

  Translation _translationFromRow(Row row) => Translation.fromMap({
    'id': row['id'],
    'sura': row['sura'],
    'aya': row['aya'],
    'translation': row['translation'],
    'footnotes': row['footnotes'],
  });
}
