import 'package:mushaf_reader/mushaf_reader.dart' show SurahTiming;
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_playback_policy.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_seek_pipeline.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_state_machine.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

/// Native playback lifecycle translated by the audio adapter.
enum RecitationNativeLifecycle {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Framework-independent native playback facts observed by a session.
class RecitationNativeSnapshot {
  const RecitationNativeSnapshot({
    required this.lifecycle,
    required this.position,
    required this.duration,
    required this.playIntent,
    this.remainingAbLoops,
    this.playlistIndex,
    this.error,
  });

  final RecitationNativeLifecycle lifecycle;
  final Duration position;
  final Duration duration;
  final bool playIntent;
  final int? remainingAbLoops;
  final int? playlistIndex;
  final String? error;
}

/// Result of one ordered logical session decision.
class RecitationSessionDecision {
  const RecitationSessionDecision({
    this.effects = const [],
    this.abandonsPendingSeek = false,
  });

  final List<RecitationEffect> effects;
  final bool abandonsPendingSeek;

  static const none = RecitationSessionDecision();
}

/// The single writer for logical Quran recitation state.
///
/// Riverpod, native audio, persistence, and Mushaf integrations are adapters.
/// They submit commands or observations here and project [state]; they never
/// reconcile or mutate logical session state themselves.
class RecitationSession {
  RecitationSession({
    required int Function(int surah) surahAyahCount,
    RecitationState initialState = const RecitationState(active: true),
    void Function(RecitationState state)? onStateChanged,
    void Function(String message)? log,
  }) : _surahAyahCount = surahAyahCount,
       _state = initialState,
       _onStateChanged = onStateChanged,
       _log = log;

  final int Function(int surah) _surahAyahCount;
  final void Function(RecitationState state)? _onStateChanged;
  final void Function(String message)? _log;

  RecitationState _state;
  RecitationTimeline _timeline = const RecitationTimeline();
  int _defaultAyahRepeatCount = 1;
  int _defaultRangeRepeatCount = 1;
  int? _lastAbLoopRemaining;
  int? _lastTrackIndex;
  Duration _lastAcceptedPosition = Duration.zero;

  RecitationState get state => _state;
  RecitationTimeline get timeline => _timeline;
  SurahTiming? get currentTiming => _timeline.timing;
  Duration get lastAcceptedPosition => _lastAcceptedPosition;
  int? get lastTrackIndex => _lastTrackIndex;

  bool get hasAyahTiming =>
      _state.moshaf?.hasTiming == true &&
      (_timeline.hasTiming || _state.isLoading || _state.timelinePending);

  void updateRepeatDefaults({int? ayahRepeatCount, int? rangeRepeatCount}) {
    if (ayahRepeatCount != null) {
      _defaultAyahRepeatCount = clampRepeatCount(ayahRepeatCount);
    }
    if (rangeRepeatCount != null) {
      _defaultRangeRepeatCount = clampRepeatCount(rangeRepeatCount);
    }
  }

  RecitationSessionDecision dispatch(
    RecitationEvent event, {
    bool trackLoaded = false,
    bool? nativePlayWhenReady,
  }) {
    final result = transition(
      _state,
      event,
      timeline: _timeline,
      defaultAyahRepeatCount: _defaultAyahRepeatCount,
      defaultRangeRepeatCount: _defaultRangeRepeatCount,
      trackLoaded: trackLoaded,
      nativePlayWhenReady: nativePlayWhenReady,
      surahAyahCount: _surahAyahCount,
    );
    _commit(result.state);
    return RecitationSessionDecision(
      effects: result.effects,
      abandonsPendingSeek: _abandonsPendingSeek(event),
    );
  }

