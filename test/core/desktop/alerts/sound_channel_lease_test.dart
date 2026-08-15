import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/app/desktop/alerts/sound_alert_channel.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';

class _MockAudioPlayerController extends Mock implements AdhanAudioController {}

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
    late _MockAudioPlayerController adhanPlayer;

    setUp(() {
      adhanPlayer = _MockAudioPlayerController();

      when(
        () => adhanPlayer.stop(
          fadeOut: any(named: 'fadeOut'),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async {});
      when(() => adhanPlayer.setVolume(any())).thenAnswer((_) async {});
      when(
        () => adhanPlayer.playTrack(
          any(),
          fadeIn: any(named: 'fadeIn'),
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
        adhanPlayer: adhanPlayer,
        onCaptureRecitationVolume: onCaptureRecitationVolume ?? () async => 70,
        onSuspend: onSuspend ?? () async {},
        onRestoreRecitationVolume: onRestoreRecitationVolume ?? (_) async {},
        onResume: onResume ?? () async {},
      );
    }

    test('deliver plays through adhan player after suspend', () async {
      var suspended = false;
      when(
        () => adhanPlayer.playTrack(
          any(),
          fadeIn: any(named: 'fadeIn'),
        ),
      ).thenAnswer((_) async {
        expect(suspended, isTrue);
      });

      final channel = makeChannel(
        onSuspend: () async {
          suspended = true;
        },
      );
      await channel.deliver(_event());

      verify(() => adhanPlayer.setVolume(80)).called(1);
      verify(
        () => adhanPlayer.playTrack(
          any(),
        ),
      ).called(1);
    });

    test('deliver captures recitation volume before suspending', () async {
      var capturedVolume = 0.0;
      var suspendCalled = false;

      final channel = makeChannel(
        onCaptureRecitationVolume: () async {
          capturedVolume = 70;
          return capturedVolume;
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

    test('deliver suspends recitation before adhan playback', () async {
      var suspended = false;
      when(
        () => adhanPlayer.playTrack(
          any(),
          fadeIn: any(named: 'fadeIn'),
        ),
      ).thenAnswer((_) async {
        expect(suspended, isTrue);
      });

      final channel = makeChannel(
        onSuspend: () async {
          suspended = true;
        },
      );

      await channel.deliver(_event());

      expect(suspended, isTrue);
    });

    test('cancel stops adhan playback', () async {
      final channel = makeChannel();
      await channel.deliver(_event());
      await channel.cancel();

      verify(
        () => adhanPlayer.stop(
          fadeOut: kAudioDefaultFadeOut,
          force: true,
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
