import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
// The event/effect classes are self-describing and the file has many long
// switch signatures, so suppress documentation and line-length lints.
// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

/// Result of a state-machine transition: the next state and any side effects
/// the controller must execute.
typedef RecitationTransition = ({
  RecitationState state,
  List<RecitationEffect> effects,
});

/// Pure state machine for the recitation player.
///
/// The controller feeds events in response to user actions and audio service
/// stream updates. The machine returns the new immutable state plus a list of
/// effects (load, pause, resume, seek, etc.) for the controller to execute.
RecitationTransition transition(
  RecitationState state,
  RecitationEvent event, {
  required RecitationTimeline timeline,
  required int defaultAyahRepeatCount,
  required int defaultRangeRepeatCount,
}) {
  final ayahCount = defaultAyahRepeatCount.clamp(1, 99);
  final rangeCount = defaultRangeRepeatCount.clamp(1, 99);

  switch (event) {
    case PlaySurah():
      return _playSurah(
        state,
        event,
        timeline: timeline,
        ayahRepeatCount: ayahCount,
        rangeRepeatCount: rangeCount,
      );
    case PlayRange():
      return _playRange(
        state,
        event,
        timeline: timeline,
        ayahRepeatCount: ayahCount,
        rangeRepeatCount: rangeCount,
      );
    case TogglePlayPause():
      return _togglePlayPause(state, timeline: timeline);
    case Seek():
      return _seek(state, event, timeline: timeline);
    case Stop():
      return _stop(state);
    case SkipNext():
      return _skipNext(state, timeline: timeline);
    case SkipPrevious():
      return _skipPrevious(state, timeline: timeline);
    case SetSleep():
      return _setSleep(state, event);
    case AudioPosition():
      return _onAudioPosition(state, event, timeline: timeline);
    case AudioDuration():
      return _onAudioDuration(state, event);
    case AudioStarted():
      return _onAudioStarted(state);
    case AudioBuffering():
      return _onAudioBuffering(state);
    case AudioLoading():
      return _onAudioLoading(state);
    case AudioPaused():
      return _onAudioPaused(state);
    case AudioCompleted():
      return _onAudioCompleted(state, timeline: timeline);
    case AudioError():
      return _onAudioError(state, event);
    case AlertSuspend():
      return _alertSuspend(state);
    case AlertResume():
      return _alertResume(state);
    case SetRepeatCounts():
      return _setRepeatCounts(state, event);
    case RecitationSettingsLoaded():
      return _settingsLoaded(state, event);
    case AyahLoopExhausted():
      return _onAudioAbLoopExhausted(state, timeline: timeline);
    case GaplessTrackAdvanced():
      return _onGaplessTrackAdvanced(state, event);
  }
}

