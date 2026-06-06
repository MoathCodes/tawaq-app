import 'package:json_annotation/json_annotation.dart';

/// Quran mushaf text size presets (independent of app UI scale).
@JsonEnum()
enum QuranTextScale {
  /// Smallest mushaf preset.
  small,

  /// Default mushaf preset.
  medium,

  /// Large mushaf preset.
  large,

  /// Largest mushaf preset.
  extraLarge,
  ;

  /// Multiplier applied after mushaf auto-fit (crisp font sizes, no overflow).
  double get boost => switch (this) {
    QuranTextScale.small => 0.9,
    QuranTextScale.medium => 1,
    QuranTextScale.large => 1.08,
    QuranTextScale.extraLarge => 1.12,
  };

  /// Approximate preview size for settings UI (not used for mushaf rendering).
  double get previewFontSize => 26 * boost;

  /// Maps legacy persisted font-size index to the nearest preset.
  static QuranTextScale fromLegacyIndex(int index) => switch (index) {
    0 => QuranTextScale.small,
    1 => QuranTextScale.medium,
    2 => QuranTextScale.large,
    3 => QuranTextScale.extraLarge,
    _ => QuranTextScale.medium,
  };

  /// Parses JSON values from persisted state (supports legacy `fontSize`).
  static QuranTextScale fromJsonValue(Object? value) {
    if (value == null) return QuranTextScale.medium;
    if (value is int) return fromLegacyIndex(value);
    if (value is String) {
      return QuranTextScale.values.firstWhere(
        (e) => e.name == value,
        orElse: () => QuranTextScale.medium,
      );
    }
    return QuranTextScale.medium;
  }
}
