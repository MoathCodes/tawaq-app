import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_models.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_metadata_parser.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_normalizer.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_zone_splitter.dart';

/// Parses raw Dorar sharh text into zones, segments, and metadata fields.
HadithSharhParsed parseHadithSharh(String raw) {
  final zones = HadithSharhZoneSplitter.split(raw);
  final segments = zones.commentary.isEmpty
      ? const <HadithSharhSegment>[]
      : HadithSharhSegmentTokenizer.tokenize(zones.commentary);
  final metadataFields = HadithSharhMetadataParser.parse(zones.metadata);

  return HadithSharhParsed(
    zones: zones,
    segments: segments,
    metadataFields: metadataFields,
  );
}

/// Tokenizes Dorar sharh commentary into styled inline segments.
abstract final class HadithSharhSegmentTokenizer {
  static final _glossChainClosePattern = RegExp(r'"\s*،\s*أي\s*:');
  static final _guillemetGlossChainClosePattern = RegExp(r'»\s*،\s*أي\s*:');
  static final _guillemetQuote = RegExp('«[^»]+»');
  static final _orphanPunctuationOnly = RegExp(r'^[\.،؛:!?\s]+$');
  static final _sectionLeadPattern = RegExp(
    r'(وفي هذا الحديث|في الحديث|وفيه)\s*:',
  );
  static final _alternateOpinionPattern = RegExp(r'وقيل\s*:');
  static final _editorialBracketPattern = RegExp(r'\[[^\]]+\]');
  static final _glossLeadPattern = RegExp(
    r'(?:^|[\s؛.،])(?:أي\s*:|بمعنى\s*:|المراد\s*:|ومعناها\s*:)',
  );
  static final _scholarLeadPattern = RegExp(
    r'(?:^|[\s؛.])(?:فقال(?:ت)?|قال)\s+(?!الله\s+تعالى)[^:]+:\s*',
  );
  static final _glossBoundary = RegExp(r'[؛.]|\s+(?:وقيل|وفي هذا الحديث|في الحديث|وفيه)\s*:');

  /// Tokenizes normalized [commentary] text.
  static List<HadithSharhSegment> tokenize(String commentary) {
    final normalized = HadithSharhNormalizer.normalize(commentary);
    if (normalized.isEmpty) return const [];

    final segments = <HadithSharhSegment>[];
    var cursor = 0;

    while (cursor < normalized.length) {
      final match = _nextMatch(normalized, cursor);
      if (match == null) {
        _appendProse(segments, normalized.substring(cursor));
        break;
      }

      if (match.start > cursor) {
        _appendProse(segments, normalized.substring(cursor, match.start));
      }

      segments.add(match.segment);
      cursor = match.end;
    }

    return segments;
  }

  static void _appendProse(List<HadithSharhSegment> segments, String text) {
    if (text.trim().isEmpty) return;

    if (_orphanPunctuationOnly.hasMatch(text.trim()) && segments.isNotEmpty) {
      final previous = segments.removeLast();
      segments.add(
        HadithSharhSegment(
          kind: previous.kind,
          text: previous.text + text,
          quotedPhrase: previous.quotedPhrase,
          glossText: previous.glossText,
        ),
      );
      return;
    }

    segments.add(
      HadithSharhSegment(kind: HadithSharhSegmentKind.prose, text: text),
    );
  }

  static _TokenMatch? _nextMatch(String input, int start) {
    _TokenMatch? best;

    final glossChain = _findGlossChain(input, start);
    if (glossChain != null) {
      best = _pickBest(best, glossChain);
    }

    final guillemetGlossChain = _findGuillemetGlossChain(input, start);
    if (guillemetGlossChain != null) {
      best = _pickBest(best, guillemetGlossChain);
    }

    for (final match in _sectionLeadPattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _TokenMatch(
          start: match.start,
          end: match.end,
          segment: HadithSharhSegment(
            kind: HadithSharhSegmentKind.sectionLead,
            text: match.group(0)!,
          ),
        ),
      );
      break;
    }

