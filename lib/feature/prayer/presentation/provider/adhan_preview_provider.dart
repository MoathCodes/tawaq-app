import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_interruption.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';

part 'adhan_preview_provider.g.dart';

/// Preview playback status for a candidate prayer sound.
enum AdhanPreviewStatus {
  /// Nothing previewing.
  idle,

  /// Opening the bundled asset.
  loading,

  /// Candidate sound is audible.
  playing,

  /// Last preview failed; retry is available.
  error,
}

/// Single shared preview slot for candidate Adhan/Iqamah sounds.
class AdhanPreviewState {
  /// Creates a preview state.
  const new({
    this.status = AdhanPreviewStatus.idle,
    this.adhanSound,
    this.iqamahSound,
    this.error,
  });

  /// Current preview status.
  final AdhanPreviewStatus status;

  /// Candidate adhan sound when one is previewing, else null.
  final AdhanSound? adhanSound;

  /// Candidate iqamah sound when one is previewing, else null.
  final IqamahSound? iqamahSound;

  /// Last preview failure, if any.
  final String? error;

  /// Whether [sound] is the active preview target.
  bool isActiveAdhan(AdhanSound sound) =>
      (status == AdhanPreviewStatus.loading ||
          status == AdhanPreviewStatus.playing) &&
      adhanSound == sound;

  /// Whether [sound] is the active preview target.
  bool isActiveIqamah(IqamahSound sound) =>
      (status == AdhanPreviewStatus.loading ||
          status == AdhanPreviewStatus.playing) &&
      iqamahSound == sound;

  /// Copies with replaced fields.
  AdhanPreviewState copyWith({
    AdhanPreviewStatus? status,
    AdhanSound? Function()? adhanSound,
    IqamahSound? Function()? iqamahSound,
    String? Function()? error,
  }) => AdhanPreviewState(
    status: status ?? this.status,
    adhanSound: adhanSound != null ? adhanSound() : this.adhanSound,
    iqamahSound: iqamahSound != null ? iqamahSound() : this.iqamahSound,
    error: error != null ? error() : this.error,
  );
}

/// Plays a candidate Adhan/Iqamah sound without scheduling an alert or
/// changing the saved choice.
///
/// Previewing uses the same suspend/resume boundary as a real prayer alert.
/// The provider owns one preview slot, but never owns the audio engine after a
/// different track has taken it over.
@riverpod
class AdhanPreview extends _$AdhanPreview {
  static const _trackIdPrefix = 'preview-prayer-sound';

  late final AdhanAudioController _player;
  TawaqAudioService? _audioService;
  late final AudioInterruptionCoordinator _interruption;
  AudioInterruptionRegistration? _previewRegistration;

  /// Whether the engine is currently held by our preview track.
  bool _ownsEngine = false;
  String? _activeTrackId;

  /// Set once per preview run and cleared only by the matching teardown.
  bool _recitationSuspended = false;
  double? _capturedVolume;

  /// Serializes start/stop commands while state updates remain immediate.
  Future<void> _commandTail = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;
  AudioSessionSnapshot _lastSession = const AudioSessionSnapshot();

  @override
  AdhanPreviewState build() {
    _player = ref.read(adhanAudioControllerProvider.notifier);
    _interruption = ref.read(audioInterruptionCoordinatorProvider);
    _previewRegistration = _interruption.registerPreview(_settleForAlert);
    ref.onDispose(() {
      _previewRegistration?.dispose();
      _disposed = true;
      unawaited(_disposePreview());
    });
    ref.listen(audioSessionProvider, (previous, next) {
      _lastSession = next;
      _onSessionChanged(next);
    });
    return const AdhanPreviewState();
  }

  /// Previews [sound] at [volume]; tapping the active target stops it.
  Future<void> previewAdhan(
    AdhanSound sound, {
    required String label,
    required double volume,
  }) => _preview(
    state: AdhanPreviewState(
      status: AdhanPreviewStatus.loading,
      adhanSound: sound,
    ),
    // Fajr shares one recording across muezzins, so preview a fard prayer
    // to hear the candidate muezzin's own voice.
    assetPath: sound.assetPathFor(Prayer.dhuhr),
    title: label,
    volume: volume,
  );

  /// Previews [sound] at [volume]; tapping the active target stops it.
  Future<void> previewIqamah(
    IqamahSound sound, {
    required String label,
    required double volume,
  }) => _preview(
    state: AdhanPreviewState(
      status: AdhanPreviewStatus.loading,
      iqamahSound: sound,
    ),
    assetPath: sound.assetPathFor(Prayer.dhuhr),
    title: label,
    volume: volume,
  );

  Future<void> _preview({
    required AdhanPreviewState state,
    required String assetPath,
    required String title,
    required double volume,
  }) async {
    final current = this.state;
    final trackId = state._trackId!;
    final isSameTarget =
        current._trackId != null && current._trackId == trackId;
    final generation = ++_generation;
    if (isSameTarget &&
        (current.status == AdhanPreviewStatus.loading ||
            current.status == AdhanPreviewStatus.playing)) {
      this.state = const AdhanPreviewState();
      await _enqueue(() => _stopOwnedTrack(restore: true));
      return;
    }
    this.state = state;
    await _enqueue(
      () => _startPreview(
        generation: generation,
        trackId: trackId,
        assetPath: assetPath,
        title: title,
        volume: volume,
      ),
    );
  }

  /// Stops the active preview and restores any suspended recitation.
  Future<void> stop() async {
    ++_generation;
    state = const AdhanPreviewState();
    await _enqueue(() => _stopOwnedTrack(restore: true));
  }

