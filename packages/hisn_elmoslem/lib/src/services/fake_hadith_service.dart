import '../database/hisn_database.dart';
import '../models/models.dart';
import '../parsers/hisn_row_mapper.dart';

/// Fake hadith warning lookup.
final class FakeHadithService {
  /// Creates the service.
  FakeHadithService(this._database);

  final HisnDatabase _database;

  /// All known weak/fabricated hadith warnings.
  List<HisnFakeHadith> all() {
    final rows = _database.fakeHadith.select(
      'SELECT * FROM fakeHadith ORDER BY id ASC',
    );
    return rows.map(HisnRowMapper.mapFakeHadith).toList();
  }
}
