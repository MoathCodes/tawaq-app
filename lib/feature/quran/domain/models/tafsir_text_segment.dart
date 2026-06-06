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
  const TafsirTextSegment({
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
