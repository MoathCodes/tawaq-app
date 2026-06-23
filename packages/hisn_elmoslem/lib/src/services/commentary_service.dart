import '../database/hisn_database.dart';
import '../models/models.dart';
import '../parsers/hisn_row_mapper.dart';

/// Commentary lookup operations.
final class CommentaryService {
  /// Creates the service.
  CommentaryService(this._database);

  final HisnDatabase _database;

  /// Commentary for a content id, if present.
  HisnCommentary? byContentId(int contentId) {
    final rows = _database.commentary.select(
      'SELECT * FROM commentary WHERE contentId = ?',
      [contentId],
    );
    if (rows.isEmpty) return null;
    return HisnRowMapper.mapCommentary(rows.first);
  }

  /// Lightweight flags for list UI without loading full commentary bodies.
  HisnCommentaryFlags? flagsForContentId(int contentId) =>
      flagsForContentIds({contentId})[contentId];

  /// Batch flags lookup for many content ids in one SQL round-trip.
  Map<int, HisnCommentaryFlags> flagsForContentIds(Set<int> contentIds) {
    if (contentIds.isEmpty) return const {};

    final ids = contentIds.toList(growable: false);
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = _database.commentary.select(
      '''
      SELECT
        contentId,
        CASE WHEN sharh IS NOT NULL AND length(trim(sharh)) > 0 THEN 1 ELSE 0 END AS hasSharh,
        CASE WHEN hadith IS NOT NULL AND length(trim(hadith)) > 0 THEN 1 ELSE 0 END AS hasHadith,
        CASE WHEN benefit IS NOT NULL AND length(trim(benefit)) > 0 THEN 1 ELSE 0 END AS hasBenefit
      FROM commentary
      WHERE contentId IN ($placeholders)
      ''',
      ids,
    );

    return {
      for (final row in rows)
        row['contentId'] as int: HisnCommentaryFlags(
          hasSharh: (row['hasSharh'] as int) == 1,
          hasHadith: (row['hasHadith'] as int) == 1,
          hasBenefit: (row['hasBenefit'] as int) == 1,
        ),
    };
  }
}