PlayRange _playRangeFromState(
  RecitationState state, {
  required Reciter reciter,
  required Moshaf moshaf,
  Duration? resumeFrom,
}) {
  final seg = state.currentSegmentRefs!;
  return PlayRange(
    reciter: reciter,
    moshaf: moshaf,
    from: seg.from,
    to: seg.to,
    globalFrom: state.rangeFrom,
    globalTo: state.rangeTo,
    resumeFrom: resumeFrom,
  );
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// Base class for recitation state-machine events.
sealed class RecitationEvent {
  const RecitationEvent();
}

/// Load and play a whole surah.
final class PlaySurah extends RecitationEvent {
  /// Creates [PlaySurah].
  const PlaySurah({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    this.resumeFrom,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int surah;
  final Duration? resumeFrom;
}

/// Load and play a global ayah range.
final class PlayRange extends RecitationEvent {
  /// Creates [PlayRange].
  const PlayRange({
    required this.reciter,
    required this.moshaf,
    required this.from,
    this.to,
    this.globalFrom,
    this.globalTo,
    this.resumeFrom,
  });

  final Reciter reciter;
  final Moshaf moshaf;

  /// Segment-local start (always in the surah being loaded).
  final AyahReference from;

  /// Segment-local end, or null for whole-surah.
  final AyahReference? to;

  /// Global range start; falls back to [from] when null.
  final AyahReference? globalFrom;

  /// Global range end; falls back to [to] when null.
  final AyahReference? globalTo;

  final Duration? resumeFrom;
}

/// Play/pause toggle.
final class TogglePlayPause extends RecitationEvent {
  /// Creates [TogglePlayPause].
  const TogglePlayPause();
}

/// Seek to [position].
final class Seek extends RecitationEvent {
  /// Creates [Seek].
  const Seek(this.position);

  final Duration position;
}

/// Stop playback but keep the session visible.
final class Stop extends RecitationEvent {
  /// Creates [Stop].
  const Stop();
}

/// Advance to the next ayah (within range) or the next surah.
final class SkipNext extends RecitationEvent {
  /// Creates [SkipNext].
  const SkipNext();
}

/// Go back to the previous ayah (within range) or the previous surah.
final class SkipPrevious extends RecitationEvent {
  /// Creates [SkipPrevious].
  const SkipPrevious();
}

/// Change sleep timer.
final class SetSleep extends RecitationEvent {
  /// Creates [SetSleep].
  const SetSleep(this.sleep);

  final RecitationSleep sleep;
}

/// Audio position tick.
final class AudioPosition extends RecitationEvent {
  /// Creates [AudioPosition].
  const AudioPosition(this.position);

  final Duration position;
}

/// Audio total duration reported.
final class AudioDuration extends RecitationEvent {
  /// Creates [AudioDuration].
  const AudioDuration(this.duration);

  final Duration duration;
}

/// Audio service started playing.
final class AudioStarted extends RecitationEvent {
  /// Creates [AudioStarted].
  const AudioStarted();
}

/// Audio service is buffering.
final class AudioBuffering extends RecitationEvent {
  /// Creates [AudioBuffering].
  const AudioBuffering();
}

/// Audio service is loading/buffering.
final class AudioLoading extends RecitationEvent {
  /// Creates [AudioLoading].
  const AudioLoading();
}

/// Audio service paused.
final class AudioPaused extends RecitationEvent {
  /// Creates [AudioPaused].
  const AudioPaused();
}

/// Audio track reached its end.
final class AudioCompleted extends RecitationEvent {
  /// Creates [AudioCompleted].
  const AudioCompleted();
}

/// Audio track failed.
final class AudioError extends RecitationEvent {
  /// Creates [AudioError].
  const AudioError(this.message);

  final String message;
}

/// Pause for an adhan/iqamah alert.
final class AlertSuspend extends RecitationEvent {
  /// Creates [AlertSuspend].
  const AlertSuspend();
}

/// Resume after an alert.
final class AlertResume extends RecitationEvent {
  /// Creates [AlertResume].
  const AlertResume();
}

/// Updates the repeat budgets from persisted settings.
final class SetRepeatCounts extends RecitationEvent {
  /// Creates [SetRepeatCounts].
  const SetRepeatCounts({this.ayahRepeatCount, this.rangeRepeatCount});

  final int? ayahRepeatCount;
  final int? rangeRepeatCount;
}

/// Fired when the native mpv A-B loop count reaches zero for the current
/// ayah. Used to advance to the next ayah in each-ayah repeat mode.
final class AyahLoopExhausted extends RecitationEvent {
  /// Creates [AyahLoopExhausted].
  const AyahLoopExhausted();
}

/// Restores a persisted session without starting playback.
final class RecitationSettingsLoaded extends RecitationEvent {
  /// Creates [RecitationSettingsLoaded].
  const RecitationSettingsLoaded({
    this.reciter,
    this.moshaf,
    this.surah,
    this.rangeFrom,
    this.rangeTo,
  });

  final Reciter? reciter;
  final Moshaf? moshaf;
  final int? surah;
  final AyahReference? rangeFrom;
  final AyahReference? rangeTo;
}

/// Gapless playlist advanced to a new surah.
final class GaplessTrackAdvanced extends RecitationEvent {
  /// Creates [GaplessTrackAdvanced].
  const GaplessTrackAdvanced({required this.surah, required this.ayah});

  /// The surah now playing.
  final int surah;

  /// The ayah now highlighted.
  final int ayah;
}

// ---------------------------------------------------------------------------
// Effects
// ---------------------------------------------------------------------------

/// Side effect the controller must execute.
sealed class RecitationEffect {
  const RecitationEffect();
}

/// Load a whole surah and optionally seek.
final class LoadSurah extends RecitationEffect {
  /// Creates [LoadSurah].
  const LoadSurah({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    this.seekTo,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int surah;
  final Duration? seekTo;
}

/// Load a global range and optionally seek.
final class LoadRange extends RecitationEffect {
  /// Creates [LoadRange].
  const LoadRange({
    required this.reciter,
    required this.moshaf,
    required this.from,
    this.to,
    this.seekTo,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final AyahReference from;
  final AyahReference? to;
  final Duration? seekTo;
}

/// Pause the audio engine.
final class PauseAudio extends RecitationEffect {
  /// Creates [PauseAudio].
  const PauseAudio();
}

/// Release the recitation audio lease so alerts can acquire the player.
final class ReleaseAudioLease extends RecitationEffect {
  /// Creates [ReleaseAudioLease].
  const ReleaseAudioLease();
}

/// Resume the audio engine.
final class ResumeAudio extends RecitationEffect {
  /// Creates [ResumeAudio].
  const ResumeAudio();
}

/// Stop the audio engine.
final class StopAudio extends RecitationEffect {
  /// Creates [StopAudio].
  const StopAudio();
}

/// Seek the audio engine.
final class SeekAudio extends RecitationEffect {
  /// Creates [SeekAudio].
  const SeekAudio(this.position);

  final Duration position;
}

/// Highlight an ayah in the mushaf.
final class HighlightAyah extends RecitationEffect {
  /// Creates [HighlightAyah].
  const HighlightAyah({required this.surah, required this.ayah});

  final int surah;
  final int ayah;
}

/// Set native A-B loop markers for a single ayah without reloading audio.
/// Emitted in each-ayah repeat mode when advancing to the next ayah.
final class LoadAyahLoop extends RecitationEffect {
  /// Creates [LoadAyahLoop].
  const LoadAyahLoop({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    required this.ayah,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int surah;
  final int ayah;
}

/// Cancel any armed sleep timer (emitted on new play so a stale countdown
/// from a previous session does not fire mid-playback).
final class CancelSleepTimer extends RecitationEffect {
  /// Creates [CancelSleepTimer].
  const CancelSleepTimer();
}

/// Persist the current playback state for session restore.
final class PersistPlaybackState extends RecitationEffect {
  /// Creates [PersistPlaybackState].
  const PersistPlaybackState({
    this.surah,
    this.rangeStart,
    this.rangeEnd,
    this.rangeFromSurah,
    this.rangeFromAyah,
    this.rangeToSurah,
    this.rangeToAyah,
  });

  final int? surah;
  final int? rangeStart;
  final int? rangeEnd;
  final int? rangeFromSurah;
  final int? rangeFromAyah;
  final int? rangeToSurah;
  final int? rangeToAyah;
}

/// Load the current and next surah as a gapless playlist so the following
/// surah plays without reloading.
final class LoadGaplessContinuation extends RecitationEffect {
  /// Creates [LoadGaplessContinuation].
  const LoadGaplessContinuation({
    required this.reciter,
    required this.moshaf,
    required this.fromSurah,
    required this.toSurah,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int fromSurah;
  final int toSurah;
}

// ---------------------------------------------------------------------------
// Transition implementations
// ---------------------------------------------------------------------------

RecitationTransition _playSurah(
  RecitationState state,
  PlaySurah event, {
  required RecitationTimeline timeline,
  required int ayahRepeatCount,
  required int rangeRepeatCount,
}) {
  final firstAyah = ayahRepeatCount > 1 ? 1 : null;
  final next = state.copyWith(
    reciter: event.reciter,
    moshaf: event.moshaf,
    surah: event.surah,
    rangeFrom: null,
    rangeTo: null,
    currentAyah: firstAyah,
    position: event.resumeFrom ?? Duration.zero,
    duration: Duration.zero,
    status: RecitationStatus.loading,
    error: null,
    active: true,
    sleep: RecitationSleep.off,
    repeatsRemaining: rangeRepeatCount,
    ayahRepeatsRemaining: ayahRepeatCount,
    ayahRepeatCount: ayahRepeatCount,
    ayahLoopExiting: false,
  );
  return (
    state: next,
    effects: [
      const CancelSleepTimer(),
      LoadSurah(
        reciter: event.reciter,
        moshaf: event.moshaf,
        surah: event.surah,
        seekTo: event.resumeFrom,
      ),
    ],
  );
}

RecitationTransition _playRange(
  RecitationState state,
  PlayRange event, {
  required RecitationTimeline timeline,
  required int ayahRepeatCount,
  required int rangeRepeatCount,
}) {
  final segStart = event.from.ayah;
  final segEnd = event.to?.ayah;
  final globalFrom = event.globalFrom ?? event.from;
  final globalTo = event.globalTo ?? event.to;

  final next = state.copyWith(
    reciter: event.reciter,
    moshaf: event.moshaf,
    surah: event.from.surah,
    rangeFrom: globalFrom,
    rangeTo: globalTo,
    segmentStartAyah: segStart,
    segmentEndAyah: segEnd,
    currentAyah: segStart,
    position: event.resumeFrom ?? Duration.zero,
    duration: Duration.zero,
    status: RecitationStatus.loading,
    error: null,
    active: true,
    sleep: RecitationSleep.off,
    repeatsRemaining: rangeRepeatCount,
    ayahRepeatsRemaining: ayahRepeatCount,
    ayahRepeatCount: ayahRepeatCount,
    ayahLoopExiting: false,
  );

  return (
    state: next,
    effects: [
      const CancelSleepTimer(),
      LoadRange(
        reciter: event.reciter,
        moshaf: event.moshaf,
        from: event.from,
        to: event.to,
        seekTo: event.resumeFrom,
      ),
      PersistPlaybackState(
        surah: event.from.surah,
        rangeStart: segStart,
        rangeEnd: segEnd,
        rangeFromSurah: globalFrom.surah,
        rangeFromAyah: globalFrom.ayah,
        rangeToSurah: globalTo?.surah,
        rangeToAyah: globalTo?.ayah,
      ),
    ],
  );
}

RecitationTransition _togglePlayPause(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  if (state.isLoading) return (state: state, effects: const []);

  if (state.isPlaying) {
    return (state: state, effects: const [PauseAudio()]);
  }

  if (state.isPaused) {
    final atEnd = state.position >= state.duration - const Duration(milliseconds: 500) &&
        state.duration > Duration.zero;
    if (atEnd) {
      return (
        state: state.copyWith(position: timeline.rangeStart),
        effects: [SeekAudio(timeline.rangeStart), const ResumeAudio()],
      );
    }
    return (state: state, effects: const [ResumeAudio()]);
  }

  // Idle/error: re-load the current selection.
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  if (state.isRange && state.currentSegmentRefs != null) {
    return _playRange(
      state,
      _playRangeFromState(state, reciter: reciter, moshaf: moshaf),
      timeline: timeline,
      ayahRepeatCount: state.ayahRepeatCount.clamp(1, 99),
      rangeRepeatCount: state.repeatsRemaining.clamp(1, 99),
    );
  }

  return _playSurah(
    state,
    PlaySurah(reciter: reciter, moshaf: moshaf, surah: surah),
    timeline: timeline,
    ayahRepeatCount: state.ayahRepeatCount.clamp(1, 99),
    rangeRepeatCount: state.repeatsRemaining.clamp(1, 99),
  );
}

RecitationTransition _seek(
  RecitationState state,
  Seek event, {
  required RecitationTimeline timeline,
}) {
  final clamped = timeline.clampToRange(event.position);
  return (
    state: state.copyWith(position: clamped),
    effects: [SeekAudio(clamped)],
  );
}

RecitationTransition _stop(RecitationState state) {
  return (
    state: state.copyWith(
      status: RecitationStatus.idle,
      position: Duration.zero,
      currentAyah: null,
      error: null,
      active: true,
      sleep: RecitationSleep.off,
      userStopped: true,
    ),
    effects: const [StopAudio()],
  );
}

RecitationTransition _skipNext(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  // Within a range: advance to the next ayah if not past the segment end.
  if (state.isRange && state.currentAyah != null) {
    final endAyah = state.currentSegment?.endAyah;
    if (endAyah != null) {
      final nextAyah = state.currentAyah! + 1;
      if (nextAyah <= endAyah) {
        final start = timeline.startOfAyah(nextAyah);
        if (start != null) {
          return (
            state: state.copyWith(currentAyah: nextAyah, position: start),
            effects: [SeekAudio(start)],
          );
        }
      }
    }
  }

  // Otherwise: jump to the next available surah the moshaf has.
  var nextSurah = surah + 1;
  while (nextSurah <= 114 && !moshaf.hasSurah(nextSurah)) {
    nextSurah++;
  }
  if (nextSurah > 114 || !moshaf.hasSurah(nextSurah)) {
    return (state: state, effects: const []);
  }
  return _playSurah(
    state,
    PlaySurah(reciter: reciter, moshaf: moshaf, surah: nextSurah),
    timeline: timeline,
    ayahRepeatCount: state.ayahRepeatCount.clamp(1, 99),
    rangeRepeatCount: state.repeatsRemaining.clamp(1, 99),
  );
}

RecitationTransition _skipPrevious(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  // Within a range: go back to the previous ayah if not before the segment
  // start.
  if (state.isRange && state.currentAyah != null) {
    final startAyah = state.currentSegment?.startAyah;
    if (startAyah != null) {
      final prevAyah = state.currentAyah! - 1;
      if (prevAyah >= startAyah) {
        final start = timeline.startOfAyah(prevAyah);
        if (start != null) {
          return (
            state: state.copyWith(currentAyah: prevAyah, position: start),
            effects: [SeekAudio(start)],
          );
        }
      }
    }
  }

  // Otherwise: jump to the previous available surah the moshaf has.
  var prevSurah = surah - 1;
  while (prevSurah >= 1 && !moshaf.hasSurah(prevSurah)) {
    prevSurah--;
  }
  if (prevSurah < 1 || !moshaf.hasSurah(prevSurah)) {
    return (state: state, effects: const []);
  }
  return _playSurah(
    state,
    PlaySurah(reciter: reciter, moshaf: moshaf, surah: prevSurah),
    timeline: timeline,
    ayahRepeatCount: state.ayahRepeatCount.clamp(1, 99),
    rangeRepeatCount: state.repeatsRemaining.clamp(1, 99),
  );
}

RecitationTransition _setSleep(RecitationState state, SetSleep event) {
  return (state: state.copyWith(sleep: event.sleep), effects: const []);
}

RecitationTransition _onAudioPosition(
  RecitationState state,
  AudioPosition event, {
  required RecitationTimeline timeline,
}) {
  final effects = <RecitationEffect>[];

  if (state.isPlaying) {
    // Sleep boundary is evaluated against the ayah that was current when the
    // user armed the timer, before we roll over to the next ayah.
    final sleepBoundary = _sleepBoundary(state, timeline: timeline);
    if (sleepBoundary != null && event.position >= sleepBoundary) {
      return (
        state: state.copyWith(
          status: RecitationStatus.paused,
          position: event.position,
          currentAyah: null,
        ),
        effects: const [PauseAudio()],
      );
    }

    // Whole range/surah boundary (skipped while per-ayah A-B loop is active).
    if (state.ayahRepeatCount <= 1) {
      final endBoundary = timeline.rangeEnd;
      if (event.position >= endBoundary && state.duration > Duration.zero) {
        return _handleSelectionEnd(
          state.copyWith(position: event.position),
          timeline: timeline,
        );
      }
    }

    // Final repetition of the current ayah finished — advance to the next.
    if (state.ayahLoopExiting && state.currentAyah != null) {
      final ayahEnd = timeline.endOfAyah(state.currentAyah!);
      if (ayahEnd != null && event.position >= ayahEnd) {
        return _advanceAfterAyahLoop(
          state.copyWith(position: event.position),
          timeline: timeline,
        );
      }
    }
  }

  // Per-ayah repeat: pin currentAyah so position ticks never regress the
  // highlight while mpv loops or overshoots past B.
  if (state.ayahRepeatCount > 1) {
    return (
      state: state.copyWith(position: event.position),
      effects: effects,
    );
  }

  // Normal tick: update current ayah and highlight if it changed.
  final currentAyah = timeline.ayahAt(event.position);
  final next = state.copyWith(
    position: event.position,
    currentAyah: currentAyah,
  );

  if (currentAyah != null && currentAyah != state.currentAyah) {
    final surah = state.surah;
    if (surah != null) {
      effects.add(HighlightAyah(surah: surah, ayah: currentAyah));
    }
  }

  return (state: next, effects: effects);
}

Duration? _sleepBoundary(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  return switch (state.sleep) {
    RecitationSleep.off => null,
    RecitationSleep.endOfAyah => state.currentAyah == null
        ? null
        : timeline.endOfAyah(state.currentAyah!),
    RecitationSleep.endOfRange => timeline.rangeEnd,
    RecitationSleep.endOfSurah => state.duration > Duration.zero
        ? state.duration
        : null,
    _ => null,
  };
}

RecitationTransition _onAudioDuration(
  RecitationState state,
  AudioDuration event,
) {
  final timingMs = state.duration.inMilliseconds;
  final candidateMs = timingMs > 0 && event.duration.inMilliseconds < timingMs
      ? timingMs
      : event.duration.inMilliseconds;
  return (
    state: state.copyWith(duration: Duration(milliseconds: candidateMs)),
    effects: const [],
  );
}

RecitationTransition _onAudioStarted(RecitationState state) {
  return (
    state: state.copyWith(status: RecitationStatus.playing),
    effects: const [],
  );
}

RecitationTransition _onAudioLoading(RecitationState state) {
  return (
    state: state.copyWith(status: RecitationStatus.loading),
    effects: const [],
  );
}

RecitationTransition _onAudioPaused(RecitationState state) {
  return (
    state: state.copyWith(status: RecitationStatus.paused),
    effects: const [],
  );
}

RecitationTransition _onAudioBuffering(RecitationState state) {
  return (
    state: state.copyWith(status: RecitationStatus.buffering),
    effects: const [],
  );
}

RecitationTransition _onGaplessTrackAdvanced(
  RecitationState state,
  GaplessTrackAdvanced event,
) {
  return (
    state: state.copyWith(
      surah: event.surah,
      currentAyah: event.ayah,
      position: Duration.zero,
      duration: Duration.zero,
      status: RecitationStatus.playing,
      active: true,
    ),
    effects: const [],
  );
}

RecitationTransition _onAudioError(
  RecitationState state,
  AudioError event,
) {
  return (
    state: state.copyWith(
      status: RecitationStatus.error,
      error: event.message,
      currentAyah: null,
    ),
    effects: const [],
  );
}

RecitationTransition _onAudioAbLoopExhausted(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  if (state.ayahRepeatCount <= 1) {
    return (state: state, effects: const []);
  }
  if (state.ayahLoopExiting) {
    return (state: state, effects: const []);
  }
  return (
    state: state.copyWith(ayahLoopExiting: true),
    effects: const [],
  );
}

RecitationTransition _advanceAfterAyahLoop(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  final currentAyah = state.currentAyah;
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (currentAyah == null || reciter == null || moshaf == null ||
      surah == null) {
    return (state: state, effects: const []);
  }

  final nextAyah = currentAyah + 1;
  final endAyah = state.currentSegment?.endAyah;
  final hasNext = endAyah != null
      ? nextAyah <= endAyah && timeline.startOfAyah(nextAyah) != null
      : timeline.startOfAyah(nextAyah) != null &&
            timeline.endOfAyah(nextAyah) != null;

  if (!hasNext) {
    return _handleSelectionEnd(
      state.copyWith(ayahLoopExiting: false),
      timeline: timeline,
    );
  }

  final nextStart = timeline.startOfAyah(nextAyah);
  if (nextStart == null) {
    return (state: state, effects: const []);
  }

  return (
    state: state.copyWith(
      currentAyah: nextAyah,
      ayahRepeatsRemaining: state.ayahRepeatCount,
      ayahLoopExiting: false,
      position: nextStart,
    ),
    effects: [
      SeekAudio(nextStart),
      LoadAyahLoop(
        reciter: reciter,
        moshaf: moshaf,
        surah: surah,
        ayah: nextAyah,
      ),
      HighlightAyah(surah: surah, ayah: nextAyah),
    ],
  );
}

RecitationTransition _handleSelectionEnd(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  if (state.repeatsRemaining > 1) {
    return _repeatSelection(state, timeline: timeline);
  }

  // Whole-surah presets that start at ayah 1 are untimed-compatible.
  final isWholeSurahOrFromAyah1 =
      state.isWholeSurah || (state.rangeFrom?.ayah == 1);

  if (isWholeSurahOrFromAyah1) {
    // No continuation for whole-surah presets.
    return (
      state: state.copyWith(
        status: RecitationStatus.paused,
        position: timeline.rangeEnd,
        currentAyah: null,
      ),
      effects: const [PauseAudio()],
    );
  }

  // continueFromHere with from.ayah > 1 — try next surah if possible.
  final nextSurah = (state.surah ?? 0) + 1;
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  if (reciter == null ||
      moshaf == null ||
      nextSurah < 1 ||
      nextSurah > 114 ||
      !moshaf.hasSurah(nextSurah)) {
    return (
      state: state.copyWith(
        status: RecitationStatus.error,
        error: 'No next surah available',
        currentAyah: null,
      ),
      effects: const [],
    );
  }

  return (
    state: state.copyWith(
      surah: nextSurah,
      rangeFrom: null,
      rangeTo: null,
      currentAyah: null,
      position: Duration.zero,
      status: RecitationStatus.loading,
      repeatsRemaining: state.repeatsRemaining,
      ayahRepeatsRemaining: state.repeatsRemaining,
    ),
    effects: [
      LoadGaplessContinuation(
        reciter: reciter,
        moshaf: moshaf,
        fromSurah: state.surah ?? nextSurah,
        toSurah: nextSurah,
      ),
    ],
  );
}

RecitationTransition _repeatSelection(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  final start = timeline.rangeStart;
  final firstAyah = state.currentSegment?.startAyah;
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  final next = state.copyWith(
    repeatsRemaining: state.repeatsRemaining - 1,
    ayahRepeatsRemaining: state.repeatsRemaining - 1,
    position: start,
    currentAyah: firstAyah,
    status: RecitationStatus.loading,
    ayahLoopExiting: false,
  );

  if (state.isRange && state.currentSegmentRefs != null) {
    final seg = state.currentSegmentRefs!;
    return (
      state: next,
      effects: [
        LoadRange(
          reciter: reciter,
          moshaf: moshaf,
          from: seg.from,
          to: seg.to,
          seekTo: start,
        ),
      ],
    );
  }

  return (
    state: next,
    effects: [
      LoadSurah(
        reciter: reciter,
        moshaf: moshaf,
        surah: surah,
        seekTo: start,
      ),
    ],
  );
}

RecitationTransition _onAudioCompleted(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  return _handleSelectionEnd(state, timeline: timeline);
}

RecitationTransition _alertSuspend(RecitationState state) {
  if (!state.isPlaying && !state.isPaused) {
    return (state: state, effects: const []);
  }
  return (
    state: state.copyWith(
      status: RecitationStatus.paused,
      suspendedSnapshot: state.copyWith(),
    ),
    effects: const [PauseAudio(), ReleaseAudioLease()],
  );
}

RecitationTransition _alertResume(RecitationState state) {
  final snapshot = state.suspendedSnapshot;
  if (snapshot == null) return (state: state, effects: const []);

  final effects = <RecitationEffect>[];
  if (snapshot.isPlaying &&
      snapshot.reciter != null &&
      snapshot.moshaf != null &&
      snapshot.surah != null) {
    if (snapshot.isRange && snapshot.currentSegmentRefs != null) {
      final seg = snapshot.currentSegmentRefs!;
      effects.add(
        LoadRange(
          reciter: snapshot.reciter!,
          moshaf: snapshot.moshaf!,
          from: seg.from,
          to: seg.to,
          seekTo: snapshot.position,
        ),
      );
    } else {
      effects.add(
        LoadSurah(
          reciter: snapshot.reciter!,
          moshaf: snapshot.moshaf!,
          surah: snapshot.surah!,
          seekTo: snapshot.position,
        ),
      );
    }
  }

  return (
    state: snapshot.copyWith(suspendedSnapshot: null),
    effects: effects,
  );
}

RecitationTransition _setRepeatCounts(
  RecitationState state,
  SetRepeatCounts event,
) {
  final ayah = event.ayahRepeatCount?.clamp(1, 99);
  final range = event.rangeRepeatCount?.clamp(1, 99);
  return (
    state: state.copyWith(
      ayahRepeatCount: ayah ?? state.ayahRepeatCount,
      repeatsRemaining: range ?? state.repeatsRemaining,
      ayahRepeatsRemaining: ayah ?? state.ayahRepeatsRemaining,
    ),
    effects: const [],
  );
}

RecitationTransition _settingsLoaded(
  RecitationState state,
  RecitationSettingsLoaded event,
) {
  return (
    state: state.copyWith(
      reciter: event.reciter,
      moshaf: event.moshaf,
      surah: event.surah,
      rangeFrom: event.rangeFrom,
      rangeTo: event.rangeTo,
      active: true,
      error: null,
    ),
    effects: const [],
  );
}
