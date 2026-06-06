import 'enums.dart';
import 'models.dart';
import 'quran_presentation.dart';

/// A parsed line inside dhikr content.
sealed class HisnContentLine {
  /// Creates a content line.
  const HisnContentLine();
}

/// Plain Arabic prose (hadith, dua, etc.).
final class HisnPlainLine extends HisnContentLine {
  /// Creates a plain text line.
  const HisnPlainLine(this.text);

  /// Line text.
  final String text;
}

/// Quranic passage with a resolved [HisnQuranPresentation] render mode.
final class HisnQuranLine extends HisnContentLine {
  /// Creates a Quranic line.
  const HisnQuranLine(this.presentation);

  /// Recommended rendering strategy for this line.
  final HisnQuranPresentation presentation;

  /// Verse ranges referenced by this line.
  List<HisnVerseRange> get ranges => presentation.ranges;
}

/// A single dhikr / dua item from Hisn al-Muslim.
final class HisnContent {
  /// Creates content.
  const HisnContent({
    required this.id,
    required this.titleId,
    required this.order,
    required this.repeatCount,
    required this.lines,
    required this.rawContent,
    this.virtue = '',
    this.source = '',
    this.hokm = '',
    this.searchText = '',
    this.audio,
    this.commentary,
  });

  /// Primary key.
  final int id;

  /// Parent [HisnTitle.id].
  final int titleId;

  /// Order within the title.
  final int order;

  /// Recommended repeat count from the database.
  final int repeatCount;

  /// Parsed content lines.
  final List<HisnContentLine> lines;

  /// Raw `content` column value.
  final String rawContent;

  /// Virtue / fadl text.
  final String virtue;

  /// Takhreej / source reference.
  final String source;

  /// Raw authenticity string from the database.
  final String hokm;

  /// Normalized search text.
  final String searchText;

  /// Remote audio, if available.
  final HisnAudio? audio;

  /// Optional loaded commentary.
  final HisnCommentary? commentary;

  /// Parsed authenticity enum, if recognized.
  HisnAuthenticity? get authenticity => HisnAuthenticity.tryParse(hokm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HisnContent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Ergonomic getters for [HisnContent].
extension HisnContentX on HisnContent {
  /// Whether [virtue] is non-empty.
  bool get hasVirtue => virtue.isNotEmpty;

  /// Whether [source] is non-empty.
  bool get hasSource => source.isNotEmpty;

  /// Whether [hokm] is non-empty.
  bool get hasHokm => hokm.isNotEmpty;

  /// Whether remote audio is available.
  bool get hasAudio => audio != null;

  /// Whether any line is a [HisnQuranLine].
  bool get isQuranic => lines.any((line) => line is HisnQuranLine);

  /// Whether commentary was loaded and is non-empty.
  bool get hasCommentary => commentary?.isNotEmpty ?? false;

  /// All verse ranges across Quranic lines.
  Iterable<HisnVerseRange> get quranRanges sync* {
    for (final line in lines) {
      if (line is HisnQuranLine) {
        yield* line.ranges;
      }
    }
  }

  /// Plain prose text (non-Quranic lines joined).
  String get plainText => lines
      .whereType<HisnPlainLine>()
      .map((line) => line.text)
      .where((text) => text.isNotEmpty)
      .join('\n\n');
}

/// Ergonomic getters for [HisnTitle].
extension HisnTitleX on HisnTitle {
  /// Whether this title has bundled audio metadata.
  bool get hasAudio => audioFileName != null && audioFileName!.isNotEmpty;
}
