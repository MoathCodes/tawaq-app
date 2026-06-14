/// Known Quran reciters (IDs only — audio not bundled in v1).
enum RecitationSource {
  /// Placeholder for a future default reciter.
  placeholder,
}

/// Extension methods for [RecitationSource].
extension RecitationSourceX on RecitationSource {
  /// Stable identifier for persistence and URLs.
  String get id => name;

  /// Localized display name key suffix (l10n added when sources ship).
  String get displayName => switch (this) {
    RecitationSource.placeholder => 'Placeholder',
  };
}
