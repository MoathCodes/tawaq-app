import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_mode.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

part 'recitation_playback.freezed.dart';

/// Recitation-specific metadata for the footer mini-player. Play/pause and
/// position come from the shared audio service; this carries what is loaded.
@freezed
abstract class RecitationPlayback with _$RecitationPlayback {
  /// Creates a [RecitationPlayback].
  const factory RecitationPlayback({
    /// Currently loaded reciter.
    Reciter? reciter,

    /// Currently loaded moshaf.
    Moshaf? moshaf,

    /// Currently loaded surah number (1-114).
    int? surah,

    /// Ayah currently highlighted by playback (number in surah), when timed.
    int? currentAyah,

    /// Ephemeral mushaf highlight during playback (not persisted to settings).
    Ayah? playbackHighlightAyah,

    /// First ayah of the selection, or null for whole-surah playback.
    int? rangeStart,

    /// Last ayah of the selection, or null for whole-surah playback.
    int? rangeEnd,

    /// Global range start when the selection may span surahs.
    AyahReference? rangeFrom,

    /// Global range end when the selection may span surahs.
    AyahReference? rangeTo,

    /// End-of-selection behavior.
    @Default(RecitationMode.stopAtEnd) RecitationMode mode,

    /// Whether the current surah audio is downloading to cache.
    @Default(false) bool downloading,

    /// Whether a recitation is loaded (controls footer visibility).
    @Default(false) bool active,

    /// Active sleep timer, if any.
    @Default(RecitationSleep.off) RecitationSleep sleep,

    /// Total duration of the loaded surah audio. Fed by the player's duration
    /// stream (with a timing-derived estimate as a fallback) so the scrubber
    /// has a reliable total even when a late widget subscription misses the
    /// player's one-time duration emit.
    @Default(Duration.zero) Duration duration,

    /// Last playback failure surfaced to the UI (cleared on the next load).
    String? playbackError,
  }) = _RecitationPlayback;

  const RecitationPlayback._();

  /// Whether a specific ayah range is selected in the loaded surah.
  bool get isRange => rangeStart != null && rangeEnd != null;

  /// Whether the global selection spans more than one surah.
  bool get isCrossSurahRange =>
      rangeFrom != null &&
      rangeTo != null &&
      rangeFrom!.surah != rangeTo!.surah;

  /// Whether the whole surah is the selection.
  bool get isWholeSurah =>
      surah != null && rangeStart == null && rangeEnd == null;
}
