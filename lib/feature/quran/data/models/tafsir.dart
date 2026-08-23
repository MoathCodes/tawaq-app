/// A single tafsir (commentary) entry from a tafsir database.
class Tafsir {
  /// Creates a tafsir entry.
  const new({
    required this.id,
    required this.suraNo,
    required this.ayaNo,
    required this.ayaTafseer,
  });

  /// Creates a tafsir from a database row map.
  factory fromMap(Map<String, dynamic> map) {
    return Tafsir(
      id: map['id'] as int,
      suraNo: map['sura_no'] as int,
      ayaNo: map['aya_no'] as int,
      ayaTafseer: map['aya_tafseer'] as String,
    );
  }

  /// The unique identifier from the database.
  final int id;

  /// The surah number (1-114).
  final int suraNo;

  /// The ayah number within the surah.
  final int ayaNo;

  /// The tafsir text explaining this ayah.
  final String ayaTafseer;

  @override
  String toString() => 'Tafsir(sura: $suraNo, aya: $ayaNo)';
}
