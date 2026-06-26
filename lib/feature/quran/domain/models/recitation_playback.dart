import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_mode.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

part 'recitation_playback.freezed.dart';

/// Playback status for the unified recitation state.
enum RecitationStatus {
  /// No active media and no metadata loaded.
  idle,

  /// Audio is opening, buffering, or downloading.
  loading,

  /// Actively playing.
  playing,

  /// Paused with a loaded track.
  paused,

  /// Playback failed.
  error,
}

/// Unified recitation state — the single source of truth for the player UI.
///
/// Combines what was previously split across [RecitationPlayback] (metadata)
/// and [PlaybackState] (status/position) so widgets always read a consistent
/// snapshot from one provider.
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

    /// Total duration of the loaded surah audio.
    @Default(Duration.zero) Duration duration,

    /// Current playback position.
    @Default(Duration.zero) Duration position,

    /// Unified playback status.
    @Default(RecitationStatus.idle) RecitationStatus status,

    /// Last playback failure surfaced to the UI (cleared on the next load).
    String? playbackError,

    /// Pending reciter switch (chosen in dialog but not yet committed via play).
    Reciter? pendingReciter,

    /// Pending moshaf for the pending reciter switch.
    Moshaf? pendingMoshaf,
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

  /// Shorthand checks for the current [status].
  bool get isIdle => status == RecitationStatus.idle;
  bool get isLoading => status == RecitationStatus.loading;
  bool get isPlaying => status == RecitationStatus.playing;
  bool get isPaused => status == RecitationStatus.paused;
  bool get isError => status == RecitationStatus.error;

  /// Whether a reciter switch is pending (selected in dialog, awaiting play).
  bool get hasPendingReciter => pendingReciter != null;
}
