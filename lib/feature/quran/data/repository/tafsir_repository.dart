import 'package:hasanat/core/database/asset_database_service.dart';
import 'package:hasanat/feature/quran/data/sources/tafsir_data_source.dart';
import 'package:hasanat/feature/quran/domain/models/tafsir.dart';
import 'package:hasanat/feature/quran/domain/models/tafsir_source.dart';

/// Repository for accessing Quran tafsir (commentary).
///
/// Manages multiple tafsir data sources and provides a unified API
/// for querying tafsir by source.
class TafsirRepository {
  /// Creates a tafsir repository.
  TafsirRepository(this._dbService);

  final AssetDatabaseService _dbService;
  final Map<TafsirId, ITafsirDataSource> _dataSources = {};

  /// Gets a tafsir for a specific ayah from the given source.
  Future<Tafsir?> getTafsir(TafsirId source, int suraNo, int ayaNo) async {
    final dataSource = await _getOrCreateDataSource(source);
    return dataSource.getTafsir(suraNo, ayaNo);
  }

  /// Gets all tafsir entries for a surah from the given source.
  Future<List<Tafsir>> getTafsirForSura(TafsirId source, int suraNo) async {
    final dataSource = await _getOrCreateDataSource(source);
    return dataSource.getTafsirForSura(suraNo);
  }

  Future<ITafsirDataSource> _getOrCreateDataSource(TafsirId source) async {
    // Return cached data source if available
    if (_dataSources.containsKey(source)) {
      return _dataSources[source]!;
    }

    // Open the database and create data source
    final database = await _dbService.openDatabase(source.databasePath);
    final dataSource = SqliteTafsirDataSource(database);
    _dataSources[source] = dataSource;

    return dataSource;
  }
}
