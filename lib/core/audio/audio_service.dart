import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_engine.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

/// Process-wide mpv-backed audio engine for adhan and future Quran playback.
class TawaqAudioService implements AudioEngine {
  /// Creates a [TawaqAudioService].
  TawaqAudioService() {
    _player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: true,
      ),
    );
    _subscriptions.addAll([
      _player.stream.playing.listen((_) => _emitState()),
      _player.stream.position.listen((_) => _emitState()),
      _player.stream.duration.listen((_) => _emitState()),
      _player.stream.error.listen((error) {
        _state = PlaybackError(
          track: _activeTrack,
          message: error.toString(),
        );
        _stateController.add(_state);
      }),
      _player.stream.completed.listen((completed) {
        if (completed) unawaited(stop());
      }),
    ]);
    _stateController.add(_state);
  }

  late final Player _player;
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AudioTrack? _activeTrack;
  PlaybackState _state = const PlaybackIdle();

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  Player get player => _player;

  void _emitState() {
    final track = _activeTrack;
    if (track == null) {
      _state = const PlaybackIdle();
    } else {
      final position = _player.state.position;
      final duration = _player.state.duration;
      _state = _player.state.playWhenReady
          ? PlaybackPlaying(
              track: track,
              position: position,
              duration: duration,
            )
          : PlaybackPaused(
              track: track,
              position: position,
              duration: duration,
            );
    }
    _stateController.add(_state);
  }

  @override
  Future<void> play(AudioTrack track) async {
    await stop();
    _activeTrack = track;
    _state = PlaybackLoading(track);
    _stateController.add(_state);
    await _player.open(Media(track.uri));
    await _player.setAudioClientName('Tawaq');
    await _player.setMediaSession(
      MediaSession(
        title: track.title,
        artist: track.subtitle ?? 'Tawaq',
      ),
    );
    _emitState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _emitState();
  }

  @override
  Future<void> resume() async {
    await _player.play();
    _emitState();
  }

  @override
  Future<void> stop() async {
    _activeTrack = null;
    await _player.stop();
    await _player.setMediaSession(null);
    _state = const PlaybackIdle();
    _stateController.add(_state);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0, 100));
  }

  /// Releases native handles. Called on app shutdown.
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _stateController.close();
    await _player.dispose();
  }
}
