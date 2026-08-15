import 'dart:async';

import 'package:tawaq/core/audio/audio_service.dart' show TawaqAudioService;
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart' show RecitationState;
import 'package:tawaq/feature/quran/domain/services/recitation_playback_policy.dart';

/// How an intentional position change should reach the audio engine.
enum SeekRequestMode {
  /// Track already loaded — call [TawaqAudioService.seek].
  inTrack,

  /// Track is loading — remember target and seek after open completes.
  deferUntilLoaded,
}

/// Chains [work] onto [tail] so callers share one async mutex.
///
/// Used by the recitation controller so UI session seeks and machine
/// `SeekAudio` / load effects cannot interleave.
Future<void> chainEffectsTail(
  Future<void> tail,
  Future<void> Function() work,
) {
  return tail.catchError((_) {}).then((_) => work());
}

/// Whether a failed seek should clear optimistic pending UI.
///
/// Older seeks that lose the engine race must not wipe a newer pending target.
bool shouldRevertPendingSeek({
  required Duration? currentPending,
  required Duration failedTarget,
}) {
  return currentPending != null && currentPending == failedTarget;
}

/// Session-owned seek gate: one deferred slot, one timeout, one land/fail path.
///
/// Optimistic [RecitationState.pendingSeekTarget] is still written by the
/// transition layer so UI can read it; this pipeline is the only place that
/// schedules the 2s timeout, defers seeks during load, and calls
/// `TawaqAudioService.seek` for in-track seeks.
///
/// Mid-file opens use `openAndSeekTo(start: …)` outside this class; after open
/// completes, call [flushDeferred] so a scrub-during-load still lands.
///
/// [clear] bumps [generation] so in-flight / queued [request] and
/// [flushDeferred] calls skip engine seeks after Play/Stop/AlertSuspend.
final class SeekPipeline {
  /// Creates an empty pipeline.
  SeekPipeline({
    required this._log,
    required this._seek,
    required this._onSeekFailed,
    required this._onTimeout,
    required this._lastAcceptedPosition,
    required this._hasPendingSeek,
  });

  final void Function(String message) _log;
  final Future<bool> Function(Duration position) _seek;
  final void Function({
    required Duration revertTo,
    required Duration failedTarget,
  })
  _onSeekFailed;
  final void Function({required Duration revertTo}) _onTimeout;
  final Duration Function() _lastAcceptedPosition;
  final bool Function() _hasPendingSeek;

  Timer? _timeout;
  Duration? _deferredTarget;
  int _generation = 0;

  /// Target queued while the track was still loading, if any.
  Duration? get deferredTarget => _deferredTarget;

  /// Whether a deferred-during-load seek is waiting for open to finish.
  bool get hasDeferred => _deferredTarget != null;

  /// Bumped by [clear]; in-flight seeks capture it and no-op when stale.
  int get generation => _generation;

  /// Arms or restarts the pending-seek timeout while a pending target exists.
  ///
  /// Called on every session dispatch so ignored position ticks still restart
  /// the 2s clock (same restart-on-activity rule as the old controller timer).
  void syncTimeout() {
    if (!_hasPendingSeek()) {
      cancelTimeout();
      return;
    }
    _timeout?.cancel();
    _timeout = Timer(pendingSeekTimeout, () {
      if (!_hasPendingSeek()) return;
      final revertTo = _lastAcceptedPosition();
      _log(
        'PendingSeekTimeout firing revertToMs=${revertTo.inMilliseconds}',
      );
      _onTimeout(revertTo: revertTo);
    });
  }

  /// Cancels the pending-seek timeout without clearing deferred state.
  void cancelTimeout() {
    _timeout?.cancel();
    _timeout = null;
  }

  /// Clears deferred-during-load, cancels the timeout, and invalidates
  /// in-flight / queued seeks via [generation].
  void clear() {
    _deferredTarget = null;
    cancelTimeout();
    _generation++;
  }

  /// Executes an intentional in-track seek or defers it until load completes.
  Future<void> request(
    Duration position, {
    required SeekRequestMode mode,
  }) async {
    switch (mode) {
      case SeekRequestMode.deferUntilLoaded:
        _deferredTarget = position;
        _log(
          'SeekPipeline defer targetMs=${position.inMilliseconds}',
        );
      case SeekRequestMode.inTrack:
        final gen = _generation;
        _log(
          'SeekPipeline inTrack start targetMs=${position.inMilliseconds} '
          'gen=$gen',
        );
        final ok = await _seek(position);
        // AlertSuspend / PlaySurah / Stop may clear while seek is in flight.
        if (gen != _generation) {
          _log(
            'SeekPipeline inTrack ignored after clear '
            'targetMs=${position.inMilliseconds}',
          );
          return;
        }
        _deferredTarget = null;
        if (!ok) {
          _log(
            'SeekPipeline inTrack failure '
            'targetMs=${position.inMilliseconds}',
          );
          _onSeekFailed(
            revertTo: _lastAcceptedPosition(),
            failedTarget: position,
          );
        } else {
          _log(
            'SeekPipeline inTrack success '
            'targetMs=${position.inMilliseconds}',
          );
        }
    }
  }

  /// Applies a scrub that arrived while open-with-start was in flight.
  Future<void> flushDeferred() async {
    final pending = _deferredTarget;
    if (pending == null) return;
    final gen = _generation;
    _deferredTarget = null;
    _log(
      'SeekPipeline flushDeferred targetMs=${pending.inMilliseconds} gen=$gen',
    );
    if (gen != _generation) return;
    await _seek(pending);
  }

  /// Whether [position] lands the current pending seek (500ms tolerance).
  static bool landsPending({
    required Duration position,
    required Duration pending,
  }) {
    return positionNearTarget(position, pending);
  }

  /// Disposes timers; safe to call from provider dispose.
  void dispose() {
    clear();
  }
}
