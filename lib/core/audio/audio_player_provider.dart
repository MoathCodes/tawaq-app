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
  AudioLease? _lease;

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
  Future<void> playTrack(
    AudioTrack track, {
    Duration fadeIn = kAudioDefaultFadeIn,
  }) async {
    _lease = await _service.acquire(owner: kAdhanLeaseOwner);
    await _service.play(
      track,
      fadeIn: fadeIn,
      owner: kAdhanLeaseOwner,
    );
  }

  /// Pauses the active track.
  Future<void> pause() => _service.pause();

  /// Resumes the active track.
  Future<void> resume() => _service.resume();

  /// Stops playback, optionally ramping the volume down over [fadeOut].
  Future<void> stop({Duration fadeOut = Duration.zero}) async {
    await _service.stop(fadeOut: fadeOut, owner: kAdhanLeaseOwner);
    _lease = null;
  }

  /// Sets output volume from 0 to 100.
  Future<void> setVolume(double volume) => _service.setVolume(volume);
}
