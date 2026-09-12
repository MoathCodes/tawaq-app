import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/app/desktop/alerts/sound_alert_channel.dart';
import 'package:tawaq/core/audio/audio_interruption.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_preview_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

import '../../core/audio/fake_audio_player.dart';

class _FakeAdhanAudio extends AdhanAudioController {
  final List<AudioTrack> played = [];
  final List<double> volumes = [];
  int stops = 0;

  /// Mirrors playback into the fake session, like the real service does.
  void Function(AudioTrack track)? onPlay;
  Future<void> Function(double volume)? onSetVolume;

  @override
  void build() {}

  @override
  Future<void> playTrack(
    AudioTrack track, {
    Duration fadeIn = kAudioDefaultFadeIn,
  }) async {
    played.add(track);
    onPlay?.call(track);
  }

  @override
  Future<void> stop({
    Duration fadeOut = Duration.zero,
    bool force = false,
  }) async {
    stops++;
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
    await onSetVolume?.call(volume);
  }
}

class _Session extends AudioSession {
  @override
  AudioSessionSnapshot build() => const AudioSessionSnapshot();

  void emit(AudioSessionSnapshot snapshot) => state = snapshot;
}

class _RecitationSpy extends RecitationController {
  int suspends = 0;
  int resumes = 0;

  @override
  RecitationState build() => const RecitationState(
    active: true,
    status: RecitationStatus.playing,
    surah: 1,
  );

  @override
  Future<void> suspendForAlert() async => suspends++;

  @override
  Future<void> resumeAfterAlert() async => resumes++;
}

class _Settings extends AdhanSettingsNotifier {
  @override
  Future<AdhanSettings> build() async {
    state = AsyncData(AdhanSettings.defaults());
    return AdhanSettings.defaults();
  }
}

({
  ProviderContainer container,
  _FakeAdhanAudio audio,
  _Session session,
  TawaqAudioService service,
  FakeAudioStreamHandles handles,
  _RecitationSpy recitation,
})
_create() {
  final audio = _FakeAdhanAudio();
  final session = _Session();
  final handles = buildFakeAudioPlayer();
  final service = TawaqAudioService(player: handles.player);
  audio.onSetVolume = service.setVolume;
  final recitation = _RecitationSpy();
  final interruption = AudioInterruptionCoordinator();
  interruption.registerRecitation(
    suspend: recitation.suspendForAlert,
    resume: recitation.resumeAfterAlert,
  );
  final container = ProviderContainer(
    overrides: [
      adhanAudioControllerProvider.overrideWith(() => audio),
      tawaqAudioServiceProvider.overrideWithValue(service),
      audioInterruptionCoordinatorProvider.overrideWithValue(interruption),
      audioSessionProvider.overrideWith(() => session),
      recitationControllerProvider.overrideWith(() => recitation),
      adhanSettingsProvider.overrideWith(() => _Settings()),
    ],
  );
  addTearDown(() async {
    await service.dispose();
    await handles.dispose();
  });
  addTearDown(container.dispose);
  // Mount the fakes before driving them.
  container.read(audioSessionProvider);
  container.read(adhanPreviewProvider);
  container.listen(adhanPreviewProvider, (_, next) {});
  return (
    container: container,
    audio: audio,
    session: session,
    service: service,
    handles: handles,
    recitation: recitation,
  );
}

