import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_engine.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

/// Default fade-in applied when [TawaqAudioService.play] is called without an
/// explicit ramp.
const kAudioDefaultFadeIn = Duration(milliseconds: 800);

/// Default fade-out applied when [TawaqAudioService.stop] is called without an
/// explicit ramp.
const kAudioDefaultFadeOut = Duration(milliseconds: 500);

/// Interval between volume steps while fading.
const _fadeStep = Duration(milliseconds: 40);

/// Process-wide mpv-backed audio engine for adhan and future Quran playback.
class TawaqAudioService implements AudioEngine {
  /// Creates a [TawaqAudioService].
  TawaqAudioService() {
    _player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: true,
      ),
    );
    // Identify the audio client once; it never changes for the lifetime of the
    // process.
    unawaited(_player.setAudioClientName('Tawaq'));
    _subscriptions.addAll([
      // State is emitted only on real lifecycle transitions. Position/duration
      // ticks are intentionally NOT bridged here — UI that needs them watches
      // [positionStream]/[durationStream] directly, which avoids reallocating
      // and re-broadcasting a full [PlaybackState] many times per second.
      _player.stream.playing.listen((_) => _emitState()),
      _player.stream.error.listen((error) {
        final track = _activeTrack;
        _activeTrack = null;
        _cancelFade();
        _emit(PlaybackError(track: track, message: error.toString()));
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

  /// Desired output volume (0-100) used as the fade target.
  double _targetVolume = 100;
  Timer? _fadeTimer;

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  /// Low-level player handle for visualizers and advanced UI.
  Player get player => _player;

  void _emit(PlaybackState next) {
    _state = next;
    _stateController.add(_state);
  }

  void _emitState() {
    final track = _activeTrack;
    if (track == null) {
      _emit(const PlaybackIdle());
      return;
    }
    final position = _player.state.position;
    final duration = _player.state.duration;
    _emit(
      _player.state.playWhenReady
          ? PlaybackPlaying(
              track: track,
              position: position,
              duration: duration,
            )
          : PlaybackPaused(
              track: track,
              position: position,
              duration: duration,
            ),
    );
  }

  @override
  Future<void> play(
    AudioTrack track, {
    Duration fadeIn = kAudioDefaultFadeIn,
  }) async {
    _cancelFade();
    _activeTrack = track;
    _emit(PlaybackLoading(track));
    try {
      // Open replaces any current media; with autoPlay it starts immediately.
      // Pre-set the volume so the first frames already match the fade ramp.
      await _player.setVolume(fadeIn > Duration.zero ? 0 : _targetVolume);
      await _player.open(Media(track.uri));
      await _player.setMediaSession(
        MediaSession(title: track.title, artist: track.subtitle ?? 'Tawaq'),
      );
      if (fadeIn > Duration.zero) {
        unawaited(_fadeVolume(from: 0, to: _targetVolume, duration: fadeIn));
      }
      _emitState();
    } on Object catch (error) {
      // A throwing open() (e.g. missing/corrupt asset) must surface as a
      // terminal error instead of an unhandled async exception, so the alert
      // pipeline can dismiss rather than hang.
      _activeTrack = null;
      _cancelFade();
      _emit(PlaybackError(track: track, message: error.toString()));
    }
  }

  /// Waits until the current media is demuxed and seekable, bounded by
  /// [timeout]. Returns whether the player became seekable.
  ///
  /// mpv rejects a seek issued before the timeline exists (command error -12),
  /// which happens when seeking right after [play] — the demuxer hasn't yet
  /// reported a seekable range. Callers that need an initial offset (e.g. ayah
  /// playback) must await this before seeking.
  Future<bool> waitUntilSeekable({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_activeTrack == null) return false;
    if (_player.state.seekable) {
      // Let the demuxer settle — seekable can flip true before seeks succeed.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return _player.state.seekable;
    }
    try {
      final seekable = await _player.stream.seekable
          .firstWhere((seekable) => seekable)
          .timeout(timeout);
      if (!seekable) return false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return _player.state.seekable;
    } on TimeoutException {
      return false;
    }
  }

  /// Seeks when the timeline is ready, retrying mpv command error -12 instead of
  /// surfacing an unhandled [MpvException] to callers.
  Future<bool> safeSeek(
    Duration position, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_activeTrack == null) return false;

    for (var attempt = 0; attempt < 4; attempt++) {
      if (!await waitUntilSeekable(timeout: timeout)) {
        await Future<void>.delayed(Duration(milliseconds: 80 * (attempt + 1)));
        continue;
      }
      try {
        await _player.seek(position);
        return true;
      } on Object {
        await Future<void>.delayed(Duration(milliseconds: 120 * (attempt + 1)));
      }
    }
    return false;
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
  Future<void> stop({Duration fadeOut = Duration.zero}) async {
    _cancelFade();
    if (fadeOut > Duration.zero && _activeTrack != null) {
      await _fadeVolume(from: _targetVolume, to: 0, duration: fadeOut);
    }
    _activeTrack = null;
    await _player.stop();
    await _player.setMediaSession(null);
    // Restore the configured volume so a subsequent non-fading play is correct.
    await _player.setVolume(_targetVolume);
    _emit(const PlaybackIdle());
  }

  @override
  Future<void> setVolume(double volume) async {
    _targetVolume = volume.clamp(0, 100).toDouble();
    // While a ramp is in flight it owns the volume; it will land on the new
    // target on completion.
    if (_fadeTimer == null) {
      await _player.setVolume(_targetVolume);
    }
  }

  /// Ramps the player volume from [from] to [to] over [duration].
  Future<void> _fadeVolume({
    required double from,
    required double to,
    required Duration duration,
  }) async {
    _cancelFade();
    await _player.setVolume(from.clamp(0, 100).toDouble());
    if (duration <= Duration.zero || from == to) {
      await _player.setVolume(to.clamp(0, 100).toDouble());
      return;
    }
    final steps = (duration.inMilliseconds / _fadeStep.inMilliseconds).ceil();
    final delta = (to - from) / steps;
    final completer = Completer<void>();
    var i = 0;
    _fadeTimer = Timer.periodic(_fadeStep, (timer) {
      i++;
      final value = i >= steps ? to : from + delta * i;
      unawaited(_player.setVolume(value.clamp(0, 100).toDouble()));
      if (i >= steps) {
        timer.cancel();
        _fadeTimer = null;
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
  }

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  // ---- A-B loop & native loop -----------------------------------------------

  /// Sets the A marker for an A-B loop. Pass `null` to clear.
  Future<void> setAbLoopA(Duration? a) => _player.setAbLoopA(a);

  /// Sets the B marker for an A-B loop. Pass `null` to clear.
  Future<void> setAbLoopB(Duration? b) => _player.setAbLoopB(b);

  /// Sets the number of A-B loop repetitions. Pass `null` for infinite.
  Future<void> setAbLoopCount(int? count) =>
      _player.setAbLoopCount(count);

  /// Remaining A-B loop iterations (null when no loop or infinite).
  Stream<int?> get remainingAbLoopsStream => _player.stream.remainingAbLoops;

  /// Sets the native repeat mode ([Loop.off], [Loop.file], [Loop.playlist]).
  Future<void> setLoop(Loop loop) => _player.setLoop(loop);

  /// Releases native handles. Called on app shutdown.
  Future<void> dispose() async {
    _cancelFade();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _stateController.close();
    await _player.dispose();
  }
}
