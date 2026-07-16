import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

class _MockChannel extends Mock implements PrayerAlertChannel {
  _MockChannel(this._name);
  final String _name;

  @override
  String get debugName => _name;
}

PrayerAlertEvent _event({
  required PrayerAlertKind kind,
  required Prayer prayer,
  bool playSound = true,
}) {
  return PrayerAlertEvent(
    kind: kind,
    prayer: prayer,
    scheduledTime: DateTime(2026, 1, 1, 12),
    playSound: playSound,
    showInApp: false,
    showOsNotification: false,
    volume: 80,
  );
}

AudioTrack get _track => AudioTrack.asset(
      id: 'a',
      title: 'A',
      assetPath: 'a',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(
      AudioTrack.asset(id: 'fallback', title: 'Fallback', assetPath: 'x'),
    );
    registerFallbackValue(
      PrayerAlertEvent(
        kind: PrayerAlertKind.adhan,
        prayer: Prayer.fajr,
        scheduledTime: DateTime(2026, 1, 1, 12),
        playSound: true,
        showInApp: false,
        showOsNotification: false,
        volume: 80,
      ),
    );
  });

  group('PrayerAlertCoordinator completion', () {
    test('already Playing at subscription finishes on Idle', () async {
      final states = StreamController<PlaybackState>.broadcast();
      final channel = _MockChannel('sound');
      final finished = <int>[];

      final coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: states.stream,
        soundSafetyCap: const Duration(minutes: 5),
        currentPlayback: () => PlaybackPlaying(
          track: _track,
          position: const Duration(seconds: 1),
          duration: const Duration(minutes: 2),
        ),
        onFinished: () => finished.add(1),
      );
      addTearDown(coordinator.dispose);

      when(() => channel.deliver(any())).thenAnswer((_) async {});
      when(channel.cancel).thenAnswer((_) async {});

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.adhan, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);
      expect(finished, isEmpty);

      states.add(const PlaybackIdle());
      await Future<void>.delayed(Duration.zero);
      expect(finished, [1]);
    });

    test('PlaybackPlaying then PlaybackIdle finishes alert', () async {
      final states = StreamController<PlaybackState>.broadcast();
      final channel = _MockChannel('sound');
      final finished = <int>[];

      final coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: states.stream,
        soundSafetyCap: const Duration(minutes: 5),
        onFinished: () => finished.add(1),
      );
      addTearDown(coordinator.dispose);

      when(() => channel.deliver(any())).thenAnswer((_) async {});
      when(channel.cancel).thenAnswer((_) async {});

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.adhan, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);

      states.add(
        PlaybackPlaying(
          track: _track,
          position: const Duration(seconds: 1),
          duration: const Duration(minutes: 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(finished, isEmpty);

      states.add(const PlaybackIdle());
      await Future<void>.delayed(Duration.zero);
      expect(finished, [1]);
    });

    test('PlaybackBuffering waits then Playing+Idle finishes', () async {
      final states = StreamController<PlaybackState>.broadcast();
      final channel = _MockChannel('sound');
      final finished = <int>[];

      final coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: states.stream,
        soundSafetyCap: const Duration(minutes: 5),
        onFinished: () => finished.add(1),
      );
      addTearDown(coordinator.dispose);

      when(() => channel.deliver(any())).thenAnswer((_) async {});
      when(channel.cancel).thenAnswer((_) async {});

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.adhan, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);

      states.add(PlaybackBuffering(_track));
      await Future<void>.delayed(Duration.zero);
      expect(finished, isEmpty);

      states.add(
        PlaybackPlaying(
          track: _track,
          position: const Duration(seconds: 1),
          duration: const Duration(minutes: 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(finished, isEmpty);

      states.add(const PlaybackIdle());
      await Future<void>.delayed(Duration.zero);
      expect(finished, [1]);
    });

    test('PlaybackError finishes alert', () async {
      final states = StreamController<PlaybackState>.broadcast();
      final channel = _MockChannel('sound');
      final finished = <int>[];

      final coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: states.stream,
        soundSafetyCap: const Duration(minutes: 5),
        onFinished: () => finished.add(1),
      );
      addTearDown(coordinator.dispose);

      when(() => channel.deliver(any())).thenAnswer((_) async {});
      when(channel.cancel).thenAnswer((_) async {});

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.adhan, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);

      states.add(PlaybackError(track: _track, message: 'boom'));
      await Future<void>.delayed(Duration.zero);
      expect(finished, [1]);
    });

    test('safety cap cancels and finishes a stuck alert', () async {
      final states = StreamController<PlaybackState>.broadcast();
      final channel = _MockChannel('sound');
      final finished = <int>[];

      final coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: states.stream,
        soundSafetyCap: const Duration(milliseconds: 100),
        onFinished: () => finished.add(1),
      );
      addTearDown(coordinator.dispose);

      when(() => channel.deliver(any())).thenAnswer((_) async {});
      when(channel.cancel).thenAnswer((_) async {});

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.adhan, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);

      states.add(
        PlaybackPlaying(
          track: _track,
          position: const Duration(seconds: 1),
          duration: const Duration(minutes: 2),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(finished, [1]);
      verify(channel.cancel).called(greaterThan(0));
    });

    test('iqamah skips while adhan is in-flight for same prayer', () async {
      final states = StreamController<PlaybackState>.broadcast();
      final channel = _MockChannel('sound');
      final finished = <int>[];

      final coordinator = PrayerAlertCoordinator(
        channels: [channel],
        playbackStream: states.stream,
        soundSafetyCap: const Duration(minutes: 5),
        onFinished: () => finished.add(1),
      );
      addTearDown(coordinator.dispose);

      when(() => channel.deliver(any())).thenAnswer((_) async {});
      when(channel.cancel).thenAnswer((_) async {});

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.adhan, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);

      await coordinator.dispatch(
        _event(kind: PrayerAlertKind.iqamah, prayer: Prayer.fajr),
      );
      await Future<void>.delayed(Duration.zero);

      final delivered = verify(() => channel.deliver(captureAny())).captured;
      expect(delivered.length, 1);
      expect(
        (delivered.single as PrayerAlertEvent).kind,
        PrayerAlertKind.adhan,
      );

      states
        ..add(
          PlaybackPlaying(
            track: _track,
            position: const Duration(seconds: 1),
            duration: const Duration(minutes: 2),
          ),
        )
        ..add(const PlaybackIdle());
      await Future<void>.delayed(Duration.zero);
      expect(finished, [1]);
    });
  });
}
