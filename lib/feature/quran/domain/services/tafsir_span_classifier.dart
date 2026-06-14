import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_segment_repair.dart';

/// Source-aware heuristics for compact tafsir span kinds (`t2`/`t3`).
abstract final class TafsirSpanClassifier {
  static const _longT2Threshold = 80;

  static final _t3EditorialMarker = RegExp(
    r'^\(\s*(?:قال|فعل|مسألة|قلت|قلt|وقيل)\s*\)$',
    caseSensitive: false,
  );

  static final _t3PartialVerseFragment = RegExp(
    r'^\(\s*(?:الرحمن\s+الرحيم|صراط\s+الذين|بسم\s+الله(?:\s+الرحمن\s+الرحيم)?)\s*\)?',
    caseSensitive: false,
  );

  static final _t3CompositeMarker = RegExp(
    r'كما\s+في\s+حديث|وقيل\s*:|وفي\s+هذا',
    caseSensitive: false,
  );

  static final _t3ProsePivot = RegExp(
    r'^(?:وفي\s+هذا|وقيل\s*:|كما\s+(?:في\s+حديث|تقدم)|قال\s)',
    caseSensitive: false,
  );

  static final _t2SurahCitation = RegExp(
    r'^\[\s*(?:\d+\s*-\s*.+|\S+\s*:\s*\d+)\s*\]$',
    caseSensitive: false,
  );

  static final _t2IkEditorial = RegExp(
    r'^\[\s*(?:قال|فقال|إنما|أحدها|معنى|كما\s+تقدم)\s*\]$',
    caseSensitive: false,
  );

  static final _t2MidWordEmphasis = RegExp(
    r'^\[\s+([\u0600-\u06FF]{2,5})\s+\]$',
  );

  /// Classifies a parsed span into one or more segments.
  static List<TafsirTextSegment> classifySpan({
    required String cssClass,
    required String content,
    TafsirId? tafsirId,
  }) {
    return switch (cssClass.toLowerCase()) {
      'aya' || 't4' => [_segment(content, TafsirSegmentKind.ayah)],
      't1' => [_segment(content, TafsirSegmentKind.qiraatQuote)],
      't2' => _classifyT2(content, tafsirId),
      't3' => _classifyT3(content, tafsirId),
      _ => [_segment(content, TafsirSegmentKind.commentary)],
    };
  }

  static List<TafsirTextSegment> _classifyT2(
    String content,
    TafsirId? tafsirId,
  ) {
    final trimmed = content.trim();

    if (_t2SurahCitation.hasMatch(trimmed)) {
      return [_segment(content, TafsirSegmentKind.reference)];
    }

    if (trimmed.length > _longT2Threshold) {
      return [_segment(content, TafsirSegmentKind.commentary)];
    }

    if (_isIkEditorialT2(trimmed, tafsirId)) {
      return [_segment(content, TafsirSegmentKind.commentary)];
    }

    if (_t2MidWordEmphasis.hasMatch(trimmed)) {
      return [_segment(content, TafsirSegmentKind.gloss)];
    }

    if (_isAsSadiGloss(trimmed, tafsirId)) {
      return [_segment(content, TafsirSegmentKind.gloss)];
    }

    return [_segment(content, TafsirSegmentKind.reference)];
  }

  static List<TafsirTextSegment> _classifyT3(
    String content,
    TafsirId? tafsirId,
  ) {
    final trimmed = content.trim();

    if (TafsirSegmentRepair.isSurahCrossReference(trimmed)) {
      return [_segment(content, TafsirSegmentKind.crossReference)];
    }

    if (!trimmed.startsWith('(')) {
      return [_segment(content, TafsirSegmentKind.commentary)];
    }

    if (_t3EditorialMarker.hasMatch(trimmed)) {
      return [_segment(content, TafsirSegmentKind.commentary)];
    }

    if (_t3PartialVerseFragment.hasMatch(trimmed)) {
      return [_segment(content, TafsirSegmentKind.commentary)];
    }

    final isComposite =
        _t3CompositeMarker.hasMatch(trimmed) ||
        _hasNestedParenthetical(trimmed);

    final split = _splitMegaT3Span(content);
    if (split != null) {
      return [
        _segment(split.ayahPart, TafsirSegmentKind.ayah),
        _segment(split.commentaryPart, TafsirSegmentKind.commentary),
      ];
    }

    if (isComposite) {
      return [_segment(content, TafsirSegmentKind.commentary)];
    }

    return [_segment(content, TafsirSegmentKind.ayah)];
  }

  static bool _isIkEditorialT2(String trimmed, TafsirId? tafsirId) {
    if (!_t2IkEditorial.hasMatch(trimmed)) return false;
    if (tafsirId == null) return true;
    return tafsirId == TafsirId.ibnKathir || tafsirId == TafsirId.baghawi;
  }

  static bool _isAsSadiGloss(String trimmed, TafsirId? tafsirId) {
    if (tafsirId != null && tafsirId != TafsirId.asSadi) return false;
    if (!_isBracketWrapped(trimmed)) return false;
    final inner = _bracketInner(trimmed);
    if (inner.isEmpty || inner.length > 24) return false;
    if (RegExp(r'\d|[-:]').hasMatch(inner)) return false;
    return tafsirId == TafsirId.asSadi;
  }

  static bool _isBracketWrapped(String trimmed) {
    return trimmed.startsWith('[') && trimmed.endsWith(']');
  }

  static String _bracketInner(String trimmed) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }

  static bool _hasNestedParenthetical(String trimmed) {
    final openIndex = trimmed.indexOf('(');
    if (openIndex < 0) return false;
    final closeIndex = _indexOfBalancedClose(trimmed, openIndex);
    if (closeIndex < 0) return false;
    return trimmed.indexOf('(', openIndex + 1) >= 0 ||
        trimmed.indexOf('(', closeIndex + 1) >= 0;
  }

  static ({String ayahPart, String commentaryPart})? _splitMegaT3Span(
    String content,
  ) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('(')) return null;

    final openIndex = trimmed.indexOf('(');
    final closeIndex = _indexOfBalancedClose(trimmed, openIndex);
    if (closeIndex < 0) return null;

    final remainder = trimmed.substring(closeIndex + 1).trimLeft();
    if (remainder.isEmpty) return null;
    if (!_t3ProsePivot.hasMatch(remainder) &&
        !_t3CompositeMarker.hasMatch(remainder) &&
        !_hasNestedParenthetical(trimmed)) {
      return null;
    }

    return (
      ayahPart: trimmed.substring(0, closeIndex + 1),
      commentaryPart: remainder,
    );
  }

  static int _indexOfBalancedClose(String text, int openIndex) {
    var depth = 0;
    for (var i = openIndex; i < text.length; i++) {
      final char = text[i];
      if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static TafsirTextSegment _segment(String text, TafsirSegmentKind kind) {
    return TafsirTextSegment(text: text, kind: kind);
  }
}
