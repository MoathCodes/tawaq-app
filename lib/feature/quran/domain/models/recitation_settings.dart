import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';

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

    /// Output volume (0-100).
    @Default(100) double volume,

    /// Whether the played ayah is highlighted in the mushaf.
    @Default(true) bool highlightAyah,

    /// Whether the page auto-scrolls/follows the played ayah.
    @Default(true) bool autoScroll,

    /// How many times each ayah repeats before advancing (1 = no per-ayah loop).
    @Default(1) int ayahRepeatCount,

    /// How many times the whole selection repeats (1 = play once).
    @Default(1) int rangeRepeatCount,

    /// Last played surah (1-114), restored on the next launch.
    int? lastSurah,

    /// Cross-surah range start surah (null when the range is single-surah).
    int? lastRangeFromSurah,

    /// Cross-surah range start ayah (null when the range is single-surah).
    int? lastRangeFromAyah,

    /// Cross-surah range end surah (null when the range is single-surah).
    int? lastRangeToSurah,

    /// Cross-surah range end ayah (null when the range is single-surah).
    int? lastRangeToAyah,

    /// Last range scope preset selected in the range dialog.
    RangeScopePreset? lastRangePreset,

    /// Last saved playback offset in ms (ayah start for timed, exact for untimed).
    int? lastPlaybackPositionMs,

    /// Whether surah audio is downloaded to disk automatically while listening.
    ///
    /// When false, playback streams from the network unless the surah was
    /// saved explicitly for offline use.
    @Default(true) bool autoSaveRecitations,
  }) = _RecitationSettings;

  /// Creates [RecitationSettings] from JSON.
  factory RecitationSettings.fromJson(Map<String, dynamic> json) =>
      _$RecitationSettingsFromJson(json);

  /// Default preferences for a new user.
  factory RecitationSettings.initial() => const RecitationSettings();
}
