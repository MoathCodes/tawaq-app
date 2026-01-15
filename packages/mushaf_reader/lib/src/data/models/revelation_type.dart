/// Represents the revelation type of a Surah.
///
/// In Islamic tradition, Surahs are classified based on where they were
/// revealed to the Prophet Muhammad (peace be upon him):
///
/// - [meccan]: Revealed before the migration (Hijra) to Medina
/// - [medinan]: Revealed after the migration to Medina
///
/// This classification is significant for understanding the historical
/// context and themes of each Surah.
enum RevelationType {
  /// Revealed before the Hijra (migration to Medina).
  ///
  /// Meccan Surahs typically focus on:
  /// - Monotheism (Tawhid)
  /// - The afterlife and Day of Judgment
  /// - Stories of previous prophets
  /// - Shorter verses with powerful imagery
  meccan,

  /// Revealed after the Hijra (migration to Medina).
  ///
  /// Medinan Surahs typically focus on:
  /// - Legal rulings and social legislation
  /// - Community organization
  /// - Interfaith relations
  /// - Longer verses with detailed guidance
  medinan,
}
