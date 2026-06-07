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
  const TafsirTruncationReport({
    required this.isLikelyTruncated,
    required this.reasons,
  });

  /// Whether any heuristic flagged the text.
  final bool isLikelyTruncated;

  /// All reasons that fired (may be empty).
  final List<TafsirTruncationReason> reasons;
}
