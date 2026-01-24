/// Available tafsir (commentary) sources as an enum with metadata.
///
/// Use this enum instead of strings to reference tafsirs.
/// Add new tafsirs by adding new enum values.
enum TafsirId {
  /// التفسير الميسر - Arabic tafsir.
  tafseerMouaser(
    name: 'التفسير الميسر',
    language: 'Arabic',
    databasePath: 'assets/database/tafseer_mouaser.db',
  )
  ;

  const TafsirId({
    required this.name,
    required this.language,
    required this.databasePath,
  });

  /// Human-readable name.
  final String name;

  /// Language of the tafsir.
  final String language;

  /// Asset path to the SQLite database file.
  final String databasePath;
}
