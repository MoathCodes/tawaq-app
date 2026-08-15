import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

part 'audio_player_provider.g.dart';

/// Singleton [TawaqAudioService] for the process.
@Riverpod(keepAlive: true)
TawaqAudioService tawaqAudioService(Ref ref) {
  final service = TawaqAudioService();
  ref.onDispose(service.dispose);
  return service;
}

/// Canonical native-event snapshot for all shared audio transport state.
@Riverpod(keepAlive: true)
class AudioSession extends _$AudioSession {
  @override
  AudioSessionSnapshot build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    final subscriptions = <StreamSubscription<dynamic>>[
      service.stateStream.listen((next) => _applyLifecycle(service, next)),
      service.leaseOwnerStream.listen((owner) {
        state = state.copyWith(owner: owner, clearOwner: owner == null);
      }),
      service.playWhenReadyStream.listen(
        (intent) => state = state.copyWith(playIntent: intent),
      ),
      service.positionStream.listen(
        (position) => state = state.copyWith(position: position),
      ),
      service.durationStream.listen(
        (duration) => state = state.copyWith(duration: duration),
      ),
      service.bufferedRangesStream.listen(
        (ranges) => state = state.copyWith(
          bufferedRanges: List.unmodifiable(ranges),
        ),
      ),
      service.currentIndexStream.listen(
        (index) => state = state.copyWith(playlistIndex: index),
      ),
      service.remainingAbLoopsStream.listen((loops) {
        state = state.copyWith(
          remainingAbLoops: loops,
          clearRemainingAbLoops: loops == null,
        );
      }),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
    });
    return _snapshotFrom(service, service.state);
  }

  void _applyLifecycle(TawaqAudioService service, PlaybackState next) {
    state = _snapshotFrom(service, next, previous: state);
  }

  AudioSessionSnapshot _snapshotFrom(
    TawaqAudioService service,
    PlaybackState playback, {
    AudioSessionSnapshot previous = const AudioSessionSnapshot(),
  }) {
    final track = switch (playback) {
      PlaybackLoading(:final track) ||
      PlaybackBuffering(:final track) ||
      PlaybackPlaying(:final track) ||
      PlaybackPaused(:final track) ||
      PlaybackCompleted(:final track) => track,
      PlaybackError(:final track) => track,
      PlaybackIdle() => null,
    };
    final lifecycle = switch (playback) {
      PlaybackIdle() => AudioSessionLifecycle.idle,
      PlaybackLoading() => AudioSessionLifecycle.loading,
      PlaybackBuffering() => AudioSessionLifecycle.buffering,
      PlaybackPlaying() => AudioSessionLifecycle.playing,
      PlaybackPaused() => AudioSessionLifecycle.paused,
      PlaybackCompleted() => AudioSessionLifecycle.completed,
      PlaybackError() => AudioSessionLifecycle.error,
    };
    final position = switch (playback) {
      PlaybackPlaying(:final position) ||
      PlaybackPaused(:final position) ||
      PlaybackCompleted(:final position) => position,
      _ => previous.position,
    };
    final duration = switch (playback) {
      PlaybackPlaying(:final duration) ||
      PlaybackPaused(:final duration) ||
      PlaybackCompleted(:final duration) => duration,
      _ => previous.duration,
    };
    final resetsTransport =
        playback is PlaybackIdle || playback is PlaybackLoading;
    return previous.copyWith(
      owner: service.currentLeaseOwner,
      clearOwner: service.currentLeaseOwner == null,
      track: track,
      clearTrack: track == null,
      lifecycle: lifecycle,
      playIntent: !resetsTransport && service.playWhenReady,
      position: resetsTransport ? Duration.zero : position,
      duration: resetsTransport ? Duration.zero : duration,
      bufferedRanges: resetsTransport ? const [] : null,
      playlistIndex: resetsTransport ? 0 : null,
      clearRemainingAbLoops: resetsTransport,
      error: playback is PlaybackError ? playback.message : null,
      clearError: playback is! PlaybackError,
    );
  }
}

/// Command-only controller for adhan transport.
@Riverpod(keepAlive: true)
class AdhanAudioController extends _$AdhanAudioController {
  @override
  void build() {}

  TawaqAudioService get _service => ref.read(tawaqAudioServiceProvider);

  /// Plays a single [track], optionally ramping the volume up over [fadeIn].
  ///
  /// Acquires the adhan lease via [TawaqAudioService.play], stealing any other
  /// owner (force-steal stops the prior session inside the service).
  Future<void> playTrack(
    AudioTrack track, {
    Duration fadeIn = kAudioDefaultFadeIn,
  }) async {
    await _service.play(
      track,
      fadeIn: fadeIn,
      owner: kAdhanLeaseOwner,
      force: true,
    );
  }

  /// Pauses the active track when this controller holds the adhan lease.
  Future<bool> pause() => _service.pause(owner: kAdhanLeaseOwner);

  /// Resumes the active track when this controller holds the adhan lease.
  Future<bool> resume() => _service.resume(owner: kAdhanLeaseOwner);

  /// Stops playback, optionally ramping the volume down over [fadeOut].
  ///
  /// Pass [force] to stop even when another owner holds the lease (armed
  /// alert teardown must always reclaim the engine).
  Future<void> stop({
    Duration fadeOut = Duration.zero,
    bool force = false,
  }) async {
    await _service.stop(
      fadeOut: fadeOut,
      owner: kAdhanLeaseOwner,
      force: force,
    );
  }

  /// Sets output volume from 0 to 100.
  Future<void> setVolume(double volume) => _service.setVolume(volume);
}