  /// Applies native facts in a stable order and returns resulting effects.
  RecitationSessionDecision observeNative(
    RecitationNativeSnapshot? previous,
    RecitationNativeSnapshot next,
  ) {
    if (_state.suspendedSnapshot != null) {
      _lastAbLoopRemaining = next.remainingAbLoops;
      return RecitationSessionDecision.none;
    }

    final effects = <RecitationEffect>[];
    final first = previous == null;
    if (first || previous.position != next.position) {
      effects.addAll(_observePosition(next.position).effects);
    }
    if (first || previous.duration != next.duration) {
      _setReportedDuration(next.duration);
    }
    if (first || previous.playIntent != next.playIntent) {
      _observePlayIntent(next.playIntent, next.lifecycle);
    }
    if (first || previous.remainingAbLoops != next.remainingAbLoops) {
      effects.addAll(_observeAbLoops(next.remainingAbLoops).effects);
    }
    if (first || previous.playlistIndex != next.playlistIndex) {
      effects.addAll(_observePlaylistIndex(next.playlistIndex).effects);
    }
    if (!first && previous.lifecycle == next.lifecycle) {
      return RecitationSessionDecision(effects: effects);
    }

    switch (next.lifecycle) {
      case RecitationNativeLifecycle.loading:
        _setStatus(RecitationStatus.loading);
      case RecitationNativeLifecycle.buffering:
        _setStatus(RecitationStatus.buffering);
      case RecitationNativeLifecycle.playing:
        _setStatus(RecitationStatus.playing);
      case RecitationNativeLifecycle.paused:
        _setStatus(RecitationStatus.paused);
      case RecitationNativeLifecycle.completed:
        effects.addAll(_observeCompletion(authoritative: true).effects);
      case RecitationNativeLifecycle.error:
        setAudioError(next.error ?? 'Audio playback failed');
      case RecitationNativeLifecycle.idle:
        break;
    }
    return RecitationSessionDecision(
      effects: effects,
      abandonsPendingSeek: next.lifecycle == RecitationNativeLifecycle.error,
    );
  }

  RecitationSessionDecision observeNaturalCompletion() =>
      _observeCompletion(authoritative: false);

  void clearError() {
    if (_state.error != null) _commit(_state.copyWith(error: null));
  }

  void setSleep(RecitationSleep sleep) =>
      _commit(_state.copyWith(sleep: sleep));

  /// Invalidates older asynchronous load results and clears old timing.
  int beginLoad({required bool hasTiming}) {
    final generation = _state.loadGeneration + 1;
    _timeline = const RecitationTimeline();
    _commit(
      _state.copyWith(
        loadGeneration: generation,
        userStopped: false,
        timelinePending: hasTiming,
        status: RecitationStatus.loading,
      ),
    );
    _trace('load generation=$generation started');
    return generation;
  }

  /// Begins gapless preparation without forcing the visible loading status.
  int beginGaplessLoad({required bool hasTiming}) {
    final generation = _state.loadGeneration + 1;
    _commit(
      _state.copyWith(
        loadGeneration: generation,
        userStopped: false,
        timelinePending: hasTiming,
      ),
    );
    _trace('gapless generation=$generation started');
    return generation;
  }

  bool ownsGeneration(int generation) => generation == _state.loadGeneration;

  void installTimeline(RecitationTimeline timeline, {required int generation}) {
    if (!ownsGeneration(generation)) {
      _trace(
        'timeline discarded stale=$generation active=${_state.loadGeneration}',
      );
      return;
    }
    _timeline = timeline;
    var next = _state;
    if (next.timelinePending) next = next.copyWith(timelinePending: false);
    if (timeline.totalDuration > next.duration) {
      next = next.copyWith(duration: timeline.totalDuration);
    }
    _commit(next);
  }

  void replaceTimelineForTest(RecitationTimeline timeline) {
    _timeline = timeline;
  }

  void discardTimeline() {
    _timeline = const RecitationTimeline();
  }

  void setRangeEnded() {
    final endedPosition = _state.duration > Duration.zero
        ? _state.duration
        : _state.position;
    _commit(
      _state.copyWith(
        status: RecitationStatus.ended,
        position: endedPosition,
        currentAyah: null,
        ayahLoopExiting: false,
      ),
    );
  }

  void seedTrackIndex(int? index) => _lastTrackIndex = index;

  void resetAbLoopObservation() => _lastAbLoopRemaining = null;

  void setAudioError(String message) {
    _commit(
      _state.copyWith(
        status: RecitationStatus.error,
        error: message,
        currentAyah: null,
        pendingSeekTarget: null,
      ),
    );
  }

  Duration prepareSeek(Duration requested) {
    final target = _state.isLoading || _state.timelinePending
        ? requested
        : _timeline.clampToRange(requested);
    var next = _state.copyWith(position: target, pendingSeekTarget: target);
    if (_state.isEnded) {
      next = next.copyWith(
        status: target > Duration.zero
            ? RecitationStatus.paused
            : RecitationStatus.ended,
      );
    }
    _commit(next);
    return target;
  }

