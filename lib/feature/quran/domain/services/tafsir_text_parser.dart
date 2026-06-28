import 'package:tawaq/core/text/arabic_text_normalizer.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_poetry_splitter.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_segment_repair.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_span_classifier.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_integrity.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_normalizer.dart';

/// Parses raw tafsir HTML-like markup into styled segments.
abstract final class TafsirTextParser {
  static final _spanOpenPattern = RegExp(
    '<span\\s+class=["\']([^"\']+)["\']>',
    caseSensitive: false,
  );
  static final _spanOpenToken = RegExp(r'<span\s', caseSensitive: false);
  static final _spanCloseToken = RegExp('</span>', caseSensitive: false);

  static final _brPattern = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final _divClosePattern = RegExp('</div>', caseSensitive: false);
  static final _divOpenPattern = RegExp('<div[^>]*>', caseSensitive: false);
  static final _htmlTagPattern = RegExp('<[^>]+>');

  /// Parses [rawText] into segments and a truncation report in one pass.
  static TafsirParseResult parse(
    String rawText, {
    TafsirId? tafsirId,
  }) {
    final strippedHtml = rawText.replaceAll(_htmlTagPattern, '');
    final truncationReport = TafsirTextIntegrity.analyze(
      rawText,
      strippedHtml: strippedHtml,
    );

    return TafsirParseResult(
      segments: _parseSegments(rawText, tafsirId: tafsirId),
      truncationReport: truncationReport,
    );
  }

  static List<TafsirTextSegment> _parseSegments(
    String rawText, {
    TafsirId? tafsirId,
  }) {
    final normalized = _normalize(rawText);
    if (normalized.isEmpty) return const [];

    final segments = <TafsirTextSegment>[];
    _parseContent(normalized, segments, tafsirId: tafsirId);

    if (segments.isEmpty) {
      _addCommentary(segments, normalized);
    }

    return TafsirPoetrySplitter.expand(
      TafsirSegmentRepair.repair(segments)
          .map(
            (segment) => TafsirTextSegment(
              text: _normalizeSegmentText(segment),
              kind: segment.kind,
              poetryHemistichs: segment.poetryHemistichs,
            ),
          )
          .toList(),
    );
  }

  static String _normalizeSegmentText(TafsirTextSegment segment) {
    final normalized = ArabicTextNormalizer.normalize(segment.text);
    if (segment.kind == TafsirSegmentKind.ayah) {
      return TafsirTextNormalizer.formatAyahDisplay(normalized);
    }
    return normalized;
  }

  /// Walks [text] in document order, emitting commentary or span-classified
  /// segments. Nested spans are parsed recursively so outer spans are not
  /// truncated at the first inner `</span>`.
  static void _parseContent(
    String text,
    List<TafsirTextSegment> segments, {
    String? enclosingClass,
    TafsirId? tafsirId,
  }) {
    var cursor = 0;

    while (cursor < text.length) {
      final slice = text.substring(cursor);
      final openMatch = _spanOpenPattern.firstMatch(slice);
      if (openMatch == null) {
        _addSegment(
          segments,
          text.substring(cursor),
          enclosingClass,
          tafsirId: tafsirId,
        );
        return;
      }

      final openStart = cursor + openMatch.start;
      final openEnd = cursor + openMatch.end;
      final cssClass = openMatch.group(1)?.trim() ?? '';

      if (openStart > cursor) {
        _addSegment(
          segments,
          text.substring(cursor, openStart),
          enclosingClass,
          tafsirId: tafsirId,
        );
      }

      final closeEnd = _findMatchingCloseSpan(text, openEnd);
      if (closeEnd == null) {
        _addSegment(
          segments,
          text.substring(openStart),
          enclosingClass,
          tafsirId: tafsirId,
        );
        return;
      }

      final innerStart = openEnd;
      final innerEnd = closeEnd - '</span>'.length;
      _parseContent(
        text.substring(innerStart, innerEnd),
        segments,
        enclosingClass: cssClass,
        tafsirId: tafsirId,
      );

      cursor = closeEnd;
    }
  }

  static int? _findMatchingCloseSpan(String text, int contentStart) {
    var depth = 1;
    var index = contentStart;

    while (index < text.length && depth > 0) {
      final slice = text.substring(index);
      final openMatch = _spanOpenToken.firstMatch(slice);
      final closeMatch = _spanCloseToken.firstMatch(slice);

      if (closeMatch == null) return null;

      final openOffset = openMatch?.start;
      final closeOffset = closeMatch.start;

      if (openOffset != null && openOffset < closeOffset) {
        depth++;
        index += openMatch!.end;
      } else {
        depth--;
        if (depth == 0) return index + closeMatch.end;
        index += closeMatch.end;
      }
    }

    return null;
  }

  static void _addSegment(
    List<TafsirTextSegment> segments,
    String raw,
    String? enclosingClass, {
    TafsirId? tafsirId,
  }) {
    if (enclosingClass == null) {
      _addCommentary(segments, raw);
      return;
    }

    final text = _stripResidualTags(raw);
    if (text.isEmpty) return;

    segments.addAll(
      TafsirSpanClassifier.classifySpan(
        cssClass: enclosingClass,
        content: text,
        tafsirId: tafsirId,
      ),
    );
  }

  static String _normalize(String raw) {
    return raw
        .replaceAll(_brPattern, '\n')
        .replaceAll(_divClosePattern, '')
        .replaceAll(_divOpenPattern, '');
  }

  static void _addCommentary(List<TafsirTextSegment> segments, String raw) {
    var text = raw.replaceAll(_htmlTagPattern, '').trimRight();
    if (text.isEmpty) return;

    if (segments.isNotEmpty &&
        segments.last.kind == TafsirSegmentKind.ayah &&
        text.startsWith('\n') &&
        !text.startsWith('\n ')) {
      text = '\n ${text.substring(1)}';
    }

    segments.add(
      TafsirTextSegment(
        text: text,
        kind: TafsirSegmentKind.commentary,
      ),
    );
  }

  static String _stripResidualTags(String input) {
    return input.replaceAll(_htmlTagPattern, '');
  }
}
