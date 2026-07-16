/// Structural zones of a Dorar hadith sharh string.
class HadithSharhZones {
  /// Creates sharh zones.
  const HadithSharhZones({
    required this.commentary,
    this.matnPrefix,
    this.metadata,
  });

  /// Matn text duplicated before the metadata block (metadata-rich family).
  final String? matnPrefix;

  /// Raw metadata block (`الراوي` … `التخريج`).
  final String? metadata;

  /// Commentary body after metadata (or the full text for pure-essay family).
  final String commentary;

  /// Whether this sharh uses the metadata-rich Dorar layout.
  bool get isMetadataRich => metadata != null;
}

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

/// Known Dorar sharh metadata header labels in display order.
enum HadithSharhMetadataLabel {
  /// Narrator (`الراوي`).
  rawi('الراوي'),

  /// Hadith scholar (`المحدث`).
  mohdith('المحدث'),

  /// Source book (`المصدر`).
  source('المصدر'),

  /// Page or hadith number (`الصفحة أو الرقم`).
  pageOrNumber('الصفحة أو الرقم'),

  /// Grading summary (`خلاصة حكم المحدث`).
  grade('خلاصة حكم المحدث'),

  /// External citation chain (`التخريج`).
  takhrij('التخريج');

  const HadithSharhMetadataLabel(this.arabicLabel);

  /// Arabic label text as it appears in Dorar metadata blocks.
  final String arabicLabel;

  /// Metadata fields in UI and parser order.
  static const List<HadithSharhMetadataLabel> displayOrder = [
    rawi,
    mohdith,
    source,
    pageOrNumber,
    grade,
    takhrij,
  ];
}

/// Structured Dorar sharh metadata header fields.
class HadithSharhMetadataFields {
  /// Creates parsed sharh metadata fields.
  const HadithSharhMetadataFields({
    this.rawi,
    this.mohdith,
    this.source,
    this.pageOrNumber,
    this.grade,
    this.takhrij,
  });

  /// Narrator (`الراوي`).
  final String? rawi;

  /// Hadith scholar (`المحدث`).
  final String? mohdith;

  /// Source book (`المصدر`).
  final String? source;

  /// Page or hadith number (`الصفحة أو الرقم`).
  final String? pageOrNumber;

  /// Grading summary (`خلاصة حكم المحدث`).
  final String? grade;

  /// External citation chain (`التخريج`).
  final String? takhrij;

  /// Whether any field was parsed.
  bool get hasAny =>
      rawi != null ||
      mohdith != null ||
      source != null ||
      pageOrNumber != null ||
      grade != null ||
      takhrij != null;

  /// Returns the parsed value for [label], if present.
  String? valueFor(HadithSharhMetadataLabel label) {
    return switch (label) {
      HadithSharhMetadataLabel.rawi => rawi,
      HadithSharhMetadataLabel.mohdith => mohdith,
      HadithSharhMetadataLabel.source => source,
      HadithSharhMetadataLabel.pageOrNumber => pageOrNumber,
      HadithSharhMetadataLabel.grade => grade,
      HadithSharhMetadataLabel.takhrij => takhrij,
    };
  }

  /// Non-empty metadata entries in [HadithSharhMetadataLabel.displayOrder].
  Iterable<({HadithSharhMetadataLabel label, String value})>
      get populatedEntries sync* {
    for (final label in HadithSharhMetadataLabel.displayOrder) {
      final value = valueFor(label)?.trim();
      if (value != null && value.isNotEmpty) {
        yield (label: label, value: value);
      }
    }
  }
}

/// Parsed Dorar sharh ready for presentation.
class HadithSharhParsed {
  /// Creates a parsed sharh view model.
  const HadithSharhParsed({
    required this.zones,
    required this.segments,
    required this.metadataFields,
  });

  /// Structural zones (matn prefix, metadata block, commentary).
  final HadithSharhZones zones;

  /// Tokenized commentary segments.
  final List<HadithSharhSegment> segments;

  /// Parsed metadata header fields.
  final HadithSharhMetadataFields metadataFields;

  /// Whether the sharh has displayable metadata or matn prefix content.
  bool get hasMetadataContent =>
      zones.matnPrefix != null || metadataFields.hasAny;
}
