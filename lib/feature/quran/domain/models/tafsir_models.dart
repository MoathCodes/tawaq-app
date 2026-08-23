/// Semantic kind of a parsed tafsir text segment.
enum TafsirSegmentKind {
  /// Plain commentary prose.
  commentary,

  /// Quranic ayah text or citation (Mouaser `aya`, compact `t3`/`t4`).
  ayah,

  /// Qira'at reading or scholar quote (`t1`, double-quoted).
  qiraatQuote,

  /// Bracketed hadith label or editorial note (`t2`).
  reference,

  /// Inline lexical gloss (`t2` in As-Sa'di, mid-word emphasis).
  gloss,

  /// Surah/ayah cross-reference (`t3` with `( N - name )` pattern).
  crossReference,

  /// Arabic poetry bayt with two hemistichs (شطر).
  poetry,
}

/// A segment of parsed tafsir text.
class TafsirTextSegment {
  /// Creates a tafsir text segment.
  const new({
    required this.text,
    required this.kind,
    this.poetryHemistichs,
  });

  /// Segment text content.
  final String text;

  /// Semantic role of this segment for styling.
  final TafsirSegmentKind kind;

  /// When [kind] is [TafsirSegmentKind.poetry], the two hemistichs.
  final List<String>? poetryHemistichs;

  /// Whether this segment is Quranic ayah text (vs commentary).
  bool get isAyah => kind == TafsirSegmentKind.ayah;
}

/// Why raw tafsir text is considered likely truncated.
enum TafsirTruncationReason {
  /// More `</div>` closers than `<div>` openers in the raw markup.
  orphanClosingDiv,

  /// Unbalanced `(`, `)`, `[`, `]`, `«`, `»`, or `"` after HTML is stripped.
  unbalancedDelimiters,

  /// Commentary ends on a short Arabic fragment without closing punctuation.
  midWordEnding,

  /// Long entry ends with a very short tail that does not close a sentence.
  abruptTail,
}

/// Result of truncation analysis on raw tafsir markup.
class TafsirTruncationReport {
  /// Creates a truncation report.
  const new({
    required this.isLikelyTruncated,
    required this.reasons,
  });

  /// Whether any heuristic flagged the text.
  final bool isLikelyTruncated;

  /// All reasons that fired (may be empty).
  final List<TafsirTruncationReason> reasons;
}

/// Combined output of parsing raw tafsir markup and checking DB truncation.
class TafsirParseResult {
  /// Creates a parse result.
  const new({
    required this.segments,
    required this.truncationReport,
  });

  /// Styled commentary, ayah, quote, and reference segments.
  final List<TafsirTextSegment> segments;

  /// Heuristic truncation report from the raw markup.
  final TafsirTruncationReport truncationReport;
}
