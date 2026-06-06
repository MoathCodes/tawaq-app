import '../database/hisn_database.dart';
import '../models/content.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../parsers/hisn_row_mapper.dart';

/// Full-text search over titles and contents.
final class SearchService {
  /// Creates the service.
  SearchService(this._database);

  final HisnDatabase _database;

  /// Search titles.
  (int total, List<HisnTitle> items) searchTitles(HisnSearchQuery query) {
    if (query.value.trim().isEmpty) return (0, const []);

    final where = _buildWhere('search', query);
    final rows = _database.hisn.select('''
SELECT * FROM titles
${where.clause}
ORDER BY id ASC
LIMIT ? OFFSET ?
''', [...where.args, query.limit, query.offset]);

    final countRows = _database.hisn.select('''
SELECT COUNT(*) AS count FROM titles
${where.clause}
''', where.args);

    final total = countRows.first['count']! as int;
    return (total, rows.map(HisnRowMapper.mapTitle).toList());
  }

  /// Search contents.
  (int total, List<HisnContent> items) searchContents(HisnSearchQuery query) {
    if (query.value.trim().isEmpty) return (0, const []);

    final where = _buildWhere('search', query);
    final rows = _database.hisn.select('''
SELECT * FROM contents
${where.clause}
ORDER BY `order` ASC
LIMIT ? OFFSET ?
''', [...where.args, query.limit, query.offset]);

    final countRows = _database.hisn.select('''
SELECT COUNT(*) AS count FROM contents
${where.clause}
''', where.args);

    final total = countRows.first['count']! as int;
    return (total, rows.map(HisnRowMapper.mapContent).toList());
  }

  /// Dispatches search based on [query.target].
  (int total, List<Object> items) search(HisnSearchQuery query) {
    return switch (query.target) {
      HisnSearchTarget.title => () {
        final (total, titles) = searchTitles(query);
        return (total, titles.cast<Object>());
      }(),
      HisnSearchTarget.content => () {
        final (total, contents) = searchContents(query);
        return (total, contents.cast<Object>());
      }(),
    };
  }

  _WhereClause _buildWhere(String column, HisnSearchQuery query) {
    final words = query.value.trim().split(RegExp(r'\s+'));

    return switch (query.mode) {
      HisnSearchMode.typical => _WhereClause(
        clause: 'WHERE $column LIKE ?',
        args: ['%${query.value.trim()}%'],
      ),
      HisnSearchMode.allWords => _WhereClause(
        clause:
            'WHERE (${words.map((_) => '$column LIKE ?').join(' AND ')})',
        args: [for (final word in words) '%$word%'],
      ),
      HisnSearchMode.anyWords => _WhereClause(
        clause: 'WHERE (${words.map((_) => '$column LIKE ?').join(' OR ')})',
        args: [for (final word in words) '%$word%'],
      ),
    };
  }
}

final class _WhereClause {
  const _WhereClause({required this.clause, required this.args});

  final String clause;
  final List<Object> args;
}
