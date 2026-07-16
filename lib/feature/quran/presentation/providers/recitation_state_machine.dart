import 'dart:math' show max;

import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
// The event/effect classes are self-describing and the file has many long
// switch signatures, so suppress documentation and line-length lints.
// ignore_for_file: public_member_api_docs

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
  bool trackLoaded = false,
  bool? nativePlayWhenReady,
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
      return _togglePlayPause(
        state,
        timeline: timeline,
        ayahRepeatCount: ayahCount,
        rangeRepeatCount: rangeCount,
        trackLoaded: trackLoaded,
        nativePlayWhenReady: nativePlayWhenReady,
      );
    case Seek():
      return _seek(state, event, timeline: timeline);
    case Stop():
      return _stop(state);
    case SkipAyahNext():
      return _skipAyahNext(state, timeline: timeline);
    case SkipAyahPrevious():
      return _skipAyahPrevious(state, timeline: timeline);
    case SkipSurahNext():
      return _skipSurahNext(
        state,
        timeline: timeline,
        ayahRepeatCount: ayahCount,
        rangeRepeatCount: rangeCount,
      );
    case SkipSurahPrevious():
      return _skipSurahPrevious(
        state,
        timeline: timeline,
        ayahRepeatCount: ayahCount,
        rangeRepeatCount: rangeCount,
      );
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
    case PendingSeekTimeout():
      return _onPendingSeekTimeout(state, event);
    case SeekFailed():
      return _onSeekFailed(state, event);
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

/// Clears a stale [RecitationState.pendingSeekTarget] when mpv never lands
/// near the requested position.
final class PendingSeekTimeout extends RecitationEvent {
  /// Creates [PendingSeekTimeout].
  const PendingSeekTimeout({this.revertTo});

  /// Last confirmed mpv position to restore when the seek never lands.
  final Duration? revertTo;
}

/// Seek did not land in mpv — revert optimistic UI state.
final class SeekFailed extends RecitationEvent {
  /// Creates [SeekFailed].
  const SeekFailed({required this.revertTo});

  /// Last confirmed mpv position before the failed seek.
  final Duration revertTo;
}

/// Stop playback but keep the session visible.
final class Stop extends RecitationEvent {
  /// Creates [Stop].
  const Stop();
}

/// Advance to the next ayah within the current surah/range.
final class SkipAyahNext extends RecitationEvent {
  /// Creates [SkipAyahNext].
  const SkipAyahNext();
}

/// Go back to the previous ayah within the current surah/range.
final class SkipAyahPrevious extends RecitationEvent {
  /// Creates [SkipAyahPrevious].
  const SkipAyahPrevious();
}

/// Load the next available surah in the moshaf.
final class SkipSurahNext extends RecitationEvent {
  /// Creates [SkipSurahNext].
  const SkipSurahNext();
}

/// Load the previous available surah in the moshaf.
final class SkipSurahPrevious extends RecitationEvent {
  /// Creates [SkipSurahPrevious].
  const SkipSurahPrevious();
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
    this.resumeFrom,
  });

  final Reciter? reciter;
  final Moshaf? moshaf;
  final int? surah;
  final AyahReference? rangeFrom;
  final AyahReference? rangeTo;
  final Duration? resumeFrom;
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
    this.positionMs,
  });

  final int? surah;
  final int? rangeStart;
  final int? rangeEnd;
  final int? rangeFromSurah;
  final int? rangeFromAyah;
  final int? rangeToSurah;
  final int? rangeToAyah;
  final int? positionMs;
}

