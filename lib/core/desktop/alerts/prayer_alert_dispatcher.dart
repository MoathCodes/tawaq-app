import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/alerts/os_notification_channel.dart';
import 'package:tawaq/core/desktop/alerts/sound_alert_channel.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';

part 'prayer_alert_dispatcher.g.dart';

/// Reports a non-fatal error from the alert pipeline.
typedef AlertErrorSink =
    void Function(String message, Object error, StackTrace stack);

typedef _AlertFlight = ({PrayerAlertKind kind, String prayer});

/// Active prayer for an in-flight desktop alert, or `null` when idle.
///
/// Used by the tray Stop row and “happening now” status text.
@Riverpod(keepAlive: true)
class PrayerAlertActive extends _$PrayerAlertActive {
  @override
  Prayer? build() => null;

  /// Sets the active alert prayer, or clears it with `null`.
  // ignore: use_setters_to_change_properties
  void setActive(Prayer? prayer) => state = prayer;
}

/// Coordinates prayer alert delivery across a set of [PrayerAlertChannel]s.
class PrayerAlertCoordinator {
  PrayerAlertCoordinator({
    required this._channels,
    required this._playbackStream,
    required this._soundSafetyCap,
    this._currentPlayback,
    this._onError,
    this.onFinished,
    this.onActiveChanged,
    this.notifyOnlyTimeout = const Duration(seconds: 30),
  });

  final List<PrayerAlertChannel> _channels;
  final Stream<PlaybackState> _playbackStream;
  final PlaybackState Function()? _currentPlayback;
  final AlertErrorSink? _onError;
  final void Function()? onFinished;
  /// Fired with the active prayer when an alert starts, or `null` when idle.
  final void Function(Prayer? prayer)? onActiveChanged;
  final Duration notifyOnlyTimeout;
  Duration _soundSafetyCap;
  final Set<_AlertFlight> _inFlight = {};

  /// Whether an alert is currently in flight.
  bool get isActive => _inFlight.isNotEmpty;

  /// Updates the in-flight sound safety timeout without rebuilding the
  /// coordinator.
  // ignore: use_setters_to_change_properties
  void updateSoundSafetyCap(Duration value) => _soundSafetyCap = value;

  Future<void> _queue = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;
  Timer? _finishTimer;
  StreamSubscription<PlaybackState>? _playbackSub;
  /// Iqamah deferred while the same prayer's adhan is still in flight.
  PrayerAlertEvent? _pendingIqamah;

  void _emitActive(Prayer? prayer) {
    if (_disposed) return;
    onActiveChanged?.call(prayer);
  }

  Future<void> dispatch(PrayerAlertEvent event) {
    if (!event.hasAnyEffect) return Future<void>.value();
    return _enqueue(() => _deliver(event));
  }

