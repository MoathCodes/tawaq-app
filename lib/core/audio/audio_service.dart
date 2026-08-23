import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart' show rootBundle;
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

/// Linux MPRIS `.desktop` basename for Tawaq (see install script).
const kMediaSessionDesktopEntry = 'flutter-tawaq';

/// Stable MPRIS / SMTC app identity. Must be set on the first
/// [Player.setMediaSession] call — mpv_audio_kit locks the bus name at enable.
const kMediaSessionAppName = 'Tawaq';

/// mpv player defaults for Tawaq.
///
/// Resume is owned by Hive checkpoints + [openAndSeekTo]; native watch-later
/// must stay off so it does not fight app-side seek/resume.
const kTawaqPlayerConfiguration = PlayerConfiguration(
  resumePlayback: false,
  forceSeekable: true,
);

/// Bundled artwork published to the OS media session for recitation.
const kMediaSessionAppIconAsset = 'assets/images/app_icon.png';

const kRecitationSeekLogName = 'tawaq.recitation.seek';

/// Caller-resolved display fields for the OS media session.
///
/// Title and artist must be the surah and reciter names — never defer to mp3
/// file tags once published. [appName] and [album] come from localized ARB
/// strings (`mediaSessionAppName`, `mediaSessionAudioBy`).
class MediaSessionPublishMetadata {
  /// Creates [MediaSessionPublishMetadata].
  const new({
    required this.title,
    required this.artist,
    required this.appName,
    required this.album,
  });

  /// Surah name shown as the session title.
  final String title;

  /// Reciter name shown as the session artist.
  final String artist;

  /// Localized app display name (MPRIS / SMTC identity).
  final String appName;

  /// Localized album line (e.g. "Audio by mp3quran.net").
  final String album;
}

/// Throttle for refreshing the audio lease during continuous playback.
const _leaseKeepAliveThrottle = Duration(seconds: 10);

