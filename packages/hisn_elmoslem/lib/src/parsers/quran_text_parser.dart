import '../models/content.dart';
import '../models/models.dart';
import '../models/quran_presentation.dart';
import 'quran_presentation_classifier.dart';

/// Parses `QuranText[(s:a:e)]` markers from raw content strings.
abstract final class QuranTextParser {
  static final _markerExp = RegExp(
    r'QuranText\[(\([^)]+\)(?:,\([^)]+\))*)\]',
  );

  static final _rangeExp = RegExp(r'\((\d+):(\d+):(\d+)\)');

  /// Parses verse ranges from a single `QuranText[...]` line.
  static List<HisnVerseRange> parseLine(String line) {
    final match = _markerExp.firstMatch(line);
    if (match == null) return const [];

    final ranges = match.group(1)!.split(',');
    final parsed = <HisnVerseRange>[];

    for (final range in ranges) {
      final rangeMatch = _rangeExp.firstMatch(range.trim());
      if (rangeMatch == null) continue;

      parsed.add(
        HisnVerseRange(
          surah: int.parse(rangeMatch.group(1)!),
          startAyah: int.parse(rangeMatch.group(2)!),
          endAyah: int.parse(rangeMatch.group(3)!),
        ),
      );
    }

    return parsed;
  }

  /// Classifies a parsed line into a [HisnQuranPresentation].
  static HisnQuranPresentation classifyLine(String line) {
    final ranges = parseLine(line);
    if (ranges.isEmpty) {
      throw FormatException('No QuranText ranges found in: $line');
    }
    return QuranPresentationClassifier.classify(ranges);
  }

  /// Splits raw DB content into structured lines.
  static List<HisnContentLine> parseContent(String raw) {
    if (raw.isEmpty) return const [];

    final lines = raw.split('\n');
    final result = <HisnContentLine>[];

    for (final line in lines) {
      if (line.contains('QuranText')) {
        final ranges = parseLine(line);
        if (ranges.isNotEmpty) {
          result.add(
            HisnQuranLine(QuranPresentationClassifier.classify(ranges)),
          );
        }
      } else if (line.trim().isNotEmpty) {
        result.add(HisnPlainLine(line));
      }
    }

    return result;
  }
}
