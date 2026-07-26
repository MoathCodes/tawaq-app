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

/// High-level playback controller for adhan transport and UI state mirroring.
@Riverpod(keepAlive: true)
class AudioPlayerController extends _$AudioPlayerController {
  @override
  PlaybackState build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    final sub = service.stateStream.listen((next) {
      state = next;
    });
    ref.onDispose(sub.cancel);
    return service.state;
  }

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
