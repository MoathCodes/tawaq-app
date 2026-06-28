import 'dart:async';
import 'dart:developer' as developer;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

/// Converts an [AudioTrack] into the mpv [Media] representation used by
/// [TawaqAudioService.openAll].
Media _mediaFromTrack(AudioTrack track) => Media(track.uri);

/// Default fade-in applied when [TawaqAudioService.play] is called without an
/// explicit ramp.
const kAudioDefaultFadeIn = Duration(milliseconds: 800);

/// Default fade-out applied when [TawaqAudioService.stop] is called without an
/// explicit ramp.
const kAudioDefaultFadeOut = Duration(milliseconds: 500);

/// Interval between volume steps while fading.
const _fadeStep = Duration(milliseconds: 40);

/// Process-wide mpv-backed audio engine for adhan and Quran recitation.
class TawaqAudioService {
  /// Creates a [TawaqAudioService].
  TawaqAudioService({PlayerApi? player})
      : _player = player ?? Player() {
    // autoPlay defaults to false: open(play: false) never starts playback
    // until play() is called explicitly, so seeks complete before audio.
    // Identify the audio client once; it never changes for the lifetime of
    // the process.
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
      _player.stream.endFile.listen((endFile) {
        switch (endFile.reason) {
          case MpvEndFileReason.eof:
            // Distinguish a genuine natural eof from a network drop that mpv
            // misreports as eof. Skip the heuristic for local file:// URIs
            // (cached recitations). For network streams, only flag a drop when
            // playback ended more than 10% before the reported duration on
            // tracks longer than 30s (VBR mp3s often overestimate duration).
            final duration = _player.state.duration;
            final position = _player.state.position;
            final uri = _activeTrack?.uri;
            final isNetworkDrop = _isLikelyNetworkDrop(
              duration: duration,
              position: position,
              uri: uri,
            );
            if (isNetworkDrop) {
              final track = _activeTrack;
              _activeTrack = null;
              _cancelFade();
              _emit(PlaybackError(
                track: track,
                message: 'network drop: ended at $position of $duration',
              ));
            } else {
              unawaited(stop());
            }
          case MpvEndFileReason.error:
            final track = _activeTrack;
            _activeTrack = null;
            _cancelFade();
            _emit(PlaybackError(
              track: track,
              message: 'endFile error: ${endFile.error}',
            ));
          case MpvEndFileReason.stop:
          case MpvEndFileReason.quit:
          case MpvEndFileReason.redirect:
            // Benign: emitted when stop()/open()/playlist-next is called.
            // The initiator already manages state; do not surface as error.
            break;
        }
      }),
      _player.stream.buffering.listen((_) => _emitBuffering()),
      _player.stream.pausedForCache.listen((_) => _emitBuffering()),
    ]);
    _stateController.add(_state);
  }

  final PlayerApi _player;
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AudioTrack? _activeTrack;
  PlaybackState _state = const PlaybackIdle();

  /// Desired output volume (0-100) used as the fade target.
  double _targetVolume = 100;
  Timer? _fadeTimer;

  final _volumeController = StreamController<double>.broadcast();

  // ---- Lease state ----------------------------------------------------------
  // Pure, mpv-free ownership coordination is delegated to AudioLeaseRegistry
  // so the lease logic stays unit-testable without native player init.
  final AudioLeaseRegistry _leases = AudioLeaseRegistry(
    onWatchdogForceRelease: (owner) => developer.log(
      'Watchdog force-releasing lease for $owner',
      name: 'tawaq.audio',
    ),
  );

  /// Current lease owner, or null when idle.
  String? get currentLeaseOwner => _leases.currentOwner;

  /// Stream that fires on every lease acquire/release (for contended callers).
  Stream<void> get leaseStream => _leases.leaseStream;

  PlaybackState get state => _state;

  Stream<PlaybackState> get stateStream => _stateController.stream;

  Stream<Duration> get positionStream => _player.stream.position;

  Stream<Duration> get durationStream => _player.stream.duration;

  /// Emits the currently active playlist index (0-based) whenever it
  /// changes. Derived from [PlayerStream.playlist].
  Stream<int> get currentIndexStream =>
      _player.stream.playlist.map((playlist) => playlist.index);

  /// Incoming commands issued by the OS media session (lockscreen taps,
  /// Bluetooth headset buttons, Siri / Google Assistant, Android Auto /
  /// CarPlay). These are auto-applied to the native player by the package;
  /// this passthrough exists so the app's command router can layer
  /// lease-owner dispatch (recitation vs adhan) on top — e.g. route a
  /// `next` command to recitation's ayah/surah skip logic instead of the
  /// raw mpv playlist.
  Stream<MediaSessionCommand> get mediaSessionCommands =>
      _player.stream.mediaSessionCommands;

  /// The advertised capabilities + metadata published to the OS media
  /// session. Exposed so the command router can reason about which
  /// controls the surfaces render.
  Set<MediaAction> get mediaSessionActions => _mediaSessionActions;

  final Set<MediaAction> _mediaSessionActions = const {
    MediaAction.play,
    MediaAction.pause,
    MediaAction.playPause,
    MediaAction.next,
    MediaAction.previous,
    MediaAction.seek,
    MediaAction.stop,
  };

  /// Builds the rich [MediaSession] metadata for [track] using the current
  /// advertised actions, duration, and a fallback artist.
  ///
  /// The duration is only set when mpv already reports one; otherwise `null`
  /// lets the OS media session fall back to mpv's `duration` property once it
  /// resolves, instead of pinning an explicit zero that would suppress it.
  MediaSession _mediaSessionFor(AudioTrack track) {
    final duration = _player.state.duration;
    return MediaSession(
      title: track.title,
      artist: track.subtitle ?? 'Tawaq',
      duration: duration > Duration.zero ? duration : null,
      actions: _mediaSessionActions,
    );
  }

  /// Low-level player handle for visualizers and advanced UI.
  PlayerApi get player => _player;

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

  void _emitBuffering() {
    final track = _activeTrack;
    if (track != null) {
      _emit(PlaybackBuffering(track));
    }
  }

  /// Returns true when an eof event likely reflects a network stall rather
  /// than natural completion.
  bool _isLikelyNetworkDrop({
    required Duration duration,
    required Duration position,
    required String? uri,
  }) {
    if (uri != null && uri.startsWith('file://')) return false;
    if (duration <= const Duration(seconds: 30)) return false;
    if (duration <= Duration.zero) return false;
    final thresholdMs = (duration.inMilliseconds * 0.90).round();
    return position.inMilliseconds < thresholdMs;
  }

  /// Loads [tracks] as a playlist, optionally starting at [index], and
  /// starts playback. Replaces any current file or playlist.
  Future<void> openAll(
    List<AudioTrack> tracks, {
    int index = 0,
    String? owner,
  }) async {
    final effectiveOwner = owner ?? _leases.currentOwner ?? 'unknown';
    if (!_leases.hasValidLease(effectiveOwner)) {
      await acquire(owner: effectiveOwner);
    }
    _cancelFade();
    await clearAbLoop();
    final activeTrack = tracks.elementAtOrNull(index);
    _activeTrack = activeTrack;
    _emit(PlaybackLoading(activeTrack ?? _fallbackTrack(tracks)));
    try {
      await _player.setVolume(_targetVolume);
      await _player.openAll(
        tracks.map(_mediaFromTrack).toList(),
        play: true,
        index: index,
      );
      if (tracks.isNotEmpty) {
        await _player.setMediaSession(
          _mediaSessionFor(tracks[index.clamp(0, tracks.length - 1)]),
        );
      }
      _emitState();
    } on Object catch (error) {
      _activeTrack = null;
      _cancelFade();
      _emit(PlaybackError(track: null, message: error.toString()));
    }
  }

  Future<void> play(
    AudioTrack track, {
    Duration fadeIn = kAudioDefaultFadeIn,
    String? owner,
  }) async {
    final effectiveOwner = owner ?? _leases.currentOwner ?? 'unknown';
    if (!_leases.hasValidLease(effectiveOwner)) {
      await acquire(owner: effectiveOwner);
    }
    _cancelFade();
    await clearAbLoop();
    _activeTrack = track;
    _emit(PlaybackLoading(track));
    try {
      await _player.setVolume(fadeIn > Duration.zero ? 0 : _targetVolume);
      await _player.open(Media(track.uri), play: false);
      await _player.setMediaSession(_mediaSessionFor(track));
      if (fadeIn > Duration.zero) {
        unawaited(_fadeVolume(from: 0, to: _targetVolume, duration: fadeIn));
      }
      await _player.play();
      _emitState();
    } on Object catch (error) {
      _activeTrack = null;
      _cancelFade();
      _emit(PlaybackError(track: track, message: error.toString()));
    }
  }

  int _seekGeneration = 0;

  /// Opens media without auto-play then seeks to [start] and begins playback.
  ///
  /// Waits for mpv's post-load [PlayerStream.seekCompleted] before issuing
  /// [Player.seek], then waits for the seek landing before calling [play].
  /// Generation tags ignore stale signals from superseded loads.
  Future<void> openAndSeekTo(
    AudioTrack track, {
    Duration? start,
    Duration fadeIn = kAudioDefaultFadeIn,
    String? owner,
  }) async {
    final effectiveOwner = owner ?? _leases.currentOwner ?? 'unknown';
    if (!_leases.hasValidLease(effectiveOwner)) {
      await acquire(owner: effectiveOwner);
    }
    _cancelFade();
    await clearAbLoop();
    _activeTrack = track;
    _emit(PlaybackLoading(track));
    final loadGen = ++_seekGeneration;
    try {
      await _player.setVolume(fadeIn > Duration.zero ? 0 : _targetVolume);
      final loadReady = _player.stream.seekCompleted
          .firstWhere((_) => _seekGeneration == loadGen)
          .timeout(const Duration(seconds: 15));
      await _player.open(Media(track.uri), play: false);
      await _player.setMediaSession(_mediaSessionFor(track));
      await loadReady;

      if (start != null && start > Duration.zero) {
        final seekGen = ++_seekGeneration;
        final seekLanding = _player.stream.seekCompleted
            .firstWhere((_) => _seekGeneration == seekGen)
            .timeout(const Duration(seconds: 15));
        await _player.seek(start);
        await seekLanding;
      }
      if (fadeIn > Duration.zero) {
        unawaited(_fadeVolume(from: 0, to: _targetVolume, duration: fadeIn));
      }
      await _player.play();
      _emitState();
    } on Object catch (error) {
      _activeTrack = null;
      _cancelFade();
      _emit(PlaybackError(track: track, message: error.toString()));
    }
  }

  /// Seeks to [position] in the currently loaded track.
  ///
  /// Returns `false` when nothing is loaded or [owner] does not hold the lease.
  /// Prefer this over [PlayerApi.seek] so callers avoid mpv errors during file
  /// reloads (e.g. reciter switches).
  Future<bool> seek(Duration position, {String? owner}) async {
    if (_activeTrack == null) return false;
    final effectiveOwner = owner ?? _leases.currentOwner;
    if (effectiveOwner != null && !_leases.hasValidLease(effectiveOwner)) {
      return false;
    }
    try {
      await _player.seek(position);
      _emitState();
      return true;
    } on Object catch (error) {
      final track = _activeTrack;
      _activeTrack = null;
      _cancelFade();
      _emit(PlaybackError(track: track, message: error.toString()));
      return false;
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _emitState();
  }

  Future<void> resume() async {
    await _player.play();
    _emitState();
  }

  Future<void> stop({Duration fadeOut = Duration.zero, String? owner}) async {
    final effectiveOwner = owner ?? _leases.currentOwner;
    if (effectiveOwner != null && !_leases.hasValidLease(effectiveOwner)) {
      return; // ignore stop from non-owner
    }
    _cancelFade();
    if (fadeOut > Duration.zero && _activeTrack != null) {
      await _fadeVolume(from: _targetVolume, to: 0, duration: fadeOut);
    }
    _activeTrack = null;
    await clearAbLoop();
    await _player.stop();
    await _player.setMediaSession(null);
    await _player.setVolume(_targetVolume);
    _emit(const PlaybackIdle());
    _leases.releaseCurrent();
  }

  /// Current target output volume (0-100).
  double get volume => _targetVolume;

  /// Emits the target volume whenever it changes.
  Stream<double> get volumeStream => _volumeController.stream;

  Future<void> setVolume(double volume) async {
    _targetVolume = volume.clamp(0, 100).toDouble();
    _volumeController.add(_targetVolume);
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

  /// Clears mpv A-B loop markers so a new track (e.g. adhan) does not inherit
  /// recitation per-ayah loop state.
  Future<void> clearAbLoop() async {
    await setAbLoopA(null);
    await setAbLoopB(null);
    await setAbLoopCount(null);
  }

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

  /// Enables or disables prefetching the next playlist entry during
  /// playback.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setPrefetchPlaylist(bool enabled) =>
      _player.setPrefetchPlaylist(enabled);

  /// Sets the gapless-playback policy across playlist boundaries.
  Future<void> setGapless(Gapless gapless) => _player.setGapless(gapless);

  AudioTrack _fallbackTrack(List<AudioTrack> tracks) {
    return tracks.isNotEmpty
        ? tracks.first
        : AudioTrack.network(
            id: 'fallback',
            title: 'Fallback',
            url: 'asset:///fallback.mp3',
          );
  }

  /// Releases the lease for [owner] if it currently holds it.
  ///
  /// Idempotent: safe to call when the lease is idle or held by another
  /// owner.
  Future<void> release({required String owner}) async {
    if (_leases.hasValidLease(owner)) {
      _leases.releaseCurrent();
    }
  }

  /// Releases native handles. Called on app shutdown.
  Future<void> dispose() async {
    _cancelFade();
    await _leases.dispose();
    await _volumeController.close();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _stateController.close();
    await _player.dispose();
  }

  // ---- Lease API ------------------------------------------------------------

  /// Acquires exclusive ownership of the audio engine.
  ///
  /// Returns a lease token that must be released when done. If another owner
  /// holds the lease, the call waits until it is released or the watchdog
  /// forces a release.
  Future<AudioLease> acquire({required String owner}) =>
      _leases.acquire(owner: owner);
}