/// Clears the saved playback position without touching surah/range metadata.
final class ClearPlaybackPosition extends RecitationEffect {
  /// Creates [ClearPlaybackPosition].
  const ClearPlaybackPosition();
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

/// Load the next surah-local segment in a global multi-surah range.
final class LoadNextRangeSegment extends RecitationEffect {
  /// Creates [LoadNextRangeSegment].
  const LoadNextRangeSegment({
    required this.reciter,
    required this.moshaf,
    required this.globalFrom,
    required this.globalTo,
    required this.currentSurah,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final AyahReference globalFrom;
  final AyahReference globalTo;
  final int currentSurah;
}

/// Native mpv repeat mode applied via [SetNativeLoop].
enum NativeLoopMode {
  /// No native file/playlist looping.
  off,

  /// Loop the current file (native mpv file loop).
  file,
}

/// Sets native mpv repeat mode.
final class SetNativeLoop extends RecitationEffect {
  /// Creates [SetNativeLoop].
  const SetNativeLoop(this.mode);

  final NativeLoopMode mode;
}

/// Clears armed A-B loop markers without reloading audio.
final class ClearNativeAbLoop extends RecitationEffect {
  /// Creates [ClearNativeAbLoop].
  const ClearNativeAbLoop();
}

/// Resets native loop/gapless/prefetch to safe defaults.
final class ResetNativePlaybackModes extends RecitationEffect {
  /// Creates [ResetNativePlaybackModes].
  const ResetNativePlaybackModes();
}

/// Pauses at EOF while keeping the loaded track and media session intact.
final class PauseAtEof extends RecitationEffect {
  /// Creates [PauseAtEof].
  const PauseAtEof();
}

/// Refreshes native A-B loop after a mid-playback repeat-count change.
final class RefreshAbLoop extends RecitationEffect {
  /// Creates [RefreshAbLoop].
  const RefreshAbLoop({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    required this.ayah,
    required this.repeatCount,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int surah;
  final int ayah;
  final int repeatCount;
}

// ---------------------------------------------------------------------------
// Native loop helpers
// ---------------------------------------------------------------------------

bool _eligibleForNativeFileLoop(RecitationState state) {
  return state.isWholeSurah && state.ayahRepeatCount <= 1;
}

bool _shouldUseNativeFileLoop(RecitationState state) {
  return _eligibleForNativeFileLoop(state) && state.repeatsRemaining > 1;
}

List<RecitationEffect> _nativeLoopEffectsForSession(
  RecitationState state, {
  int? ayah,
  bool resetModes = true,
  bool clearAbLoop = true,
}) {
  final effects = <RecitationEffect>[];
  if (resetModes) {
    effects.add(const ResetNativePlaybackModes());
  }
  if (clearAbLoop) {
    effects.add(const ClearNativeAbLoop());
  }
  if (_shouldUseNativeFileLoop(state)) {
    effects.add(const SetNativeLoop(NativeLoopMode.file));
  } else {
    effects.add(const SetNativeLoop(NativeLoopMode.off));
  }
  final loopAyah = ayah ?? state.currentAyah ?? state.currentSegment?.startAyah;
  if (state.ayahRepeatCount > 1 &&
      loopAyah != null &&
      state.reciter != null &&
      state.moshaf != null &&
      state.surah != null) {
    effects.add(
      LoadAyahLoop(
        reciter: state.reciter!,
        moshaf: state.moshaf!,
        surah: state.surah!,
        ayah: loopAyah,
      ),
    );
  }
  return effects;
}

List<RecitationEffect> _terminalEndedEffects() {
  return const [
    SetNativeLoop(NativeLoopMode.off),
    PauseAtEof(),
  ];
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
    userStopped: false,
    pendingSeekTarget: null,
  );
  return (
    state: next,
    effects: [
      const CancelSleepTimer(),
      ..._nativeLoopEffectsForSession(next, ayah: firstAyah),
      LoadSurah(
        reciter: event.reciter,
        moshaf: event.moshaf,
        surah: event.surah,
        seekTo: event.resumeFrom,
      ),
      PersistPlaybackState(surah: event.surah),
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
    userStopped: false,
    pendingSeekTarget: null,
  );

  return (
    state: next,
    effects: [
      const CancelSleepTimer(),
      ..._nativeLoopEffectsForSession(next, ayah: segStart),
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

// ---------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------

const _pendingSeekToleranceMs = 500;

bool _positionNearTarget(Duration position, Duration target) {
  return (position.inMilliseconds - target.inMilliseconds).abs() <=
      _pendingSeekToleranceMs;
}

int? _currentAyahOrGuess(
  RecitationState state,
  RecitationTimeline timeline,
) {
  return state.currentAyah ?? timeline.ayahAt(state.position);
}

int _firstPlayableAyah(RecitationState state) {
  return state.currentSegment?.startAyah ?? 1;
}

int? _lastPlayableAyah(
  RecitationState state,
  RecitationTimeline timeline,
) {
  final segEnd = state.currentSegment?.endAyah;
  if (segEnd != null) return segEnd;
  final ayat = timeline.timing?.ayat.where((a) => a.ayah > 0).toList();
  return ayat?.lastOrNull?.ayah;
}

RecitationTransition _navigateToAyah(
  RecitationState state, {
  required int targetAyah,
  required RecitationTimeline timeline,
}) {
  final startRaw = timeline.startOfAyah(targetAyah);
  if (startRaw == null) {
    return (state: state, effects: const []);
  }

  final start = timeline.clampToRange(startRaw);
  final surah = state.surah;
  final reciter = state.reciter;
  final moshaf = state.moshaf;

  var next = state.copyWith(
    position: start,
    currentAyah: targetAyah,
    ayahLoopExiting: false,
    pendingSeekTarget: start,
    ayahRepeatsRemaining: state.ayahRepeatCount > 1
        ? state.ayahRepeatCount
        : state.ayahRepeatsRemaining,
  );

  if (state.isEnded) {
    next = next.copyWith(
      status: start > Duration.zero
          ? RecitationStatus.paused
          : RecitationStatus.ended,
    );
  }

  final effects = <RecitationEffect>[SeekAudio(start)];
  if (state.ayahRepeatCount > 1 &&
      reciter != null &&
      moshaf != null &&
      surah != null) {
    effects.add(
      LoadAyahLoop(
        reciter: reciter,
        moshaf: moshaf,
        surah: surah,
        ayah: targetAyah,
      ),
    );
  }
  if (surah != null) {
    effects.add(HighlightAyah(surah: surah, ayah: targetAyah));
  }

  return (state: next, effects: effects);
}

RecitationTransition _togglePlayPause(
  RecitationState state, {
  required RecitationTimeline timeline,
  required int ayahRepeatCount,
  required int rangeRepeatCount,
  bool trackLoaded = false,
  bool? nativePlayWhenReady,
}) {
  if (state.isEnded) {
    return _replaySelection(
      state,
      timeline: timeline,
      ayahRepeatCount: ayahRepeatCount,
      rangeRepeatCount: rangeRepeatCount,
    );
  }

  // Track loaded in mpv: follow native playWhenReady (never unload+reload).
  if (trackLoaded && nativePlayWhenReady != null) {
    if (nativePlayWhenReady) {
      return (state: state, effects: const [PauseAudio()]);
    }
    final atEnd =
        state.position >= state.duration - const Duration(milliseconds: 500) &&
            state.duration > Duration.zero;
    if (atEnd) {
      return (
        state: state.copyWith(position: timeline.rangeStart),
        effects: [SeekAudio(timeline.rangeStart), const ResumeAudio()],
      );
    }
    return (state: state, effects: const [ResumeAudio()]);
  }

  if (state.isLoading) return (state: state, effects: const []);

  if (state.userStopped) {
    return _replaySelection(
      state,
      timeline: timeline,
      ayahRepeatCount: ayahRepeatCount,
      rangeRepeatCount: rangeRepeatCount,
    );
  }

  if (state.isPlaying) {
    return (state: state, effects: const [PauseAudio()]);
  }

  if (state.isPaused) {
    final atEnd =
        state.position >= state.duration - const Duration(milliseconds: 500) &&
            state.duration > Duration.zero;
    if (atEnd) {
      return (
        state: state.copyWith(position: timeline.rangeStart),
        effects: [SeekAudio(timeline.rangeStart), const ResumeAudio()],
      );
    }
    return (state: state, effects: const [ResumeAudio()]);
  }

  // Idle/error with no loaded track: start playback.
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  final resumeFrom =
      state.position > Duration.zero ? state.position : null;

  if (state.isRange && state.currentSegmentRefs != null) {
    return _playRange(
      state,
      _playRangeFromState(
        state,
        reciter: reciter,
        moshaf: moshaf,
        resumeFrom: resumeFrom,
      ),
      timeline: timeline,
      ayahRepeatCount: ayahRepeatCount,
      rangeRepeatCount: rangeRepeatCount,
    );
  }

  return _playSurah(
    state,
    PlaySurah(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      resumeFrom: resumeFrom,
    ),
    timeline: timeline,
    ayahRepeatCount: ayahRepeatCount,
    rangeRepeatCount: rangeRepeatCount,
  );
}

RecitationTransition _replaySelection(
  RecitationState state, {
  required RecitationTimeline timeline,
  required int ayahRepeatCount,
  required int rangeRepeatCount,
}) {
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
      ayahRepeatCount: ayahRepeatCount,
      rangeRepeatCount: rangeRepeatCount,
    );
  }

  return _playSurah(
    state,
    PlaySurah(reciter: reciter, moshaf: moshaf, surah: surah),
    timeline: timeline,
    ayahRepeatCount: ayahRepeatCount,
    rangeRepeatCount: rangeRepeatCount,
  );
}

RecitationTransition _seek(
  RecitationState state,
  Seek event, {
  required RecitationTimeline timeline,
}) {
  if (state.isLoading || state.timelinePending) {
    var next = state.copyWith(
      position: event.position,
      pendingSeekTarget: event.position,
    );
    if (state.isEnded) {
      next = next.copyWith(
        status: event.position > Duration.zero
            ? RecitationStatus.paused
            : RecitationStatus.ended,
      );
    }
    return (
      state: next,
      effects: [SeekAudio(event.position)],
    );
  }

  final clamped = timeline.clampToRange(event.position);
  final ayah = timeline.ayahAt(clamped);
  if (ayah != null && timeline.startOfAyah(ayah) != null) {
    return _navigateToAyah(state, targetAyah: ayah, timeline: timeline);
  }

  var next = state.copyWith(
    position: clamped,
    pendingSeekTarget: clamped,
  );
  if (state.isEnded) {
    next = next.copyWith(
      status: clamped > Duration.zero
          ? RecitationStatus.paused
          : RecitationStatus.ended,
    );
  }
  return (
    state: next,
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
      ayahLoopExiting: false,
      ayahRepeatsRemaining: state.ayahRepeatCount,
      pendingSeekTarget: null,
    ),
    effects: const [
      StopAudio(),
      ClearPlaybackPosition(),
      ResetNativePlaybackModes(),
      ClearNativeAbLoop(),
    ],
  );
}

RecitationTransition _skipAyahNext(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  final current = _currentAyahOrGuess(state, timeline);
  if (current == null) return (state: state, effects: const []);

  final last = _lastPlayableAyah(state, timeline);
  if (last == null || current >= last) {
    return (state: state, effects: const []);
  }

  return _navigateToAyah(
    state,
    targetAyah: current + 1,
    timeline: timeline,
  );
}

RecitationTransition _skipAyahPrevious(
  RecitationState state, {
  required RecitationTimeline timeline,
}) {
  final current = _currentAyahOrGuess(state, timeline);
  if (current == null) return (state: state, effects: const []);

  final first = _firstPlayableAyah(state);
  if (current <= first) return (state: state, effects: const []);

  return _navigateToAyah(
    state,
    targetAyah: current - 1,
    timeline: timeline,
  );
}

RecitationTransition _skipSurahNext(
  RecitationState state, {
  required RecitationTimeline timeline,
  required int ayahRepeatCount,
  required int rangeRepeatCount,
}) {
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  var nextSurah = surah + 1;
  while (nextSurah <= 114 && !moshaf.hasSurah(nextSurah)) {
    nextSurah++;
  }
  final rangeTo = state.rangeTo;
  if (rangeTo != null && nextSurah > rangeTo.surah) {
    return (state: state, effects: const []);
  }
  if (nextSurah > 114 || !moshaf.hasSurah(nextSurah)) {
    return (state: state, effects: const []);
  }
  return _playSurah(
    state,
    PlaySurah(reciter: reciter, moshaf: moshaf, surah: nextSurah),
    timeline: timeline,
    ayahRepeatCount: ayahRepeatCount,
    rangeRepeatCount: rangeRepeatCount,
  );
}

RecitationTransition _skipSurahPrevious(
  RecitationState state, {
  required RecitationTimeline timeline,
  required int ayahRepeatCount,
  required int rangeRepeatCount,
}) {
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  final surah = state.surah;
  if (reciter == null || moshaf == null || surah == null) {
    return (state: state, effects: const []);
  }

  var prevSurah = surah - 1;
  while (prevSurah >= 1 && !moshaf.hasSurah(prevSurah)) {
    prevSurah--;
  }
  final rangeFrom = state.rangeFrom;
  if (rangeFrom != null && prevSurah < rangeFrom.surah) {
    return (state: state, effects: const []);
  }
  if (prevSurah < 1 || !moshaf.hasSurah(prevSurah)) {
    return (state: state, effects: const []);
  }
  return _playSurah(
    state,
    PlaySurah(reciter: reciter, moshaf: moshaf, surah: prevSurah),
    timeline: timeline,
    ayahRepeatCount: ayahRepeatCount,
    rangeRepeatCount: rangeRepeatCount,
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
  if (state.userStopped || state.isIdle) {
    return (state: state, effects: const []);
  }

  final effects = <RecitationEffect>[];

  final pending = state.pendingSeekTarget;
  if (pending != null && !_positionNearTarget(event.position, pending)) {
    return (state: state, effects: effects);
  }
  if (pending != null) {
    state = state.copyWith(pendingSeekTarget: null);
  }

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

    // Range boundary only (whole surah ends via natural EOF).
    if (state.ayahRepeatCount <= 1 && state.isRange) {
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
  // highlight while mpv loops or overshoots past B. Detect loop wraps to
  // decrement [ayahRepeatsRemaining] for live UI repeat counters.
  if (state.ayahRepeatCount > 1) {
    var ayahRepeatsRemaining = state.ayahRepeatsRemaining;
    if (_detectAyahLoopWrap(state, event.position, timeline)) {
      ayahRepeatsRemaining = max(1, ayahRepeatsRemaining - 1);
    }
    return (
      state: state.copyWith(
        position: event.position,
        ayahRepeatsRemaining: ayahRepeatsRemaining,
      ),
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

/// True when mpv's A-B loop wrapped the current ayah (position jumped back).
bool _detectAyahLoopWrap(
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
      pendingSeekTarget: null,
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
      pendingSeekTarget: null,
    ),
    effects: const [],
  );
}

RecitationTransition _onPendingSeekTimeout(
  RecitationState state,
  PendingSeekTimeout event,
) {
  if (state.pendingSeekTarget == null) {
    return (state: state, effects: const []);
  }
  return (
    state: state.copyWith(
      pendingSeekTarget: null,
      position: event.revertTo ?? state.position,
    ),
    effects: const [],
  );
}

RecitationTransition _onSeekFailed(
  RecitationState state,
  SeekFailed event,
) {
  return (
    state: state.copyWith(
      pendingSeekTarget: null,
      position: event.revertTo,
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
    if (_shouldUseNativeFileLoop(state)) {
      return (
        state: state.copyWith(
          repeatsRemaining: state.repeatsRemaining - 1,
          ayahLoopExiting: false,
          pendingSeekTarget: null,
        ),
        effects: const [],
      );
    }
    return _repeatSelection(state, timeline: timeline);
  }

  final endedPosition =
      state.duration > Duration.zero ? state.duration : state.position;

  // Terminal: whole surah playback.
  if (state.isWholeSurah) {
    return (
      state: state.copyWith(
        status: RecitationStatus.ended,
        position: endedPosition,
        currentAyah: null,
        ayahLoopExiting: false,
        pendingSeekTarget: null,
      ),
      effects: _terminalEndedEffects(),
    );
  }

  // Bounded multi-surah range — advance to the next surah-local segment.
  final rangeFrom = state.rangeFrom;
  final rangeTo = state.rangeTo;
  final surah = state.surah;
  final reciter = state.reciter;
  final moshaf = state.moshaf;
  if (rangeFrom != null &&
      rangeTo != null &&
      surah != null &&
      reciter != null &&
      moshaf != null &&
      surah < rangeTo.surah) {
    final loading = state.copyWith(
      status: RecitationStatus.loading,
      currentAyah: null,
      position: Duration.zero,
      ayahLoopExiting: false,
      pendingSeekTarget: null,
    );
    return (
      state: loading,
      effects: [
        ..._nativeLoopEffectsForSession(loading),
        LoadNextRangeSegment(
          reciter: reciter,
          moshaf: moshaf,
          globalFrom: rangeFrom,
          globalTo: rangeTo,
          currentSurah: surah,
        ),
      ],
    );
  }

  // Terminal: bounded ayah range finished.
  if (state.isRange && rangeTo != null) {
    return (
      state: state.copyWith(
        status: RecitationStatus.ended,
        position: endedPosition,
        currentAyah: null,
        ayahLoopExiting: false,
        pendingSeekTarget: null,
      ),
      effects: _terminalEndedEffects(),
    );
  }

  // Open-ended continueFromHere — try next surah if possible.
  final nextSurah = (state.surah ?? 0) + 1;
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
        pendingSeekTarget: null,
      ),
      effects: const [],
    );
  }

  final gapless = state.copyWith(
    surah: nextSurah,
    rangeFrom: null,
    rangeTo: null,
    currentAyah: null,
    position: Duration.zero,
    status: RecitationStatus.loading,
    repeatsRemaining: state.repeatsRemaining,
    ayahRepeatsRemaining: state.ayahRepeatCount,
    pendingSeekTarget: null,
  );
  return (
    state: gapless,
    effects: [
      ..._nativeLoopEffectsForSession(gapless),
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
    ayahRepeatsRemaining: state.ayahRepeatCount,
    position: start,
    currentAyah: firstAyah,
    status: RecitationStatus.loading,
    ayahLoopExiting: false,
    pendingSeekTarget: null,
  );

  if (state.isRange && state.currentSegmentRefs != null) {
    final seg = state.currentSegmentRefs!;
    return (
      state: next,
      effects: [
        ..._nativeLoopEffectsForSession(next, ayah: firstAyah),
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
      ..._nativeLoopEffectsForSession(next, ayah: firstAyah),
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
  final next = state.copyWith(
    ayahRepeatCount: ayah ?? state.ayahRepeatCount,
    repeatsRemaining: range ?? state.repeatsRemaining,
    ayahRepeatsRemaining: ayah ?? state.ayahRepeatsRemaining,
  );

  final effects = <RecitationEffect>[];
  final activePlayback =
      next.isPlaying || next.isPaused || next.isBuffering || next.isLoading;
  if (activePlayback && next.reciter != null && next.moshaf != null) {
    effects.addAll(
      _nativeLoopEffectsForSession(
        next,
        ayah: next.currentAyah ?? next.currentSegment?.startAyah,
      ),
    );
    final loopAyah = next.currentAyah ?? next.currentSegment?.startAyah;
    if (next.ayahRepeatCount > 1 &&
        loopAyah != null &&
        next.surah != null &&
        ayah != null &&
        ayah != state.ayahRepeatCount) {
      effects.add(
        RefreshAbLoop(
          reciter: next.reciter!,
          moshaf: next.moshaf!,
          surah: next.surah!,
          ayah: loopAyah,
          repeatCount: next.ayahRepeatCount,
        ),
      );
    }
  }

  return (state: next, effects: effects);
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
      position: event.resumeFrom ?? Duration.zero,
      active: true,
      error: null,
    ),
    effects: const [],
  );
}
