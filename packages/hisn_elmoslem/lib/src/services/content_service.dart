import '../database/hisn_database.dart';
import '../models/content.dart';
import '../parsers/hisn_row_mapper.dart';

/// Dhikr content lookup operations.
final class ContentService {
  /// Creates the service.
  ContentService(this._database);

  final HisnDatabase _database;

  /// All contents ordered by `order`.
  List<HisnContent> all() {
    final rows = _database.hisn.select(
      'SELECT * FROM contents ORDER BY `order` ASC',
    );
    return rows.map(HisnRowMapper.mapContent).toList();
  }

  /// Contents for a title, ordered by `order`.
  List<HisnContent> byTitleId(int titleId) {
    final rows = _database.hisn.select('''
SELECT * FROM contents
WHERE titleId = ?
ORDER BY `order` ASC
''', [titleId]);
    return rows.map(HisnRowMapper.mapContent).toList();
  }

  /// Single content by id.
  HisnContent? byId(int id) {
    final rows = _database.hisn.select(
      'SELECT * FROM contents WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    return HisnRowMapper.mapContent(rows.first);
  }

  /// Count of contents per title id.
  Map<int, int> countByTitleId() {
    final rows = _database.hisn.select('''
SELECT titleId, COUNT(*) AS count
FROM contents
GROUP BY titleId
''');
    return {
      for (final row in rows) row['titleId']! as int: row['count']! as int,
    };
  }
}
