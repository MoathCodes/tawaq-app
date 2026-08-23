import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

part 'recitation_state.freezed.dart';

/// Unified, immutable source of truth for the recitation player.
@freezed
abstract class RecitationState with _$RecitationState {
  /// Creates a [RecitationState].
  const factory({
    /// Currently loaded reciter.
    Reciter? reciter,

    /// Currently loaded moshaf (riwayah).
    Moshaf? moshaf,

    /// Currently loaded surah number (1-114).
    int? surah,

    /// Ayah currently highlighted by playback, when timed.
    int? currentAyah,

    /// Global range start, null for whole-surah playback.
    AyahReference? rangeFrom,

    /// Global range end, null for open-ended or whole-surah playback.
    AyahReference? rangeTo,

    /// Whether the user explicitly stopped playback.
    @Default(false) bool userStopped,

    /// Monotonic generation counter incremented on every new load.
    @Default(0) int loadGeneration,

    /// Whether a timing timeline is still being fetched.
    @Default(false) bool timelinePending,

    /// Active sleep timer, if any.
    @Default(RecitationSleep.off) RecitationSleep sleep,

    /// Total duration of the loaded surah audio.
    @Default(Duration.zero) Duration duration,

    /// Current playback position.
    @Default(Duration.zero) Duration position,

    /// Unified playback status.
    @Default(RecitationStatus.idle) RecitationStatus status,

    /// Restores the saved session and Quran reference data before playback
    /// controls can become interactive. This is distinct from [status], which
    /// describes audio preparation and playback only.
    @Default(RecitationInitializationStatus.ready)
    RecitationInitializationStatus initializationStatus,

    /// Error from restoring the saved session or Quran reference data.
    String? initializationError,

    /// Last playback failure surfaced to the UI.
    String? error,

    /// Whether a recitation session is active (player chrome visible).
    @Default(false) bool active,

    /// Remaining repeats for the current selection (range-scope).
    @Default(1) int repeatsRemaining,

    /// Remaining repeats for the currently playing ayah (each-ayah-scope).
    @Default(1) int ayahRepeatsRemaining,

    /// Per-ayah repeat count for the active session.
    @Default(1) int ayahRepeatCount,

    /// True when mpv's A-B loop count reached zero and the final repetition
    /// of the current ayah is still playing; advance waits for real end time.
    @Default(false) bool ayahLoopExiting,

    /// Local segment start ayah within [surah] (for cross-surah ranges).
    /// Null when the segment covers the whole surah.
    int? segmentStartAyah,

    /// Local segment end ayah within [surah] (for cross-surah ranges).
    /// Null when the segment covers the whole surah.
    int? segmentEndAyah,

    /// Snapshot captured when an alert suspends playback, for later resume.
    RecitationState? suspendedSnapshot,

    /// Optimistic seek target; stale audio-position ticks are ignored until
    /// playback is near this value.
    Duration? pendingSeekTarget,
  }) = _RecitationState;

  const new _();

  /// Kind of playback selection active in the session.
  PlaybackSelectionKind get selectionKind {
    if (rangeFrom == null) return PlaybackSelectionKind.wholeSurah;
    if (rangeTo == null) return PlaybackSelectionKind.openEndedRange;
    return PlaybackSelectionKind.boundedRange;
  }

  /// Whether playback is constrained to a global ayah range (bounded or open).
  bool get hasRangeSelection =>
      selectionKind != PlaybackSelectionKind.wholeSurah;

  /// Whether the current selection is a specific ayah range.
  ///
  /// True for bounded and open-ended ranges; false for whole-surah playback.
  bool get isRange => hasRangeSelection && rangeFrom != null;

  /// Surah-local segment within the loaded [surah] for the current selection.
  ({int startAyah, int? endAyah})? get currentSegment {
    final loadedSurah = surah;
    final from = rangeFrom;
    if (loadedSurah == null || from == null) return null;

    final start =
        segmentStartAyah ?? (from.surah == loadedSurah ? from.ayah : 1);
    final end =
        segmentEndAyah ??
        (rangeTo != null && rangeTo!.surah == loadedSurah
            ? rangeTo!.ayah
            : null);
    return (startAyah: start, endAyah: end);
  }

  /// Segment-local [AyahReference] endpoints for reload/resume.
  ({AyahReference from, AyahReference? to})? get currentSegmentRefs {
    final loadedSurah = surah;
    final seg = currentSegment;
    if (loadedSurah == null || seg == null) return null;
    return (
      from: AyahReference(surah: loadedSurah, ayah: seg.startAyah),
      to: seg.endAyah != null
          ? AyahReference(surah: loadedSurah, ayah: seg.endAyah!)
          : null,
    );
  }

  /// Whether the global selection spans more than one surah.
  bool get isCrossSurahRange =>
      rangeFrom != null &&
      rangeTo != null &&
      rangeFrom!.surah != rangeTo!.surah;

  /// Whether the whole surah is the selection.
  bool get isWholeSurah =>
      surah != null && rangeFrom == null && rangeTo == null;

  /// Whether no media is loaded.
  bool get isIdle => status == RecitationStatus.idle;

  /// Whether media is opening/buffering/downloading.
  bool get isLoading => status == RecitationStatus.loading;

  /// Whether saved selection and Quran reference data are still loading.
  bool get isInitializing =>
      initializationStatus == RecitationInitializationStatus.initializing;

  /// Whether initialization failed and requires retry.
  bool get hasInitializationError =>
      initializationStatus == RecitationInitializationStatus.failed;

  /// Whether the restored selection may be presented and played.
  bool get isInitializationReady =>
      initializationStatus == RecitationInitializationStatus.ready;

  /// Whether actively playing.
  bool get isPlaying => status == RecitationStatus.playing;

  /// Whether paused with a loaded track.
  bool get isPaused => status == RecitationStatus.paused;

  /// Whether mid-playback buffering (network stall).
  bool get isBuffering => status == RecitationStatus.buffering;

  /// Whether playback failed.
  bool get isError => status == RecitationStatus.error;

  /// Whether the current selection finished and is ready to replay.
  bool get isEnded => status == RecitationStatus.ended;
}

/// Unified playback status for [RecitationState].
enum RecitationStatus {
  /// No active media and no metadata loaded.
  idle,

  /// Audio is opening, buffering, or downloading.
  loading,

  /// Mid-playback buffering (network stall).
  buffering,

  /// Actively playing.
  playing,

  /// Paused with a loaded track.
  paused,

  /// Playback failed.
  error,

  /// The current selection finished; press replay to start again.
  ended,
}

/// Initialization state for the persisted recitation session and Quran
/// reference data. It deliberately does not overlap with [RecitationStatus].
enum RecitationInitializationStatus {
  /// The saved selection or Quran reference data is still loading.
  initializing,

  /// The selection is safe to present and may be played by a user action.
  ready,

  /// Saved values remain persisted, but initialization must be retried.
  failed,
}

/// Kind of playback selection active in a recitation session.
enum PlaybackSelectionKind {
  /// Whole surah with no global range endpoints.
  wholeSurah,

  /// Global range with an explicit end (may span surahs).
  boundedRange,

  /// Open-ended range (continue from here to end of Quran).
  openEndedRange,
}

/// Canonical selection/repeat/timeline session state.
typedef RecitationSessionState = RecitationState;
