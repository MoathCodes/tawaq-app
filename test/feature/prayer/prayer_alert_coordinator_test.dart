import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_coordinator.dart';

/// Records deliver/cancel calls. `cancel` is a no-op when idle, mirroring the
/// real channels.
class _FakeChannel implements PrayerAlertChannel {
  _FakeChannel(this.debugName, this.log);

  @override
  final String debugName;
  final List<String> log;

  bool _active = false;
  int delivered = 0;
  int cancelled = 0;

  bool get isActive => _active;

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    delivered++;
    _active = true;
    log.add('deliver:$debugName');
  }

  @override
  Future<void> cancel() async {
    if (!_active) return;
    _active = false;
    cancelled++;
    log.add('cancel:$debugName');
  }
}

/// Blocks [deliver] until [release] is called — for queue/dispose races.
class _BlockingChannel implements PrayerAlertChannel {
  _BlockingChannel(this.debugName, this.log);

  @override
  final String debugName;
  final List<String> log;

  final _deliverGate = Completer<void>();
  int delivered = 0;
  int cancelled = 0;

  void release() {
    if (!_deliverGate.isCompleted) _deliverGate.complete();
  }

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    delivered++;
    log.add('deliver:$debugName');
    await _deliverGate.future;
  }

  @override
  Future<void> cancel() async {
    cancelled++;
    log.add('cancel:$debugName');
    release();
  }
}

final _track = AudioTrack.asset(
  id: 'x',
  title: 'x',
  assetPath: 'assets/audio/adhan/x.mp3',
);

PlaybackState get _playing => PlaybackPlaying(
  track: _track,
  position: Duration.zero,
  duration: const Duration(minutes: 2),
);

PrayerAlertEvent _event({
  required bool playSound,
  PrayerAlertKind kind = PrayerAlertKind.adhan,
}) {
  return PrayerAlertEvent(
    kind: kind,
    prayer: Prayer.fajr,
    scheduledTime: DateTime(2026, 6, 9, 5, 30),
    playSound: playSound,
    showInApp: true,
    showOsNotification: true,
    volume: 80,
    soundAssetPath: playSound ? 'assets/audio/adhan/x.mp3' : null,
  );
}

void main() {
  group('PrayerAlertCoordinator', () {
    late StreamController<PlaybackState> playback;
    late List<String> log;
    late _FakeChannel channel;
    late PrayerAlertCoordinator coordinator;

    setUp(() {
      playback = StreamController<PlaybackState>.broadcast();
      log = [];
      channel = _FakeChannel('a', log);
      coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: playback.stream,
        notifyOnlyTimeout: const Duration(milliseconds: 20),
        soundSafetyCap: const Duration(seconds: 5),
      );
    });

    tearDown(() async {
      await coordinator.dispose();
      await playback.close();
    });

    test('delivers, then cancels when playback completes', () async {
      await coordinator.dispatch(_event(playSound: true));
      expect(channel.delivered, 1);
      expect(channel.cancelled, 0);

      playback
        ..add(_playing)
        ..add(const PlaybackIdle());
      await pumpEventQueue();

      expect(channel.cancelled, 1);
    });

    test('cancels when playback errors', () async {
      await coordinator.dispatch(_event(playSound: true));
      playback
        ..add(_playing)
        ..add(const PlaybackError(track: null, message: 'boom'));
      await pumpEventQueue();

      expect(channel.cancelled, 1);
    });

    test('ignores an idle emitted before playback started', () async {
      await coordinator.dispatch(_event(playSound: true));
      playback.add(const PlaybackIdle());
      await pumpEventQueue();

      expect(channel.cancelled, 0);
    });

    test('a new event preempts the in-flight alert', () async {
      await coordinator.dispatch(_event(playSound: true));
      expect(channel.delivered, 1);

      await coordinator.dispatch(
        _event(playSound: true, kind: PrayerAlertKind.iqamah),
      );

      expect(channel.delivered, 2);
      expect(channel.cancelled, 1);
      // The first alert is torn down before the second is shown.
      expect(log, ['deliver:a', 'cancel:a', 'deliver:a']);
    });

    test('notify-only alert auto-dismisses after the timeout', () async {
      await coordinator.dispatch(_event(playSound: false));
      expect(channel.delivered, 1);
      expect(channel.cancelled, 0);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await pumpEventQueue();

      expect(channel.cancelled, 1);
    });

    test('dismiss tears the active alert down', () async {
      await coordinator.dispatch(_event(playSound: true));
      await coordinator.dismiss();
      await pumpEventQueue();

      expect(channel.cancelled, 1);
    });

    test('dispose mid-alert tears down active channels', () async {
      await coordinator.dispatch(_event(playSound: true));
      expect(channel.delivered, 1);
      expect(channel.isActive, isTrue);
      expect(channel.cancelled, 0);

      await coordinator.dispose();

      expect(channel.cancelled, 1);
      expect(channel.isActive, isFalse);
    });

    test('dispose during queued dispatch does not deliver queued work', () async {
      final blocking = _BlockingChannel('block', log);
      final localCoordinator = PrayerAlertCoordinator(
        channels: [blocking],
        playbackStream: playback.stream,
        notifyOnlyTimeout: const Duration(milliseconds: 20),
      );

      unawaited(localCoordinator.dispatch(_event(playSound: false)));
      await pumpEventQueue();
      expect(blocking.delivered, 1);

      unawaited(localCoordinator.dispatch(_event(playSound: false)));
      await localCoordinator.dispose();

      blocking.release();
      await pumpEventQueue();

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await pumpEventQueue();

      expect(blocking.delivered, 1);
      expect(blocking.cancelled, greaterThanOrEqualTo(1));
    });

    test('dispose does not re-arm finish timers', () async {
      await coordinator.dispatch(_event(playSound: false));
      expect(channel.delivered, 1);

      await coordinator.dispose();
      expect(channel.cancelled, 1);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await pumpEventQueue();

      expect(channel.cancelled, 1);
    });

    test('enqueue after dispose is a no-op', () async {
      await coordinator.dispatch(_event(playSound: true));
      expect(channel.delivered, 1);

      await coordinator.dispose();

      await coordinator.dispatch(_event(playSound: true));
      await coordinator.dismiss();
      await pumpEventQueue();

      expect(channel.delivered, 1);
      expect(channel.cancelled, 1);
    });
  });
}
