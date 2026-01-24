/// A single translation entry from a translation database.
class Translation {
  /// Creates a translation entry.
  const Translation({
    required this.id,
    required this.sura,
    required this.aya,
    required this.translation,
    this.footnotes,
  });

  /// Creates a translation from a database row map.
  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      id: map['id'] as int,
      sura: map['sura'] as int,
      aya: map['aya'] as int,
      translation: map['translation'] as String,
      footnotes: map['footnotes'] as String?,
    );
  }

  /// The unique identifier from the database.
  final int id;

  /// The surah number (1-114).
  final int sura;

  /// The ayah number within the surah.
  final int aya;

  /// The translated text of the ayah.
  final String translation;

  /// Optional footnotes for this translation.
  final String? footnotes;

  @override
  String toString() => 'Translation(sura: $sura, aya: $aya)';
}
