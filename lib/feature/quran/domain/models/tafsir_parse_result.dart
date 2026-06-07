import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_truncation_report.dart';

/// Combined output of parsing raw tafsir markup and checking DB truncation.
class TafsirParseResult {
  /// Creates a parse result.
  const TafsirParseResult({
    required this.segments,
    required this.truncationReport,
  });

  /// Styled commentary, ayah, quote, and reference segments.
  final List<TafsirTextSegment> segments;

  /// Heuristic truncation report from the raw markup.
  final TafsirTruncationReport truncationReport;
}
