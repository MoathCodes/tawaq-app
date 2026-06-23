import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/feature/quran/data/models/tafsir.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';

/// Abstract interface for tafsir data sources.
abstract class ITafsirDataSource {
  /// Gets a tafsir for a specific surah and ayah.
  Tafsir? getTafsir(int suraNo, int ayaNo);

  /// Gets all tafsir entries for a specific surah.
  List<Tafsir> getTafsirForSura(int suraNo);
}

/// SQLite implementation of [ITafsirDataSource].
///
/// Reads tafsir data from a SQLite database with the schema:
/// - Table: tafseer
/// - Columns: id, jozz, page, sura_no, sura_name_en, sura_name_ar,
///            line_start, line_end, aya_no, aya_text, aya_text_emlaey,
///            aya_tafseer
class SqliteTafsirDataSource implements ITafsirDataSource {
  /// Creates a data source from an open sqlite3 database.
  SqliteTafsirDataSource(this._database);

  final Database _database;

  @override
  Tafsir? getTafsir(int suraNo, int ayaNo) {
    final result = _database.select(
      'SELECT id, sura_no, aya_no, aya_tafseer '
      'FROM tafseer WHERE sura_no = ? AND aya_no = ?',
      [suraNo, ayaNo],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Tafsir.fromMap(_rowToMap(row));
  }

  @override
  List<Tafsir> getTafsirForSura(int suraNo) {
    final result = _database.select(
      'SELECT id, sura_no, aya_no, aya_tafseer '
      'FROM tafseer WHERE sura_no = ? ORDER BY aya_no',
      [suraNo],
    );

    return result.map((row) => Tafsir.fromMap(_rowToMap(row))).toList();
  }

  Map<String, dynamic> _rowToMap(Row row) {
    return {
      'id': row['id'],
      'sura_no': row['sura_no'],
      'aya_no': row['aya_no'],
      'aya_tafseer': row['aya_tafseer'],
    };
  }
}

/// SQLite implementation for compact tafsir databases.
///
/// Reads tafsir data from tables such as `AS`, `Ba`, or `IK` with columns:
/// `SURA_num`, `AYA_num`, `Tafsir`.
class SqliteCompactTafsirDataSource implements ITafsirDataSource {
  /// Creates a compact-schema data source.
  SqliteCompactTafsirDataSource(this._database, this._tableName);

  final Database _database;
  final String _tableName;

  @override
  Tafsir? getTafsir(int suraNo, int ayaNo) {
    final result = _database.select(
      'SELECT SURA_num, AYA_num, Tafsir '
      'FROM "$_tableName" WHERE SURA_num = ? AND AYA_num = ?',
      [suraNo, ayaNo],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Tafsir(
      id: 0,
      suraNo: row['SURA_num'] as int,
      ayaNo: row['AYA_num'] as int,
      ayaTafseer: row['Tafsir'] as String,
    );
  }

  @override
  List<Tafsir> getTafsirForSura(int suraNo) {
    final result = _database.select(
      'SELECT SURA_num, AYA_num, Tafsir '
      'FROM "$_tableName" WHERE SURA_num = ? ORDER BY AYA_num',
      [suraNo],
    );

    return result
        .map(
          (row) => Tafsir(
            id: 0,
            suraNo: row['SURA_num'] as int,
            ayaNo: row['AYA_num'] as int,
            ayaTafseer: row['Tafsir'] as String,
          ),
        )
        .toList();
  }
}

/// Creates the appropriate data source for [source].
ITafsirDataSource createTafsirDataSource(Database database, TafsirId source) {
  return switch (source.schema) {
    TafsirSchema.mouaser => SqliteTafsirDataSource(database),
    TafsirSchema.compact => SqliteCompactTafsirDataSource(
      database,
      source.tableName!,
    ),
  };
}
