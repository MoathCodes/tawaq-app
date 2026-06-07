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
