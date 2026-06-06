import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';

/// Abstract interface for translation data sources.
abstract class ITranslationDataSource {
  /// Gets a translation for a specific surah and ayah.
  Translation? getTranslation(int sura, int aya);

  /// Gets all translations for a specific surah.
  List<Translation> getTranslationsForSura(int sura);
}

/// SQLite implementation of [ITranslationDataSource].
///
/// Reads translation data from a SQLite database with the schema:
/// - Table: translation
/// - Columns: id, sura, aya, translation, footnotes
class SqliteTranslationDataSource implements ITranslationDataSource {
  /// Creates a data source from an open sqlite3 database.
  SqliteTranslationDataSource(this._database);

  final Database _database;

  @override
  Translation? getTranslation(int sura, int aya) {
    final result = _database.select(
      'SELECT * FROM translation WHERE sura = ? AND aya = ?',
      [sura, aya],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Translation.fromMap(_rowToMap(row));
  }

  @override
  List<Translation> getTranslationsForSura(int sura) {
    final result = _database.select(
      'SELECT * FROM translation WHERE sura = ? ORDER BY aya',
      [sura],
    );

    return result.map((row) => Translation.fromMap(_rowToMap(row))).toList();
  }

  Map<String, dynamic> _rowToMap(Row row) {
    return {
      'id': row['id'],
      'sura': row['sura'],
      'aya': row['aya'],
      'translation': row['translation'],
      'footnotes': row['footnotes'],
    };
  }
}
