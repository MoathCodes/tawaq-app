import '../models/content.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../parsers/quran_text_parser.dart';

/// Maps database rows to domain models.
abstract final class HisnRowMapper {
  /// Maps a `titles` row.
  static HisnTitle mapTitle(Map<String, Object?> row) {
    return HisnTitle(
      id: row['id']! as int,
      name: row['name']! as String,
      order: row['order']! as int,
      recurrence: HisnRecurrence.fromDb(row['freq']! as String),
      searchText: row['search'] as String? ?? '',
      audioFileName: row['audio'] as String?,
    );
  }

  /// Maps a `contents` row.
  static HisnContent mapContent(Map<String, Object?> row) {
    final rawContent = row['content']! as String;
    final audioUrl = row['audio_url'] as String?;

    return HisnContent(
      id: row['id']! as int,
      titleId: row['titleId']! as int,
      order: row['order']! as int,
      repeatCount: row['count']! as int,
      lines: QuranTextParser.parseContent(rawContent),
      rawContent: rawContent,
      virtue: row['fadl'] as String? ?? '',
      source: row['source'] as String? ?? '',
      hokm: row['hokm'] as String? ?? '',
      searchText: row['search'] as String? ?? '',
      audio: _mapAudio(audioUrl),
    );
  }

  /// Maps a `commentary` row.
  static HisnCommentary mapCommentary(Map<String, Object?> row) {
    return HisnCommentary(
      id: row['id']! as int,
      contentId: row['contentId']! as int,
      sharh: row['sharh'] as String? ?? '',
      hadith: row['hadith'] as String? ?? '',
      benefit: row['benefit'] as String? ?? '',
    );
  }

  /// Maps a `fakeHadith` row.
  static HisnFakeHadith mapFakeHadith(Map<String, Object?> row) {
    return HisnFakeHadith(
      id: row['id']! as int,
      text: row['text']! as String,
      darga: row['darga']! as String,
      source: row['source']! as String,
    );
  }

  static HisnAudio? _mapAudio(String? audioUrl) {
    if (audioUrl == null || audioUrl.isEmpty) return null;
    final uri = Uri.tryParse(audioUrl);
    if (uri == null) return null;
    return HisnAudio(remoteUrl: uri);
  }
}
