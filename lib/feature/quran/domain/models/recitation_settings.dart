import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_mode.dart';

part 'recitation_settings.freezed.dart';
part 'recitation_settings.g.dart';

/// Persisted recitation preferences (selected reciter and end-of-track mode).
@freezed
abstract class RecitationSettings with _$RecitationSettings {
  /// Creates [RecitationSettings].
  const factory RecitationSettings({
    /// Selected reciter id, or null until the user picks one.
    int? reciterId,

    /// Selected moshaf id within the reciter, or null for the primary moshaf.
    int? moshafId,

    /// End-of-selection behavior.
    @Default(RecitationMode.stopAtEnd) RecitationMode mode,

    /// Output volume (0-100).
    @Default(100) double volume,

    /// Whether the played ayah is highlighted in the mushaf.
    @Default(true) bool highlightAyah,

    /// Whether the page auto-scrolls/follows the played ayah.
    @Default(true) bool autoScroll,

    /// How many times the whole selection repeats (1 = play once).
    @Default(1) int repeatCount,
  }) = _RecitationSettings;

  /// Creates [RecitationSettings] from JSON.
  factory RecitationSettings.fromJson(Map<String, dynamic> json) =>
      _$RecitationSettingsFromJson(json);

  /// Default preferences for a new user.
  factory RecitationSettings.initial() => const RecitationSettings();
}
