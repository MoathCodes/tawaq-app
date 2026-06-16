import 'package:tawaq/core/audio/audio_service.dart' show TawaqAudioService;
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

/// Minimal playback surface for unit tests and [TawaqAudioService].
abstract interface class AudioEngine {
  /// Current playback snapshot.
  PlaybackState get state;

  /// Emits playback state changes.
  Stream<PlaybackState> get stateStream;

  /// Emits the current playback position.
  Stream<Duration> get positionStream;

  /// Emits the active track duration when known.
  Stream<Duration> get durationStream;

  /// Opens and starts [track].
  ///
  /// When [fadeIn] is greater than zero the output volume ramps from silence
  /// up to the configured volume over that duration.
  Future<void> play(AudioTrack track, {Duration fadeIn});

  /// Pauses playback.
  Future<void> pause();

  /// Resumes playback.
  Future<void> resume();

  /// Stops playback and clears the active track.
  ///
  /// When [fadeOut] is greater than zero the output volume ramps down to
  /// silence over that duration before the player is stopped.
  Future<void> stop({Duration fadeOut});

  /// Sets volume from 0 to 100.
  Future<void> setVolume(double volume);
}