void main() {
  setUpAll(registerAudioServiceFallbacks);

  group('adhan preview (TAW-72)', () {
    test(
      'previews the candidate muezzin voice without touching settings',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        session.emit(const AudioSessionSnapshot());
        final before = await container.read(adhanSettingsProvider.future);

        await container
            .read(adhanPreviewProvider.notifier)
            .previewAdhan(AdhanSound.makkah, label: 'Makkah', volume: 80);

        expect(audio.played, hasLength(1));
        expect(audio.played.single.id, contains('adhan-makkah'));
        expect(
          audio.played.single.uri,
          contains('assets/audio/adhan/makkah.mp3'),
        );
        expect(audio.volumes, [80]);
        final preview = container.read(adhanPreviewProvider);
        expect(preview.status, AdhanPreviewStatus.playing);
        expect(preview.adhanSound, AdhanSound.makkah);
        expect(await container.read(adhanSettingsProvider.future), before);
      },
    );

    test('iqamah preview replaces an active adhan preview', () async {
      final (:container, :audio, :session, :service, :handles, :recitation) =
          _create();
      session.emit(const AudioSessionSnapshot());
      final notifier = container.read(adhanPreviewProvider.notifier);

      await notifier.previewAdhan(
        AdhanSound.makkah,
        label: 'Makkah',
        volume: 80,
      );
      await notifier.previewIqamah(
        IqamahSound.madinah,
        label: 'Madinah',
        volume: 60,
      );

      expect(audio.played, hasLength(2));
      expect(audio.played.last.uri, contains('assets/audio/iqamah/'));
      final preview = container.read(adhanPreviewProvider);
      expect(preview.status, AdhanPreviewStatus.playing);
      expect(preview.iqamahSound, IqamahSound.madinah);
      expect(preview.adhanSound, isNull);
    });

    test('tapping the active target stops the preview', () async {
      final (:container, :audio, :session, :service, :handles, :recitation) =
          _create();
      session.emit(const AudioSessionSnapshot());
      final notifier = container.read(adhanPreviewProvider.notifier);

      await notifier.previewAdhan(
        AdhanSound.makkah,
        label: 'Makkah',
        volume: 80,
      );
      // Engine still holds our preview track, so cleanup stops it.
      session.emit(
        AudioSessionSnapshot(track: audio.played.single),
      );
      await notifier.previewAdhan(
        AdhanSound.makkah,
        label: 'Makkah',
        volume: 80,
      );

      expect(
        container.read(adhanPreviewProvider).status,
        AdhanPreviewStatus.idle,
      );
      expect(audio.stops, 1);
    });

    test(
      'stop works when the session reports playing before play resolves',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        session.emit(const AudioSessionSnapshot());
        // The real service emits playing while playTrack is still awaited;
        // ownership must already cover that transition.
        audio.onPlay = (track) => session.emit(
          AudioSessionSnapshot(
            track: track,
            lifecycle: AudioSessionLifecycle.playing,
          ),
        );
        final notifier = container.read(adhanPreviewProvider.notifier);

        await notifier.previewAdhan(
          AdhanSound.makkah,
          label: 'Makkah',
          volume: 80,
        );
        expect(
          container.read(adhanPreviewProvider).status,
          AdhanPreviewStatus.playing,
        );

        await notifier.stop();

        expect(audio.stops, 1);
        expect(
          container.read(adhanPreviewProvider).status,
          AdhanPreviewStatus.idle,
        );
      },
    );

    test('stop after a real alert preempts leaves the engine alone', () async {
      final (:container, :audio, :session, :service, :handles, :recitation) =
          _create();
      session.emit(const AudioSessionSnapshot());
      final notifier = container.read(adhanPreviewProvider.notifier);

      await notifier.previewAdhan(
        AdhanSound.makkah,
        label: 'Makkah',
        volume: 80,
      );
      // A real alert takes over under the same lease; the preview drops out.
      session.emit(
        const AudioSessionSnapshot(
          track: AudioTrack(
            id: 'adhan-dhuhr',
            title: 'Adhan',
            uri: 'asset:///assets/audio/adhan/makkah.mp3',
            source: AudioTrackSource.asset,
          ),
        ),
      );
      expect(
        container.read(adhanPreviewProvider).status,
        AdhanPreviewStatus.idle,
      );

      await notifier.stop();

      expect(audio.stops, isZero);
      expect(recitation.suspends, 1);
      expect(recitation.resumes, isZero);
    });

    test(
      'suspends recitation once and restores volume and playback on stop',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        await service.setVolume(42);
        final notifier = container.read(adhanPreviewProvider.notifier);

        await notifier.previewAdhan(
          AdhanSound.makkah,
          label: 'Makkah',
          volume: 80,
        );
        await notifier.previewIqamah(
          IqamahSound.madinah,
          label: 'Madinah',
          volume: 60,
        );

        expect(recitation.suspends, 1);
        expect(recitation.resumes, isZero);
        expect(service.volume, 60);

        await notifier.stop();
        await notifier.stop();

        expect(audio.stops, 2);
        expect(service.volume, 42);
        expect(recitation.resumes, 1);
      },
    );

    test(
      'natural completion stops the preview and resumes recitation',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        await service.setVolume(35);
        final notifier = container.read(adhanPreviewProvider.notifier);

        await notifier.previewAdhan(
          AdhanSound.makkah,
          label: 'Makkah',
          volume: 80,
        );
        final track = audio.played.single;
        session.emit(
          AudioSessionSnapshot(
            track: track,
            lifecycle: AudioSessionLifecycle.completed,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(adhanPreviewProvider).status,
          AdhanPreviewStatus.idle,
        );
        expect(audio.stops, 1);
        expect(service.volume, 35);
        expect(recitation.resumes, 1);
      },
    );

    test(
      'error tears down the preview and restores recitation exactly once',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        await service.setVolume(35);
        final notifier = container.read(adhanPreviewProvider.notifier);

        await notifier.previewAdhan(
          AdhanSound.makkah,
          label: 'Makkah',
          volume: 80,
        );
        session.emit(
          AudioSessionSnapshot(
            track: audio.played.single,
            lifecycle: AudioSessionLifecycle.error,
            error: 'decode failed',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(adhanPreviewProvider).status,
          AdhanPreviewStatus.error,
        );
        expect(audio.stops, 1);
        expect(service.volume, 35);
        expect(recitation.resumes, 1);
        await notifier.stop();
        expect(recitation.resumes, 1);
      },
    );

    test(
      'rapid target changes keep one preview slot and one suspension',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        final notifier = container.read(adhanPreviewProvider.notifier);

        final first = notifier.previewAdhan(
          AdhanSound.makkah,
          label: 'Makkah',
          volume: 80,
        );
        final second = notifier.previewIqamah(
          IqamahSound.madinah,
          label: 'Madinah',
          volume: 60,
        );
        await Future.wait([first, second]);

        expect(audio.played, hasLength(1));
        expect(
          container.read(adhanPreviewProvider).iqamahSound,
          IqamahSound.madinah,
        );
        expect(recitation.suspends, 1);
        expect(recitation.resumes, isZero);
      },
    );

    test(
      'real alert settles preview before capturing restored volume',
      () async {
        final (:container, :audio, :session, :service, :handles, :recitation) =
            _create();
        await service.setVolume(42);
        final notifier = container.read(adhanPreviewProvider.notifier);

        await notifier.previewAdhan(
          AdhanSound.makkah,
          label: 'Makkah',
          volume: 80,
        );

        var capturedVolume = 0.0;
        final channel = SoundAlertChannel(
          adhanPlayer: audio,
          onSettlePreview: container
              .read(audioInterruptionCoordinatorProvider)
              .settlePreview,
          onCaptureRecitationVolume: () async {
            capturedVolume = service.volume;
            return capturedVolume;
          },
          onSuspend: recitation.suspendForAlert,
          onRestoreRecitationVolume: service.setVolume,
          onResume: recitation.resumeAfterAlert,
        );

        await channel.deliver(
          PrayerAlertEvent(
            kind: PrayerAlertKind.adhan,
            prayer: Prayer.fajr,
            scheduledTime: DateTime(2026, 1, 1, 12),
            playSound: true,
            showInApp: false,
            showOsNotification: false,
            volume: 70,
            soundAssetPath: 'assets/audio/adhan/default.mp3',
          ),
        );

        expect(capturedVolume, 42);
        expect(recitation.suspends, 2);
        expect(recitation.resumes, 1);
        expect(audio.stops, 1);
      },
    );
  });
}
