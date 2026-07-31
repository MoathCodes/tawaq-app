import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

/// Land tolerance for pending intentional seeks (scrub / skip / navigate).
///
/// Position ticks farther than this from [RecitationState.pendingSeekTarget]
/// are ignored so stale engine positions do not thrash highlight / range-end.
const pendingSeekToleranceMs = 500;

/// Wall-clock timeout before a pending seek is abandoned and UI reverts.
const pendingSeekTimeout = Duration(seconds: 2);

/// Epsilon used when deciding whether playback is "at the end of the track"
/// for resume-from-start behavior on toggle.
const nearTrackEndTolerance = Duration(milliseconds: 500);

/// Clamp for ayah / range repeat counts accepted from settings or UI.
int clampRepeatCount(int count) => count.clamp(1, 99);

/// Whether [position] is within [pendingSeekToleranceMs] of [target].
bool positionNearTarget(Duration position, Duration target) {
  return (position.inMilliseconds - target.inMilliseconds).abs() <=
      pendingSeekToleranceMs;
}

/// Whether [position] is near the end of [duration] (toggle resume-from-start).
bool isNearTrackEnd(Duration position, Duration duration) {
  return position >= duration - nearTrackEndTolerance &&
      duration > Duration.zero;
}

/// Whole-surah sessions with no per-ayah repeat may use mpv file loop.
bool eligibleForNativeFileLoop(RecitationState state) {
  return state.isWholeSurah && state.ayahRepeatCount <= 1;
}

/// Whether the session should arm native file loop for remaining repeats.
bool shouldUseNativeFileLoop(RecitationState state) {
  return eligibleForNativeFileLoop(state) && state.repeatsRemaining > 1;
}

/// Current ayah from state, or guess from [timeline] at [state.position].
int? currentAyahOrGuess(
  RecitationState state,
  RecitationTimeline timeline,
) {
  return state.currentAyah ?? timeline.ayahAt(state.position);
}

/// First ayah of the current selection (or 1 for whole surah).
int firstPlayableAyah(RecitationState state) {
  return state.currentSegment?.startAyah ?? 1;
}

/// Last ayah of the current selection, or last timed ayah of the surah.
int? lastPlayableAyah(
  RecitationState state,
  RecitationTimeline timeline,
) {
  final segEnd = state.currentSegment?.endAyah;
  if (segEnd != null) return segEnd;
  final ayat = timeline.timing?.ayat.where((a) => a.ayah > 0).toList();
  return ayat?.lastOrNull?.ayah;
}

/// Whether there is a next ayah after [currentAyah] within the selection.
bool hasNextAyahAfterLoop({
  required RecitationState state,
  required RecitationTimeline timeline,
  required int currentAyah,
}) {
  final nextAyah = currentAyah + 1;
  final endAyah = state.currentSegment?.endAyah;
  if (endAyah != null) {
    return nextAyah <= endAyah && timeline.startOfAyah(nextAyah) != null;
  }
  return timeline.startOfAyah(nextAyah) != null &&
      timeline.endOfAyah(nextAyah) != null;
}

/// True when a bounded range selection has reached its end boundary.
bool isPastRangeEnd({
  required RecitationState state,
  required RecitationTimeline timeline,
  required Duration position,
}) {
  if (state.ayahRepeatCount > 1 || !state.isRange) return false;
  final endBoundary = timeline.rangeEnd;
  return position >= endBoundary && state.duration > Duration.zero;
}

/// True when mpv's A-B loop wrapped the current ayah (position jumped back).
///
/// Used only for UI repeat-counter heuristics; playback advance is driven by
/// native `remainingAbLoops` / [RecitationState.ayahLoopExiting].
bool detectAyahLoopWrap(
  RecitationState state,
  Duration newPosition,
  RecitationTimeline timeline,
) {
  final ayah = state.currentAyah;
  if (ayah == null || state.ayahRepeatsRemaining <= 1) return false;

  final start = timeline.startOfAyah(ayah);
  final end = timeline.endOfAyah(ayah);
  if (start == null || end == null) return false;

  final prevMs = state.position.inMilliseconds;
  final newMs = newPosition.inMilliseconds;
  final startMs = start.inMilliseconds;
  final endMs = end.inMilliseconds;
  final span = endMs - startMs;
  if (span <= 0) return false;

  final wasNearEnd = prevMs >= startMs + (span * 0.55);
  final isNearStart = newMs <= startMs + (span * 0.45);
  final jumpedBack = newMs < prevMs - 80;

  return wasNearEnd && isNearStart && jumpedBack;
}

/// Content boundary for [state.sleep], or null when sleep is off / countdown.
Duration? sleepBoundary(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  return switch (state.sleep) {
    RecitationSleep.off => null,
    RecitationSleep.endOfAyah => state.currentAyah == null
        ? null
        : timeline.endOfAyah(state.currentAyah!),
    RecitationSleep.endOfRange => timeline.rangeEnd,
    RecitationSleep.endOfSurah =>
      state.duration > Duration.zero ? state.duration : null,
    _ => null,
  };
}

/// Prefer timing-derived duration when the engine reports a shorter value.
Duration mergeReportedDuration({
  required Duration current,
  required Duration reported,
}) {
  final timingMs = current.inMilliseconds;
  final candidateMs = timingMs > 0 && reported.inMilliseconds < timingMs
      ? timingMs
      : reported.inMilliseconds;
  return Duration(milliseconds: candidateMs);
}