/// Process-wide mpv-backed audio engine for adhan and Quran recitation.
class TawaqAudioService {
  /// Creates a [TawaqAudioService].
  ///
  /// [leaseRegistry] is for tests that need a custom registry. Prefer
  /// [watchdogTimeout] when you only need a short unattended deadline — that
  /// path keeps the production watchdog→engine-clear hook.
  new({
    PlayerApi? player,
    AudioLeaseRegistry? leaseRegistry,
    Duration watchdogTimeout = const Duration(seconds: 30),
  }) : _player = player ?? Player(configuration: kTawaqPlayerConfiguration) {
    // Watchdog must stop the engine — releasing ownership alone leaves an
    // orphaned loaded track that fights the next owner.
    _leases =
        leaseRegistry ??
        AudioLeaseRegistry(
          watchdogTimeout: watchdogTimeout,
          onWatchdogForceRelease: (owner) {
            developer.log(
              'Watchdog force-releasing lease for $owner',
              name: 'tawaq.audio',
            );
            _leaseOwnerController.add(null);
            unawaited(_clearEngineAfterWatchdog());
          },
        );
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
      _player.stream.playWhenReady.listen((_) => _emitState()),
      _player.stream.completed.listen((completed) {
        if (completed) {
          _onNaturalCompletion();
        } else {
          _trackCompleted = false;
          _emitState();
        }
      }),
      _player.stream.eofReached.listen((reached) {
        if (reached) {
          _onNaturalCompletion();
        }
      }),
      _player.stream.duration.listen(
        (_) => unawaited(_refreshPublishedSession()),
      ),
      _player.stream.error.listen((error) {
        final track = _activeTrack;
        _activeTrack = null;
        _trackCompleted = false;
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
              _trackCompleted = false;
              _cancelFade();
              _emit(
                PlaybackError(
                  track: track,
                  message: 'network drop: ended at $position of $duration',
                ),
              );
            } else {
              _onNaturalCompletion();
            }
          case MpvEndFileReason.error:
            final track = _activeTrack;
            _activeTrack = null;
            _trackCompleted = false;
            _cancelFade();
            _emit(
              PlaybackError(
                track: track,
                message: 'endFile error: ${endFile.error}',
              ),
            );
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
      _player.stream.position.listen(_refreshLeaseKeepAliveFromPlayback),
    ]);
    _stateController.add(_state);
  }

  final PlayerApi _player;
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _completionController = StreamController<void>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AudioTrack? _activeTrack;
  PlaybackState _state = const PlaybackIdle();
  MediaSessionPublishMetadata? _publishedMetadata;
  CoverArt? _appIconArtwork;
  bool _trackCompleted = false;
  bool _disposed = false;

  /// Desired output volume (0-100) used as the fade target.
  double _targetVolume = 100;

  /// Last volume applied to the player (may differ from [_targetVolume] mid-fade).
  double _actualVolume = 100;

  /// Owned in-flight fade; cancel always settles [_ActiveFade.done].
  _ActiveFade? _activeFade;

  final _volumeController = StreamController<double>.broadcast();
  final _leaseOwnerController = StreamController<String?>.broadcast();

  // ---- Lease state ----------------------------------------------------------
  // Pure, mpv-free ownership coordination is delegated to AudioLeaseRegistry
  // so the lease logic stays unit-testable without native player init.
  late final AudioLeaseRegistry _leases;
  Duration? _lastKeepAlivePosition;
  Timer? _leaseKeepAliveTimer;

  /// Current lease owner, or null when idle.
  String? get currentLeaseOwner => _leases.currentOwner;

  /// Emits whenever exclusive transport ownership changes.
  Stream<String?> get leaseOwnerStream => _leaseOwnerController.stream;

  PlaybackState get state => _state;

  Stream<PlaybackState> get stateStream => _stateController.stream;

  /// Fires once when the active track reaches its natural end without unloading.
  Stream<void> get completionStream => _completionController.stream;

  /// Whether a track is currently loaded (including paused-at-EOF).
  bool get hasActiveTrack => _activeTrack != null;

  /// Whether the user/play intent axis is set (stable across seeks/buffering).
  bool get playWhenReady => _player.state.playWhenReady;

  /// Emits whenever [playWhenReady] changes.
  Stream<bool> get playWhenReadyStream => _player.stream.playWhenReady;

  Stream<Duration> get positionStream => _player.stream.position;

  Stream<Duration> get durationStream => _player.stream.duration;

  /// Seekable cache intervals without exposing the platform player to UI.
  Stream<List<PlaybackBufferRange>> get bufferedRangesStream =>
      _player.stream.demuxerCacheState.map(
        (state) => [
          for (final range in state.seekableRanges)
            (start: range.start, end: range.end),
        ],
      );

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

  /// Low-level player handle for visualizers and advanced UI.
  PlayerApi get player => _player;

  void _emit(PlaybackState next) {
    _state = next;
    _stateController.add(_state);
  }

  void _emitState() {
    final track = _activeTrack;
    if (track == null) {
      _stopLeaseKeepAliveTimer();
      _emit(const PlaybackIdle());
      return;
    }
    final position = _player.state.position;
    final duration = _player.state.duration;
    _refreshLeaseKeepAlive();
    if (_trackCompleted) {
      _emit(
        PlaybackCompleted(
          track: track,
          position: position,
          duration: duration,
        ),
      );
      return;
    }
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
    if (track != null && !_trackCompleted) {
      _refreshLeaseKeepAlive();
      _emit(PlaybackBuffering(track));
    }
  }

  /// Refreshes the lease watchdog while a track is loaded for the current
  /// owner — including paused and EOF — not only while [playWhenReady].
  ///
  /// Position ticks cover continuous play; a periodic timer covers pause/EOF
  /// where mpv stops advancing position.
  void _refreshLeaseKeepAlive() {
    final owner = _leases.currentOwner;
    if (_activeTrack == null || owner == null) {
      _stopLeaseKeepAliveTimer();
      return;
    }
    _leases.keepAlive(owner: owner);
    _leaseKeepAliveTimer ??= Timer.periodic(_leaseKeepAliveThrottle, (_) {
      final currentOwner = _leases.currentOwner;
      if (_activeTrack == null || currentOwner == null) {
        _stopLeaseKeepAliveTimer();
        return;
      }
      _leases.keepAlive(owner: currentOwner);
    });
  }

  void _stopLeaseKeepAliveTimer() {
    _leaseKeepAliveTimer?.cancel();
    _leaseKeepAliveTimer = null;
    _lastKeepAlivePosition = null;
  }

  /// Refreshes the lease watchdog during continuous playback.
  ///
  /// [_emitState] only runs on lifecycle transitions; mpv position ticks keep
  /// long sessions from losing the lease while audio is still playing.
  void _refreshLeaseKeepAliveFromPlayback(Duration position) {
    if (_activeTrack == null) return;
    final owner = _leases.currentOwner;
    if (owner == null) return;

    final last = _lastKeepAlivePosition;
    if (last != null && position - last < _leaseKeepAliveThrottle) {
      return;
    }
    _lastKeepAlivePosition = position;
    _refreshLeaseKeepAlive();
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

  void _onNaturalCompletion() {
    if (_activeTrack == null || _trackCompleted) return;
    _trackCompleted = true;
    _completionController.add(null);
    unawaited(_player.pause());
    _emitState();
  }

  /// Pauses at EOF while keeping the loaded track and media session intact.
  Future<void> pauseAtEof() async {
    if (_activeTrack == null) return;
    _trackCompleted = true;
    await _player.pause();
    _emitState();
  }

  /// Resets native loop/gapless/prefetch modes to safe defaults.
  ///
  /// Called automatically on [stop], [play], [openAll], and [openAndSeekTo].
  /// Controllers should also call this when tearing down gapless recitation.
  Future<void> resetPlaybackModes() async {
    await _player.setLoop(Loop.off);
    await _player.setGapless(Gapless.weak);
    await _player.setPrefetchPlaylist(false);
  }

  /// Publishes rich OS media-session metadata using caller-resolved strings.
  ///
  /// Title/artist are explicit overrides — mpv file tags never replace them.
  /// Artwork uses the bundled Tawaq app icon; duration refreshes automatically
  /// when [durationStream] resolves.
  Future<void> publishMediaSession(MediaSessionPublishMetadata metadata) async {
    _publishedMetadata = metadata;
    await _ensureAppIconArtwork();
    await _player.setMediaSession(_buildMediaSession());
  }

  Future<void> _refreshPublishedSession() async {
    if (_publishedMetadata == null || _activeTrack == null) return;
    final current = _player.state.mediaSession;
    if (current == null) {
      await _player.setMediaSession(_buildMediaSession());
      return;
    }
    final duration = _player.state.duration;
    final nextDuration = duration > Duration.zero ? duration : null;
    if (current.duration == nextDuration) return;
    await _player.setMediaSession(
      current.copyWith(duration: nextDuration),
    );
  }

  Future<void> _ensureAppIconArtwork() async {
    if (_appIconArtwork != null) return;
    try {
      final data = await rootBundle.load(kMediaSessionAppIconAsset);
      _appIconArtwork = CoverArt(
        bytes: data.buffer.asUint8List(),
        mimeType: 'image/png',
      );
    } on Object catch (error) {
      developer.log(
        'Failed to load media session app icon: $error',
        name: 'tawaq.audio',
      );
    }
  }

  MediaSession _buildMediaSession() {
    final metadata = _publishedMetadata;
    final duration = _player.state.duration;
    final artwork = _appIconArtwork == null
        ? MediaSessionArtwork.none
        : MediaSessionArtwork.custom(_appIconArtwork!);
    return MediaSession(
      title: metadata?.title,
      artist: metadata?.artist,
      album: metadata?.album,
      appName: metadata?.appName ?? kMediaSessionAppName,
      desktopEntry: kMediaSessionDesktopEntry,
      artwork: artwork,
      duration: duration > Duration.zero ? duration : null,
      actions: _mediaSessionActions,
      autoApplyPlaylistNavigation: false,
    );
  }

  /// Adhan/simple fallback when no [publishMediaSession] metadata is set.
  MediaSession _mediaSessionFor(AudioTrack track) {
    final duration = _player.state.duration;
    return MediaSession(
      title: track.title,
      artist: track.subtitle ?? kMediaSessionAppName,
      appName: kMediaSessionAppName,
      desktopEntry: kMediaSessionDesktopEntry,
      duration: duration > Duration.zero ? duration : null,
      actions: _mediaSessionActions,
      autoApplyPlaylistNavigation: false,
    );
  }

  Future<void> _applyMediaSessionForTrack(AudioTrack track) async {
    if (_publishedMetadata != null) {
      await _ensureAppIconArtwork();
      await _player.setMediaSession(_buildMediaSession());
    } else {
      await _player.setMediaSession(_mediaSessionFor(track));
    }
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
    _trackCompleted = false;
    await _clearWatchLater();
    await clearAbLoop();
    await resetPlaybackModes();
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
        await _applyMediaSessionForTrack(
          tracks[index.clamp(0, tracks.length - 1)],
        );
      }
      _emitState();
    } on Object catch (error) {
      _activeTrack = null;
      _trackCompleted = false;
      _cancelFade();
      _emit(PlaybackError(track: null, message: error.toString()));
    }
  }

  Future<void> play(
    AudioTrack track, {
    Duration fadeIn = kAudioDefaultFadeIn,
    String? owner,
    bool force = false,
  }) async {
    final effectiveOwner = owner ?? _leases.currentOwner ?? 'unknown';
    if (!_leases.hasValidLease(effectiveOwner)) {
      await acquire(owner: effectiveOwner, force: force);
    }
    _cancelFade();
    _trackCompleted = false;
    await _clearWatchLater();
    await clearAbLoop();
    await resetPlaybackModes();
    _activeTrack = track;
    _emit(PlaybackLoading(track));
    try {
      await _player.setVolume(fadeIn > Duration.zero ? 0 : _targetVolume);
      await _player.open(Media(track.uri), play: false);
      await _applyMediaSessionForTrack(track);
      if (fadeIn > Duration.zero) {
        unawaited(_fadeVolume(from: 0, to: _targetVolume, duration: fadeIn));
      }
      await _player.play();
      _emitState();
    } on Object catch (error) {
      _activeTrack = null;
      _trackCompleted = false;
      _cancelFade();
      _emit(PlaybackError(track: track, message: error.toString()));
    }
  }

  int _seekGeneration = 0;

  Future<void> _clearWatchLater() async {
    try {
      await _player.deleteResumeConfig();
      developer.log('deleteResumeConfig', name: kRecitationSeekLogName);
    } on Object catch (error) {
      developer.log(
        'deleteResumeConfig failed (continuing): $error',
        name: kRecitationSeekLogName,
      );
    }
  }

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
    _trackCompleted = false;
    await _clearWatchLater();
    await clearAbLoop();
    await resetPlaybackModes();
    _activeTrack = track;
    _emit(PlaybackLoading(track));
    final loadGen = ++_seekGeneration;
    try {
      developer.log(
        'openAndSeekTo start uri=${track.uri} '
        'startMs=${start?.inMilliseconds ?? 0} loadGen=$loadGen',
        name: kRecitationSeekLogName,
      );
      await _player.setVolume(fadeIn > Duration.zero ? 0 : _targetVolume);
      final loadReady = _player.stream.seekCompleted
          .firstWhere((_) => _seekGeneration == loadGen)
          .timeout(const Duration(seconds: 15));
      await _player.open(Media(track.uri), play: false);
      await _applyMediaSessionForTrack(track);
      await loadReady;
      developer.log(
        'openAndSeekTo loadReady loadGen=$loadGen',
        name: kRecitationSeekLogName,
      );

      if (start != null && start > Duration.zero) {
        final seekGen = ++_seekGeneration;
        developer.log(
          'openAndSeekTo start seek targetMs=${start.inMilliseconds} '
          'seekGen=$seekGen',
          name: kRecitationSeekLogName,
        );
        final seekLanding = _player.stream.seekCompleted
            .firstWhere((_) => _seekGeneration == seekGen)
            .timeout(const Duration(seconds: 15));
        await _player.seek(start);
        await seekLanding;
        developer.log(
          'openAndSeekTo seekCompleted seekGen=$seekGen',
          name: kRecitationSeekLogName,
        );
      }
      if (fadeIn > Duration.zero) {
        unawaited(_fadeVolume(from: 0, to: _targetVolume, duration: fadeIn));
      }
      await _player.play();
      developer.log('openAndSeekTo play', name: kRecitationSeekLogName);
      _emitState();
    } on Object catch (error) {
      developer.log(
        'openAndSeekTo failed loadGen=$loadGen: $error',
        name: kRecitationSeekLogName,
      );
      _activeTrack = null;
      _trackCompleted = false;
      _cancelFade();
      _emit(PlaybackError(track: track, message: error.toString()));
    }
  }

  /// Seeks to [position] in the currently loaded track.
  ///
  /// Returns `false` when nothing is loaded or another owner holds the lease.
  /// Re-acquires an idle lease when a track is still loaded (e.g. after the
  /// unattended watchdog released ownership during continuous play).
  /// Prefer this over [PlayerApi.seek] so callers avoid mpv errors during file
  /// reloads (e.g. reciter switches).
  Future<bool> seek(Duration position, {String? owner}) async {
    if (_activeTrack == null) {
      developer.log(
        'seek reject reason=noTrack',
        name: kRecitationSeekLogName,
      );
      return false;
    }

    final effectiveOwner = owner ?? _leases.currentOwner;
    if (effectiveOwner == null) {
      developer.log(
        'seek reject reason=noOwner',
        name: kRecitationSeekLogName,
      );
      return false;
    }

    if (!_leases.hasValidLease(effectiveOwner)) {
      final holder = _leases.currentOwner;
      if (holder != null && holder != effectiveOwner) {
        developer.log(
          'seek reject reason=leaseHeldBy other=$holder requested=$effectiveOwner',
          name: kRecitationSeekLogName,
        );
        return false;
      }
      developer.log(
        'seek reacquire owner=$effectiveOwner',
        name: kRecitationSeekLogName,
      );
      await acquire(owner: effectiveOwner);
    }

    final seekGen = ++_seekGeneration;
    developer.log(
      'seek begin targetMs=${position.inMilliseconds} seekGen=$seekGen',
      name: kRecitationSeekLogName,
    );
    try {
      final seekLanding = _player.stream.seekCompleted
          .firstWhere((_) => _seekGeneration == seekGen)
          .timeout(const Duration(seconds: 15));
      await _player.seek(position, exact: true);
      await seekLanding;
      developer.log(
        'seekCompleted landed targetMs=${position.inMilliseconds} '
        'seekGen=$seekGen',
        name: kRecitationSeekLogName,
      );
      _emitState();
      return true;
    } on Object catch (error) {
      developer.log(
        'seek failed/timeout targetMs=${position.inMilliseconds} '
        'seekGen=$seekGen: $error',
        name: kRecitationSeekLogName,
      );
      return false;
    }
  }

  /// Pauses playback when [owner] holds the lease (or [force] is true).
  ///
  /// Returns `false` when [owner] is omitted/wrong and [force] is false.
  Future<bool> pause({String? owner, bool force = false}) async {
    if (!_mayControlTransport(owner: owner, force: force)) return false;
    await _player.pause();
    _emitState();
    return true;
  }

  /// Resumes playback when [owner] holds the lease (or [force] is true).
  ///
  /// Returns `false` when [owner] is omitted/wrong and [force] is false.
  Future<bool> resume({String? owner, bool force = false}) async {
    if (!_mayControlTransport(owner: owner, force: force)) return false;
    await _player.play();
    _trackCompleted = false;
    _emitState();
    return true;
  }

  /// True when [owner]/[force] may drive pause/resume/stop transport.
  ///
  /// Fail closed: an omitted [owner] never impersonates the current holder.
  /// Only [force] or a matching lease owner may control transport.
  bool _mayControlTransport({String? owner, bool force = false}) {
    if (force) return true;
    if (owner == null) return false;
    return _leases.hasValidLease(owner);
  }

  Future<void> stop({
    Duration fadeOut = Duration.zero,
    String? owner,
    bool force = false,
  }) async {
    if (!_mayControlTransport(owner: owner, force: force)) {
      return; // ignore stop from non-owner
    }
    _cancelFade();
    if (fadeOut > Duration.zero && _activeTrack != null) {
      await _fadeVolume(from: _actualVolume, to: 0, duration: fadeOut);
    }
    await _unloadEngine(releaseLease: true);
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
    if (_activeFade == null) {
      _actualVolume = _targetVolume;
      await _player.setVolume(_targetVolume);
    }
  }

  /// Ramps the player volume from [from] to [to] over [duration].
  ///
  /// Cancel always settles the returned Future (via [_cancelFade]) so callers
  /// that `await` a fade never hang when a superseding play/stop/error cancels.
  Future<void> _fadeVolume({
    required double from,
    required double to,
    required Duration duration,
  }) async {
    _cancelFade();
    final start = from.clamp(0, 100).toDouble();
    final end = to.clamp(0, 100).toDouble();
    _actualVolume = start;
    await _player.setVolume(start);
    if (duration <= Duration.zero || start == end) {
      _actualVolume = end;
      await _player.setVolume(end);
      return;
    }
    final steps = (duration.inMilliseconds / _fadeStep.inMilliseconds).ceil();
    final delta = (end - start) / steps;
    final done = Completer<void>();
    var i = 0;
    final timer = Timer.periodic(_fadeStep, (timer) {
      i++;
      final value = i >= steps ? end : start + delta * i;
      _actualVolume = value.clamp(0, 100).toDouble();
      unawaited(_player.setVolume(_actualVolume));
      if (i >= steps) {
        timer.cancel();
        final active = _activeFade;
        _activeFade = null;
        if (active != null && !active.done.isCompleted) {
          active.done.complete();
        }
      }
    });
    _activeFade = _ActiveFade(timer: timer, done: done);
    await done.future;
  }

  /// Cancels any in-flight fade and always settles its Completer.
  void _cancelFade() {
    final active = _activeFade;
    if (active == null) return;
    _activeFade = null;
    active.timer.cancel();
    if (!active.done.isCompleted) {
      active.done.complete();
    }
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
  Future<void> setAbLoopCount(int? count) => _player.setAbLoopCount(count);

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
  /// Clears published media-session metadata so a subsequent owner (e.g. adhan)
  /// does not inherit surah/reciter identity from a prior recitation session.
  /// Idempotent: safe to call when the lease is idle or held by another
  /// owner.
  Future<void> release({required String owner}) async {
    if (!_leases.hasValidLease(owner)) return;
    _publishedMetadata = null;
    _stopLeaseKeepAliveTimer();
    await _player.setMediaSession(null);
    _leases.releaseCurrent();
    _leaseOwnerController.add(null);
  }

  /// Releases native handles. Called on app shutdown. Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cancelFade();
    _stopLeaseKeepAliveTimer();
    await _leases.dispose();
    await _volumeController.close();
    await _leaseOwnerController.close();
    await _completionController.close();
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
  /// forces a release. Pass [force] to steal immediately: the prior session is
  /// stopped (no fade) then ownership transfers — callers need not race a
  /// separate suspend ritual for correctness.
  Future<AudioLease> acquire({
    required String owner,
    bool force = false,
  }) async {
    if (force) {
      final holder = _leases.currentOwner;
      if (holder != null && holder != owner) {
        await _unloadEngine(releaseLease: true);
      }
    }
    final lease = await _leases.acquire(owner: owner, force: force);
    _leaseOwnerController.add(owner);
    return lease;
  }

  /// Unloads the loaded track and optionally releases the lease.
  Future<void> _unloadEngine({required bool releaseLease}) async {
    _cancelFade();
    _activeTrack = null;
    _trackCompleted = false;
    _publishedMetadata = null;
    _stopLeaseKeepAliveTimer();
    await _clearWatchLater();
    await clearAbLoop();
    await resetPlaybackModes();
    await _player.stop();
    await _player.setMediaSession(null);
    _actualVolume = _targetVolume;
    await _player.setVolume(_targetVolume);
    _emit(const PlaybackIdle());
    if (releaseLease) {
      _leases.releaseCurrent();
      _leaseOwnerController.add(null);
    }
  }

  /// Watchdog path: clear engine state after the registry already released.
  Future<void> _clearEngineAfterWatchdog() async {
    _cancelFade();
    _activeTrack = null;
    _trackCompleted = false;
    _publishedMetadata = null;
    _stopLeaseKeepAliveTimer();
    try {
      await _clearWatchLater();
      await clearAbLoop();
      await resetPlaybackModes();
      await _player.stop();
      await _player.setMediaSession(null);
      _actualVolume = _targetVolume;
      await _player.setVolume(_targetVolume);
    } on Object catch (error) {
      developer.log(
        'Watchdog engine clear failed: $error',
        name: 'tawaq.audio',
      );
    }
    _emit(const PlaybackIdle());
  }
}

/// In-flight volume ramp. Cancel must always complete [done].
final class _ActiveFade {
  new({required this.timer, required this.done});

  final Timer timer;
  final Completer<void> done;
}

/// Interval between volume steps while fading.
const _fadeStep = Duration(milliseconds: 40);
