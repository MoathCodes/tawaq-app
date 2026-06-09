import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/text/arabic_text_normalizer.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_commentary_block.dart';

/// Splits raw Hisn sharh into readable blocks.
abstract final class FortressCommentaryParser {
  static final _listItemHeaderPattern = RegExp(r'^(\d+)\s*[-–—]\s*');
  static final _listItemSplitPattern = RegExp(r'\n(?=\d+\s*[-–—]\s*)');
  static final _citationPattern = RegExp(r'/55\s*(.+?)\s*/55', dotAll: true);
  static final _collapseWhitespacePattern = RegExp(r'\s+');
  static final _trailingCommaPattern = RegExp(r'\s*،\s*$');
  static final _spaceTabPattern = RegExp(r'[ \t]+');
  static final _newlinePattern = RegExp(r'\n+');

  /// Parses [text] into intro and numbered blocks.
  static List<FortressCommentaryBlock> parse(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];

    final rawSegments = normalized.split(_listItemSplitPattern);
    final blocks = <FortressCommentaryBlock>[];

    for (final segment in rawSegments) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;

      final header = _listItemHeaderPattern.firstMatch(trimmed);
      if (header == null) {
        final intro = _extractCitations(trimmed);
        if (intro.body.isNotEmpty || intro.citations.isNotEmpty) {
          blocks.add(
            FortressCommentaryBlock(
              body: intro.body,
              citations: intro.citations,
            ),
          );
        }
        continue;
      }

      final listNumber = int.tryParse(header.group(1)!);
      final remainder = trimmed.substring(header.end).trim();
      final parsed = _extractCitations(remainder);
      if (parsed.body.isEmpty && parsed.citations.isEmpty) continue;

      blocks.add(
        FortressCommentaryBlock(
          listNumber: listNumber,
          body: parsed.body,
          citations: parsed.citations,
        ),
      );
    }

    return blocks;
  }

  static ({String body, List<String> citations}) _extractCitations(
    String input,
  ) {
    final citations = <String>[];
    final body = input.replaceAllMapped(_citationPattern, (match) {
      final citation = _normalizeCitation(match.group(1)!);
      if (citation.isNotEmpty) citations.add(citation);
      return ' ';
    });

    return (
      body: _normalizeBody(body),
      citations: citations,
    );
  }

  static String _normalizeCitation(String raw) {
    final normalized = _collapseHisnWhitespace(
      raw.replaceAll(_collapseWhitespacePattern, ' '),
    ).replaceAll(_trailingCommaPattern, '');
    return isolateLtrNumerals(normalized);
  }

  /// Collapses Hisn DB line breaks before shared Arabic typography fixes.
  static String _collapseHisnWhitespace(String input) {
    return input
        .replaceAll(_spaceTabPattern, ' ')
        .replaceAll(_newlinePattern, ' ')
        .replaceAll(_collapseWhitespacePattern, ' ')
        .trim();
  }

  static String _normalizeBody(String input) {
    return ArabicTextNormalizer.normalize(_collapseHisnWhitespace(input));
  }
}
