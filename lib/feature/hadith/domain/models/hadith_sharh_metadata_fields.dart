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
