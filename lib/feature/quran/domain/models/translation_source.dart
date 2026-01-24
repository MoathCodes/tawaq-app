/// Available translation sources as an enum with metadata.
///
/// Use this enum instead of strings to reference translations.
/// Add new translations by adding new enum values.
enum TranslationId {
  /// Saheeh International English translation.
  saheehInternational(
    name: 'Saheeh International',
    language: 'English',
    databasePath: 'assets/database/saheeh_international.db',
  )
  ;

  const TranslationId({
    required this.name,
    required this.language,
    required this.databasePath,
  });

  /// Human-readable name.
  final String name;

  /// Language of the translation.
  final String language;

  /// Asset path to the SQLite database file.
  final String databasePath;
}
