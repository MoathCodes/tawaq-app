import '../database/hisn_database.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../parsers/hisn_row_mapper.dart';

/// Title lookup operations.
final class TitleService {
  /// Creates the service.
  TitleService(this._database);

  final HisnDatabase _database;

  /// All titles ordered by `order`.
  List<HisnTitle> all({HisnRecurrence? recurrence}) {
    final rows = _database.hisn.select('''
SELECT * FROM titles
${recurrence == null ? '' : 'WHERE freq = ?'}
ORDER BY `order` ASC
''', recurrence == null ? [] : [recurrence.dbCode]);

    return rows.map(HisnRowMapper.mapTitle).toList();
  }

  /// Title by primary key.
  HisnTitle? byId(int id) {
    final rows = _database.hisn.select(
      'SELECT * FROM titles WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    return HisnRowMapper.mapTitle(rows.first);
  }

  /// Titles whose names contain any of [nameFragments] (normalized match).
  List<HisnTitle> byNameFragments(Iterable<String> nameFragments) {
    final titles = all();
    return [
      for (final title in titles)
        if (nameFragments.any((fragment) => title.name.contains(fragment)))
          title,
    ];
  }
}
