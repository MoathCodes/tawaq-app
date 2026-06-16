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
  });
}