    for (final match in _alternateOpinionPattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _TokenMatch(
          start: match.start,
          end: match.end,
          segment: HadithSharhSegment(
            kind: HadithSharhSegmentKind.alternateOpinion,
            text: match.group(0)!,
          ),
        ),
      );
      break;
    }

    for (final match in _editorialBracketPattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _TokenMatch(
          start: match.start,
          end: match.end,
          segment: HadithSharhSegment(
            kind: HadithSharhSegmentKind.editorialBracket,
            text: match.group(0)!,
          ),
        ),
      );
      break;
    }

    for (final match in _guillemetQuote.allMatches(input, start)) {
      if (_isGuillemetGlossChainClose(input, match.end - 1)) continue;
      best = _pickBest(
        best,
        _TokenMatch(
          start: match.start,
          end: match.end,
          segment: HadithSharhSegment(
            kind: HadithSharhSegmentKind.quote,
            text: match.group(0)!,
          ),
        ),
      );
      break;
    }

    final asciiQuote = _findAsciiQuote(input, start);
    if (asciiQuote != null) {
      best = _pickBest(best, asciiQuote);
    }

    for (final match in _glossLeadPattern.allMatches(input, start)) {
      final leadText = match.group(0)!.trimLeft();
      final leadStart = match.start + (match.group(0)!.length - leadText.length);
      best = _pickBest(
        best,
        _TokenMatch(
          start: leadStart,
          end: match.end,
          segment: HadithSharhSegment(
            kind: HadithSharhSegmentKind.gloss,
            text: leadText,
          ),
        ),
      );
      break;
    }

    for (final match in _scholarLeadPattern.allMatches(input, start)) {
      final leadText = match.group(0)!.trimLeft();
      final leadStart = match.start + (match.group(0)!.length - leadText.length);
      best = _pickBest(
        best,
        _TokenMatch(
          start: leadStart,
          end: match.end,
          segment: HadithSharhSegment(
            kind: HadithSharhSegmentKind.scholarLead,
            text: leadText,
          ),
        ),
      );
      break;
    }

    return best;
  }

  /// Finds the next `"phrase"، أي:` pair using the closing anchor.
  ///
  /// Dorar sometimes emits orphan `"` marks (e.g. `؟"`) that break naive
  /// `[^"]+` scanning; anchoring on `"، أي:` and walking back to the opening
  /// quote recovers the intended phrase boundary.
  static _TokenMatch? _findGlossChain(String input, int start) {
    for (final match in _glossChainClosePattern.allMatches(input, start)) {
      final closeQuote = match.start;
      final openQuote = input.lastIndexOf('"', closeQuote - 1);
      if (openQuote < 0 || openQuote < start) continue;

      final phrase = input.substring(openQuote + 1, closeQuote);
      if (!_isValidQuotedPhrase(phrase)) continue;

      final glossStart = match.end;
      final glossEnd = _glossEnd(input, glossStart);
      return _TokenMatch(
        start: openQuote,
        end: glossEnd,
        segment: HadithSharhSegment(
          kind: HadithSharhSegmentKind.glossChain,
          text: input.substring(openQuote, glossEnd),
          quotedPhrase: '"$phrase"',
          glossText: input.substring(glossStart, glossEnd).trim(),
        ),
      );
    }
    return null;
  }

  /// Finds the next `«phrase»، أي:` pair using the closing guillemet anchor.
  static _TokenMatch? _findGuillemetGlossChain(String input, int start) {
    for (final match in _guillemetGlossChainClosePattern.allMatches(input, start)) {
      final closeGuillemet = match.start;
      final openGuillemet = input.lastIndexOf('«', closeGuillemet - 1);
      if (openGuillemet < 0 || openGuillemet < start) continue;

      final phrase = input.substring(openGuillemet + 1, closeGuillemet);
      if (!_isValidQuotedPhrase(phrase)) continue;

      final glossStart = match.end;
      final glossEnd = _glossEnd(input, glossStart);
      return _TokenMatch(
        start: openGuillemet,
        end: glossEnd,
        segment: HadithSharhSegment(
          kind: HadithSharhSegmentKind.glossChain,
          text: input.substring(openGuillemet, glossEnd),
          quotedPhrase: '«$phrase»',
          glossText: input.substring(glossStart, glossEnd).trim(),
        ),
      );
    }
    return null;
  }

  static _TokenMatch? _findAsciiQuote(String input, int start) {
    var searchFrom = start;
    while (searchFrom < input.length) {
      final openQuote = input.indexOf('"', searchFrom);
      if (openQuote < 0) return null;

      final closeQuote = input.indexOf('"', openQuote + 1);
      if (closeQuote < 0) return null;

      if (_isGlossChainClose(input, closeQuote)) {
        searchFrom = closeQuote + 1;
        continue;
      }

      final phrase = input.substring(openQuote + 1, closeQuote);
      if (!_isValidQuotedPhrase(phrase)) {
        searchFrom = openQuote + 1;
        continue;
      }

      return _TokenMatch(
        start: openQuote,
        end: closeQuote + 1,
        segment: HadithSharhSegment(
          kind: HadithSharhSegmentKind.quote,
          text: input.substring(openQuote, closeQuote + 1),
        ),
      );
    }
    return null;
  }

  static int _glossEnd(String input, int start) {
    var earliest = input.length;

    for (final match in _glossChainClosePattern.allMatches(input, start)) {
      final openQuote = input.lastIndexOf('"', match.start - 1);
      if (openQuote < 0 || openQuote < start) continue;

      final phrase = input.substring(openQuote + 1, match.start);
      if (!_isValidQuotedPhrase(phrase)) continue;

      earliest = openQuote;
      break;
    }

    for (final match in _guillemetGlossChainClosePattern.allMatches(input, start)) {
      final openGuillemet = input.lastIndexOf('«', match.start - 1);
      if (openGuillemet < 0 || openGuillemet < start) continue;

      final phrase = input.substring(openGuillemet + 1, match.start);
      if (!_isValidQuotedPhrase(phrase)) continue;

      if (openGuillemet < earliest) {
        earliest = openGuillemet;
        break;
      }
    }

    for (final match in _glossBoundary.allMatches(input, start)) {
      if (match.start < earliest) {
        earliest = match.start;
        break;
      }
    }

    return earliest;
  }

  static bool _isGlossChainClose(String input, int quoteIndex) {
    return _glossChainClosePattern.hasMatch(input.substring(quoteIndex));
  }

  static bool _isGuillemetGlossChainClose(String input, int guillemetCloseIndex) {
    return _guillemetGlossChainClosePattern.hasMatch(
      input.substring(guillemetCloseIndex),
    );
  }

  static bool _isValidQuotedPhrase(String phrase) {
    final trimmed = phrase.trimLeft();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('،') || trimmed.startsWith(':')) return false;
    return true;
  }

  static _TokenMatch? _pickBest(_TokenMatch? current, _TokenMatch candidate) {
    if (current == null || candidate.start < current.start) {
      return candidate;
    }
    return current;
  }
}

class _TokenMatch {
  const new({
    required this.start,
    required this.end,
    required this.segment,
  });

  final int start;
  final int end;
  final HadithSharhSegment segment;
}