  Future<void> dismiss() => _enqueue(() => _finish(_generation));

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _pendingIqamah = null;
    _finishTimer?.cancel();
    _finishTimer = null;
    await _playbackSub?.cancel();
    _playbackSub = null;
    await _teardown();
    _inFlight.clear();
    onActiveChanged?.call(null);
    _queue = Future<void>.value();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    if (_disposed) return Future<void>.value();
    return _queue = _queue.then((_) {
      if (_disposed) return Future<void>.value();
      return action();
    }).catchError((Object error, StackTrace stack) async {
      _onError?.call('Prayer alert pipeline error', error, stack);
      // Fail closed: tear down the in-flight alert so a broken channel cannot
      // leave the dialog / sound armed indefinitely.
      await _failClosed();
    });
  }

  Future<void> _failClosed() async {
    if (_disposed) return;
    ++_generation;
    _pendingIqamah = null;
    await _teardown();
    _inFlight.clear();
    _emitActive(null);
  }

  Future<void> _deliver(PrayerAlertEvent event) async {
    if (_disposed) return;

    final prayerKey = event.prayer.name;
    if (event.kind == PrayerAlertKind.iqamah &&
        _inFlight.any(
          (flight) => flight.kind == PrayerAlertKind.adhan &&
              flight.prayer == prayerKey,
        )) {
      // Scheduler already deduped this fire key — hold it until adhan ends
      // so the iqamah is not silently dropped for the rest of the day.
      _pendingIqamah = event;
      return;
    }

    final generation = ++_generation;
    await _teardown();
    _inFlight.clear();
    if (_disposed || generation != _generation) return;

    _inFlight.add((kind: event.kind, prayer: prayerKey));
    _emitActive(event.prayer);

    for (final channel in _channels) {
      if (_disposed || generation != _generation) {
        await _teardown();
        return;
      }
      try {
        await channel.deliver(event);
      } on Object catch (error, stack) {
        _onError?.call(
          'Channel ${channel.debugName} failed for ${event.slug}',
          error,
          stack,
        );
      }
      if (_disposed || generation != _generation) {
        await _teardown();
        return;
      }
    }

    if (_disposed || generation != _generation) {
      await _teardown();
      return;
    }

    if (event.playSound) {
      _watchPlaybackCompletion(generation);
    } else {
      _finishTimer = Timer(
        notifyOnlyTimeout,
        () => _scheduleFinish(generation),
      );
    }
  }

  void _watchPlaybackCompletion(int generation) {
    if (_disposed || generation != _generation) return;
    final initial = _currentPlayback?.call() ?? const PlaybackIdle();
    var sawPlaying = initial is PlaybackPlaying;
    _playbackSub = _playbackStream.listen((playback) {
      if (_disposed || generation != _generation) return;

      if (playback is PlaybackPlaying) {
        sawPlaying = true;
        return;
      }
      if (playback is PlaybackLoading || playback is PlaybackBuffering) {
        return;
      }
      if (playback is PlaybackError) {
        _scheduleFinish(generation);
        return;
      }
      if (playback is PlaybackCompleted && sawPlaying) {
        _scheduleFinish(generation);
        return;
      }
      if (playback is PlaybackIdle && sawPlaying) {
        _scheduleFinish(generation);
      }
    });
    _finishTimer = Timer(
      _soundSafetyCap,
      () => _scheduleFinish(generation),
    );
  }

  void _scheduleFinish(int generation) {
    if (_disposed || generation != _generation) return;
    unawaited(_enqueue(() => _finish(generation)));
  }

  Future<void> _finish(int generation) async {
    if (_disposed || generation != _generation) return;
    await _teardown();
    _inFlight.clear();
    _emitActive(null);
    if (_disposed || generation != _generation) return;
    onFinished?.call();

    final pending = _pendingIqamah;
    _pendingIqamah = null;
    if (pending != null && !_disposed) {
      await _deliver(pending);
    }
  }

  Future<void> _teardown() async {
    _finishTimer?.cancel();
    _finishTimer = null;
    await _playbackSub?.cancel();
    _playbackSub = null;

    for (final channel in _channels.reversed) {
      try {
        await channel.cancel();
      } on Object catch (error, stack) {
        _onError?.call(
          'Channel ${channel.debugName} failed to cancel',
          error,
          stack,
        );
      }
    }
  }
}

/// Wires desktop alert channels and exposes delivery to the scheduler and UI.
@Riverpod(keepAlive: true)
class PrayerAlertDispatcher extends _$PrayerAlertDispatcher {
  late final PrayerAlertCoordinator _coordinator;

  @override
  PrayerAlertCoordinator build() {
    final inApp = ref.watch(adhanAlertControllerProvider.notifier);
    final recitation = ref.read(recitationControllerProvider.notifier);
    final service = ref.read(tawaqAudioServiceProvider);
    final sound = SoundAlertChannel(
      adhanPlayer: ref.read(audioPlayerControllerProvider.notifier),
      onCaptureRecitationVolume: () async => service.volume,
      onSuspend: recitation.suspendForAlert,
      onRestoreRecitationVolume: service.setVolume,
      onResume: recitation.resumeAfterAlert,
    );
    final os = OsNotificationChannel(
      onClick: inApp.focusAlert,
      onStop: () => _coordinator.dismiss(),
    );
    final log = ref.read(loggerProvider);

    final soundSafetyCap =
        ref.read(adhanSettingsProvider).value?.soundSafetyCap ??
        const Duration(minutes: 8);

    _coordinator = PrayerAlertCoordinator(
      channels: [os, inApp, sound],
      playbackStream: ref.read(tawaqAudioServiceProvider).stateStream,
      currentPlayback: () => service.state,
      onError: (message, error, stack) =>
          log.e(message, error: error, stackTrace: stack),
      soundSafetyCap: soundSafetyCap,
      onActiveChanged: (prayer) {
        ref.read(prayerAlertActiveProvider.notifier).setActive(prayer);
      },
    );

    // Update the cap in place so unrelated adhan setting edits do not dispose
    // the coordinator mid-alert (Riverpod select + listen).
    ref.listen(
      adhanSettingsProvider.select((s) => s.value?.soundSafetyCap),
      (previous, next) {
        if (next != null) _coordinator.updateSoundSafetyCap(next);
      },
    );

    ref.onDispose(() {
      unawaited(_coordinator.dispose());
    });
    return _coordinator;
  }

  Future<void> dispatch(PrayerAlertEvent event) {
    if (!isDesktopPlatform) return Future<void>.value();
    return state.dispatch(event);
  }

  Future<void> dismiss() => state.dismiss();

  Future<void> forceShutdown() => state.dispose();
}
