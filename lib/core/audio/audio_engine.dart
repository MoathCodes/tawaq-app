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

  /// Opens and optionally starts [track].
  Future<void> play(AudioTrack track);

  /// Pauses playback.
  Future<void> pause();

  /// Resumes playback.
  Future<void> resume();

  /// Stops playback and clears the active track.
  Future<void> stop();

  /// Sets volume from 0 to 100.
  Future<void> setVolume(double volume);
}
