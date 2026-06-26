import 'dart:async';

import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Reports a non-fatal error from the alert pipeline.
typedef AlertErrorSink =
    void Function(String message, Object error, StackTrace stack);

/// Coordinates prayer alert delivery across a set of [PrayerAlertChannel]s.
///
/// This is plugin-agnostic on purpose — it depends only on the channel
/// interface and a playback state [Stream] — so it can be unit-tested with
/// fakes. The Riverpod notifier wires the concrete channels (audio, window,
/// OS notification) into it.
///
/// Guarantees:
/// - **serialized**: deliveries run one at a time, so overlapping crossings
///   never interleave audio and UI from different alerts;
/// - **preemptive**: a new event tears the in-flight alert down before showing;
/// - **self-finishing**: when the sound ends/errors (or the safety cap fires,
///   or a notify-only alert times out) every channel is cancelled together.
class PrayerAlertCoordinator {
  /// Creates a [PrayerAlertCoordinator].
  PrayerAlertCoordinator({
    required this._channels,
    required this._playbackStream,
    this._onError,
    this.notifyOnlyTimeout = const Duration(seconds: 30),
    this.soundSafetyCap = const Duration(minutes: 6),
  });

  final List<PrayerAlertChannel> _channels;
  final Stream<PlaybackState> _playbackStream;
  final AlertErrorSink? _onError;

  /// Auto-dismiss delay for notify-only (silent) alerts.
  final Duration notifyOnlyTimeout;

  /// Hard ceiling guarding against a stuck/never-completing sound.
  final Duration soundSafetyCap;

  Future<void> _queue = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;
  Timer? _finishTimer;
  StreamSubscription<PlaybackState>? _playbackSub;

  /// Enqueues [event] for delivery. The returned future completes once delivery
  /// setup finishes; completion/dismissal happen asynchronously afterwards.
  Future<void> dispatch(PrayerAlertEvent event) {
    if (!event.hasAnyEffect) return Future<void>.value();
    return _enqueue(() => _deliver(event));
  }

  /// Dismisses the currently active alert.
  Future<void> dismiss() => _enqueue(() => _finish(_generation));

  /// Cancels timers, playback, and every channel. Call on shutdown.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _finishTimer?.cancel();
    _finishTimer = null;
    await _playbackSub?.cancel();
    _playbackSub = null;
    await _teardown();
    _queue = Future<void>.value();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    if (_disposed) return Future<void>.value();
    return _queue = _queue.then((_) {
      if (_disposed) return Future<void>.value();
      return action();
    }).catchError(
      (Object error, StackTrace stack) =>
          _onError?.call('Prayer alert pipeline error', error, stack),
    );
  }

  Future<void> _deliver(PrayerAlertEvent event) async {
    if (_disposed) return;
    final generation = ++_generation;
    await _teardown();
    if (_disposed || generation != _generation) return;

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

  /// Auto-finishes when playback ends, errors, or exceeds the safety cap.
  void _watchPlaybackCompletion(int generation) {
    if (_disposed || generation != _generation) return;
    var started = false;
    _playbackSub = _playbackStream.listen((playback) {
      if (_disposed || generation != _generation) return;
      if (playback is PlaybackPlaying) started = true;
      if (playback is PlaybackError || (playback is PlaybackIdle && started)) {
        _scheduleFinish(generation);
      }
    });
    _finishTimer = Timer(soundSafetyCap, () => _scheduleFinish(generation));
  }

  void _scheduleFinish(int generation) {
    if (_disposed || generation != _generation) return;
    unawaited(_enqueue(() => _finish(generation)));
  }

  Future<void> _finish(int generation) async {
    if (_disposed || generation != _generation) return;
    await _teardown();
    if (_disposed || generation != _generation) return;
  }

  /// Cancels the active timers, the playback listener, and every channel.
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
