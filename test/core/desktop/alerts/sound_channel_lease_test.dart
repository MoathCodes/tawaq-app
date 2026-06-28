import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/desktop/alerts/sound_alert_channel.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';

class _MockTawaqAudioService extends Mock implements TawaqAudioService {}

PrayerAlertEvent _event({
  PrayerAlertKind kind = PrayerAlertKind.adhan,
  bool playSound = true,
  double volume = 80,
  String? assetPath = 'assets/audio/adhan/default.mp3',
}) {
  return PrayerAlertEvent(
    kind: kind,
    prayer: Prayer.fajr,
    scheduledTime: DateTime(2026, 1, 1, 12),
    playSound: playSound,
    showInApp: false,
    showOsNotification: false,
    volume: volume,
    soundAssetPath: assetPath,
    soundTitle: 'Adhan',
    soundSubtitle: 'Fajr',
  );
}

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

  group('SoundAlertChannel lease coordination', () {
    late _MockTawaqAudioService service;
    late AudioLease adhanLease;

    setUp(() async {
      service = _MockTawaqAudioService();

      final registry = AudioLeaseRegistry();
      addTearDown(registry.dispose);
      adhanLease = await registry.acquire(owner: kAdhanLeaseOwner);

      when(() => service.acquire(owner: kAdhanLeaseOwner))
          .thenAnswer((_) async => adhanLease);
      when(() => service.volume).thenReturn(70);
      when(
        () => service.stop(
          fadeOut: any(named: 'fadeOut'),
          owner: kAdhanLeaseOwner,
        ),
      ).thenAnswer((_) async {});
      when(() => service.setVolume(any())).thenAnswer((_) async {});
      when(
        () => service.play(
          any(),
          fadeIn: any(named: 'fadeIn'),
          owner: kAdhanLeaseOwner,
        ),
      ).thenAnswer((_) async {});
    });

    SoundAlertChannel makeChannel({
      Future<double> Function()? onCaptureRecitationVolume,
      Future<void> Function()? onSuspend,
      Future<void> Function(double volume)? onRestoreRecitationVolume,
      Future<void> Function()? onResume,
    }) {
      return SoundAlertChannel(
        service: service,
        onCaptureRecitationVolume:
            onCaptureRecitationVolume ?? () async => service.volume,
        onSuspend: onSuspend ?? () async {},
        onRestoreRecitationVolume:
            onRestoreRecitationVolume ?? (_) async {},
        onResume: onResume ?? () async {},
      );
    }

    test('deliver acquires adhan lease before play', () async {
      var acquired = false;
      when(() => service.acquire(owner: kAdhanLeaseOwner)).thenAnswer((_) async {
        acquired = true;
        return adhanLease;
      });
      when(
        () => service.play(
          any(),
          fadeIn: any(named: 'fadeIn'),
          owner: kAdhanLeaseOwner,
        ),
      ).thenAnswer((_) async {
        expect(acquired, isTrue);
      });

      final channel = makeChannel();
      await channel.deliver(_event());

      verify(() => service.acquire(owner: kAdhanLeaseOwner)).called(1);
      verify(
        () => service.play(
          any(),
          fadeIn: any(named: 'fadeIn'),
          owner: kAdhanLeaseOwner,
        ),
      ).called(1);
    });

    test('deliver captures recitation volume before suspending', () async {
      var capturedVolume = 0.0;
      var suspendCalled = false;

      final channel = makeChannel(
        onCaptureRecitationVolume: () async {
          return capturedVolume = service.volume;
        },
        onSuspend: () async {
          expect(capturedVolume, 70);
          suspendCalled = true;
        },
      );

      await channel.deliver(_event());

      expect(capturedVolume, 70);
      expect(suspendCalled, isTrue);
    });

    test('deliver suspends recitation before acquiring adhan lease', () async {
      var suspended = false;
      when(() => service.acquire(owner: kAdhanLeaseOwner)).thenAnswer((_) async {
        expect(suspended, isTrue);
        return adhanLease;
      });

      final channel = makeChannel(
        onSuspend: () async {
          suspended = true;
        },
      );

      await channel.deliver(_event());

      expect(suspended, isTrue);
      verify(() => service.acquire(owner: kAdhanLeaseOwner)).called(1);
    });

    test('cancel stops adhan playback', () async {
      final channel = makeChannel();
      await channel.deliver(_event());
      await channel.cancel();

      verify(
        () => service.stop(
          fadeOut: any(named: 'fadeOut'),
          owner: kAdhanLeaseOwner,
        ),
      ).called(1);
    });

    test('cancel restores recitation volume', () async {
      var restoredVolume = 0.0;

      final channel = makeChannel(
        onCaptureRecitationVolume: () async => 42,
        onRestoreRecitationVolume: (volume) async {
          restoredVolume = volume;
        },
      );

      await channel.deliver(_event());
      await channel.cancel();

      expect(restoredVolume, 42);
    });

    test('cancel resumes recitation', () async {
      var resumeCalled = false;

      final channel = makeChannel(
        onResume: () async {
          resumeCalled = true;
        },
      );

      await channel.deliver(_event());
      await channel.cancel();

      expect(resumeCalled, isTrue);
    });

    test('cancel does not restore volume when nothing was captured', () async {
      var restoreCalled = false;

      final channel = makeChannel(
        onRestoreRecitationVolume: (_) async {
          restoreCalled = true;
        },
      );

      await channel.cancel();

      expect(restoreCalled, isFalse);
    });
  });
}