  Future<void> _startPreview({
    required int generation,
    required String trackId,
    required String assetPath,
    required String title,
    required double volume,
  }) async {
    if (_disposed || generation != _generation) return;

    try {
      if (_ownsEngine && _activeTrackId != trackId) {
        await _stopOwnedTrack(restore: false);
      }
      await _suspendRecitation();
      if (_disposed || generation != _generation) return;

      _activeTrackId = trackId;
      await _player.setVolume(volume);
      if (_disposed || generation != _generation) return;

      // Set ownership before the async transport call. The native session can
      // emit `playing` before playTrack resolves.
      _ownsEngine = true;
      await _player.playTrack(
        AudioTrack.asset(id: trackId, title: title, assetPath: assetPath),
      );

      if (_disposed || generation != _generation) {
        await _stopOwnedTrack(restore: false, expectedTrackId: trackId);
        return;
      }
      if (state._trackId == trackId &&
          state.status == AdhanPreviewStatus.loading) {
        state = state.copyWith(
          status: AdhanPreviewStatus.playing,
          error: () => null,
        );
      }
    } on Object catch (error) {
      if (_disposed || generation != _generation) return;
      if (state._trackId != trackId) return;
      state = state.copyWith(
        status: AdhanPreviewStatus.error,
        error: () => '$error',
      );
      await _finishOwnedTrack(restore: true, expectedTrackId: trackId);
    }
  }

  Future<void> _suspendRecitation() async {
    if (_recitationSuspended) return;
    _capturedVolume = _service.volume;
    try {
      await _interruption.suspendRecitation();
      _recitationSuspended = true;
    } on Object {
      _capturedVolume = null;
      rethrow;
    }
  }

  TawaqAudioService get _service {
    _audioService ??= ref.read(tawaqAudioServiceProvider);
    return _audioService!;
  }

  Future<void> _stopOwnedTrack({
    required bool restore,
    String? expectedTrackId,
  }) => _finishOwnedTrack(
    restore: restore,
    expectedTrackId: expectedTrackId,
  );

  Future<void> _finishOwnedTrack({
    required bool restore,
    String? expectedTrackId,
  }) async {
    final trackId = expectedTrackId ?? _activeTrackId;
    final ownsEngine =
        _ownsEngine &&
        (expectedTrackId == null || _activeTrackId == expectedTrackId);
    if (!ownsEngine) {
      if (restore) await _restoreRecitation();
      return;
    }

    _ownsEngine = false;
    if (_activeTrackId == trackId) _activeTrackId = null;

    final session = _lastSession;
    final stillOurTrack =
        trackId == null ||
        session.track == null ||
        session.track?.id == trackId;
    if (stillOurTrack) {
      await _player.stop();
    } else {
      // A real alert/another owner has taken the engine. Its teardown owns
      // volume restoration and recitation resume.
      _discardRecitationSuspension();
      return;
    }
    if (restore) await _restoreRecitation();
  }

  Future<void> _restoreRecitation() async {
    if (!_recitationSuspended) return;
    _recitationSuspended = false;
    final volume = _capturedVolume;
    _capturedVolume = null;
    try {
      final audioService = _audioService;
      if (volume != null && audioService != null) {
        await audioService.setVolume(volume);
      }
    } finally {
      await _interruption.resumeRecitation();
    }
  }

  Future<void> _settleForAlert() => stop();

  void _discardRecitationSuspension() {
    _recitationSuspended = false;
    _capturedVolume = null;
  }

  void _onSessionChanged(AudioSessionSnapshot next) {
    final trackId = _activeTrackId;
    if (_disposed || trackId == null || !_ownsEngine) return;

    if (next.track?.id != trackId) {
      final hasOtherTrack = next.track != null;
      _ownsEngine = false;
      _activeTrackId = null;
      ++_generation;
      state = const AdhanPreviewState();
      if (hasOtherTrack) {
        _discardRecitationSuspension();
      } else {
        unawaited(_restoreRecitation());
      }
      return;
    }

    switch (next.lifecycle) {
      case AudioSessionLifecycle.loading:
      case AudioSessionLifecycle.buffering:
        return;
      case AudioSessionLifecycle.playing:
        if (state.status == AdhanPreviewStatus.loading) {
          state = state.copyWith(
            status: AdhanPreviewStatus.playing,
            error: () => null,
          );
        }
      case AudioSessionLifecycle.completed:
        state = const AdhanPreviewState();
        unawaited(_finishOwnedTrack(restore: true, expectedTrackId: trackId));
      case AudioSessionLifecycle.error:
        state = state.copyWith(
          status: AdhanPreviewStatus.error,
          error: () => next.error,
        );
        unawaited(_finishOwnedTrack(restore: true, expectedTrackId: trackId));
      case AudioSessionLifecycle.paused:
      case AudioSessionLifecycle.idle:
        return;
    }
  }

  Future<void> _disposePreview() async {
    ++_generation;
    final trackId = _activeTrackId;
    if (!_ownsEngine || trackId == null) {
      if (_recitationSuspended) {
        await _restoreRecitation();
      } else {
        _discardRecitationSuspension();
      }
      return;
    }
    _ownsEngine = false;
    _activeTrackId = null;
    final session = _lastSession;
    if (session.track != null && session.track?.id != trackId) {
      _discardRecitationSuspension();
      return;
    }
    await _player.stop();
    await _restoreRecitation();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final previous = _commandTail;
    final result = previous.then((_) => action());
    _commandTail = result.catchError((_) {});
    return result;
  }
}

extension on AdhanPreviewState {
  String? get _trackId {
    final adhan = adhanSound;
    if (adhan != null) {
      return '${AdhanPreview._trackIdPrefix}-adhan-${adhan.name}';
    }
    final iqamah = iqamahSound;
    if (iqamah != null) {
      return '${AdhanPreview._trackIdPrefix}-iqamah-${iqamah.name}';
    }
    return null;
  }
}
