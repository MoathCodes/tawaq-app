/// Inline segment kinds discovered in Dorar sharh commentary.
enum HadithSharhSegmentKind {
  /// Plain commentary prose.
  prose,

  /// Matn phrase in `"…"` or «…».
  quote,

  /// Lexical gloss lead (`أي:` / `بمعنى:` / `المراد` / `ومعناها`).
  gloss,

  /// Dorar pedagogical pair: `"phrase"، أي: explanation`.
  glossChain,

  /// Narrator/scholar dialogue lead (`قال X:` / `فقال`).
  scholarLead,

  /// Alternate opinion stack (`وقيل:`).
  alternateOpinion,

  /// Section pivot (`وفي هذا الحديث` / `في الحديث:` / `وفيه:`).
  sectionLead,

  /// Editorial bracket content (`[هذا]`).
  editorialBracket,
}

/// A tokenized commentary segment.
class HadithSharhSegment {
  /// Creates a sharh segment.
  const HadithSharhSegment({
    required this.kind,
    required this.text,
    this.quotedPhrase,
    this.glossText,
  });

  /// Segment classification.
  final HadithSharhSegmentKind kind;

  /// Full matched text (or prose chunk).
  final String text;

  /// Quoted phrase for [HadithSharhSegmentKind.glossChain].
  final String? quotedPhrase;

  /// Gloss explanation for [HadithSharhSegmentKind.glossChain].
  final String? glossText;
}