  ({Duration position, bool needsAbLoop})? prepareAyahNavigation(
    int targetAyah,
  ) {
    if (_state.suspendedSnapshot != null) return null;
    final raw = _timeline.startOfAyah(targetAyah);
    if (raw == null) return null;
    final start = _timeline.clampToRange(raw);
    final needsAbLoop =
        _state.ayahRepeatCount > 1 &&
        _state.reciter != null &&
        _state.moshaf != null &&
        _state.surah != null;
    var next = _state.copyWith(
      position: start,
      currentAyah: targetAyah,
      ayahLoopExiting: false,
      pendingSeekTarget: start,
      ayahRepeatsRemaining: _state.ayahRepeatCount > 1
          ? _state.ayahRepeatCount
          : _state.ayahRepeatsRemaining,
    );
    if (_state.isEnded) {
      next = next.copyWith(
        status: start > Duration.zero
            ? RecitationStatus.paused
            : RecitationStatus.ended,
      );
    }
    _commit(next);
    return (position: start, needsAbLoop: needsAbLoop);
  }

  bool revertPendingSeek(Duration revertTo, {Duration? onlyIfPendingEquals}) {
    final pending = _state.pendingSeekTarget;
    if (pending == null) return false;
    if (onlyIfPendingEquals != null &&
        !shouldRevertPendingSeek(
          currentPending: pending,
          failedTarget: onlyIfPendingEquals,
        )) {
      _trace(
        'seek revert discarded stale=${onlyIfPendingEquals.inMilliseconds} '
        'active=${pending.inMilliseconds}',
      );
      return false;
    }
    _commit(_state.copyWith(pendingSeekTarget: null, position: revertTo));
    return true;
  }

  RecitationSessionDecision _observePosition(Duration position) {
    if (_state.userStopped || _state.isIdle) {
      return RecitationSessionDecision.none;
    }
    final decision = dispatch(AudioPosition(position));
    if (_state.pendingSeekTarget == null) {
      _lastAcceptedPosition = _state.position;
    }
    return decision;
  }

  void _setReportedDuration(Duration duration) {
    final merged = mergeReportedDuration(
      current: _state.duration,
      reported: duration,
    );
    if (merged != _state.duration) _commit(_state.copyWith(duration: merged));
  }

  void _observePlayIntent(
    bool playIntent,
    RecitationNativeLifecycle lifecycle,
  ) {
    if (playIntent) {
      if (_state.userStopped || _state.isEnded) return;
      if (_state.isPlaying || _state.isBuffering) return;
      _setStatus(RecitationStatus.playing);
      return;
    }
    if (_state.userStopped || _state.isEnded || _state.isLoading) return;
    if (lifecycle == RecitationNativeLifecycle.completed) return;
    if (_state.isPlaying || _state.isBuffering) {
      _setStatus(RecitationStatus.paused);
    }
  }

  RecitationSessionDecision _observeAbLoops(int? remaining) {
    final previous = _lastAbLoopRemaining;
    _lastAbLoopRemaining = remaining;
    if (remaining == 0 && previous != null && previous > 0) {
      return dispatch(const AyahLoopExhausted());
    }
    return RecitationSessionDecision.none;
  }

  RecitationSessionDecision _observePlaylistIndex(int? index) {
    final previous = _lastTrackIndex;
    _lastTrackIndex = index;
    if (index == null || index < 1) return RecitationSessionDecision.none;
    if (previous != null && previous >= 1) {
      return RecitationSessionDecision.none;
    }
    final surah = _state.surah;
    if (surah == null || _state.rangeFrom != null) {
      return RecitationSessionDecision.none;
    }
    return dispatch(GaplessTrackAdvanced(surah: surah, ayah: 1));
  }

  RecitationSessionDecision _observeCompletion({required bool authoritative}) {
    if (authoritative) {
      if (!_state.active ||
          _state.userStopped ||
          _state.timelinePending ||
          _state.isEnded) {
        return RecitationSessionDecision.none;
      }
    } else if (!_shouldDispatchCompletion) {
      return RecitationSessionDecision.none;
    }
    return dispatch(const AudioCompleted());
  }

  bool get _shouldDispatchCompletion =>
      _state.active &&
      !_state.userStopped &&
      !_state.timelinePending &&
      !_state.isLoading &&
      (_state.isPlaying || _state.isBuffering);

  void _setStatus(RecitationStatus status) {
    if (_state.status != status) _commit(_state.copyWith(status: status));
  }

  bool _abandonsPendingSeek(RecitationEvent event) =>
      event is PlaySurah ||
      event is PlayRange ||
      event is Stop ||
      event is AudioError ||
      event is AlertSuspend;

  void _commit(RecitationState next) {
    if (identical(next, _state) || next == _state) return;
    _state = next;
    _onStateChanged?.call(next);
  }

  void _trace(String message) => _log?.call('[RecitationSession] $message');
}
