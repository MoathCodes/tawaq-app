import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/media_session_router_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

import '../../core/audio/fake_audio_player.dart';

// Spy notifiers that record dispatched calls.

enum _RecitationCall { toggle, stop, next, previous, seekTo }

class _SpyRecitationController extends RecitationController {
  final List<_RecitationCall> calls = [];
  final List<Duration> seeks = [];

  @override
  RecitationState build() => const RecitationState(active: true);

  @override
  Future<void> togglePlayPause() async => calls.add(_RecitationCall.toggle);
  @override
  Future<void> stop() async => calls.add(_RecitationCall.stop);
  @override
  Future<void> skipNext() async => calls.add(_RecitationCall.next);
  @override
  Future<void> skipPrevious() async => calls.add(_RecitationCall.previous);
  @override
  Future<void> seekTo(Duration position) async {
    calls.add(_RecitationCall.seekTo);
    seeks.add(position);
  }
}

enum _AdhanCall { resume, pause, stop }

class _SpyAudioPlayerController extends AudioPlayerController {
  final List<_AdhanCall> calls = [];

  @override
  PlaybackState build() => const PlaybackIdle();

  @override
  Future<void> pause() async => calls.add(_AdhanCall.pause);
  @override
  Future<void> resume() async => calls.add(_AdhanCall.resume);
  @override
  Future<void> stop({Duration fadeOut = Duration.zero}) async =>
      calls.add(_AdhanCall.stop);
}

void main() {
  setUpAll(registerAudioServiceFallbacks);

  late FakeAudioStreamHandles handles;
  late TawaqAudioService service;

  setUp(() {
    handles = buildFakeAudioPlayer();
    service = TawaqAudioService(player: handles.player);
  });

  tearDown(() async {
    await handles.dispose();
    await service.dispose();
  });

  ProviderContainer buildContainer({
    required _SpyRecitationController recitationSpy,
    required _SpyAudioPlayerController adhanSpy,
  }) {
    return ProviderContainer(overrides: [
      tawaqAudioServiceProvider.overrideWithValue(service),
      recitationControllerProvider.overrideWith(() => recitationSpy),
      audioPlayerControllerProvider.overrideWith(() => adhanSpy),
    ]);
  }

  void setPlayWhenReady(bool value) {
    setFakePlayerState(
      handles.player,
      PlayerState(playWhenReady: value),
    );
  }

  group('media session command router', () {
    test('recitation play/pause compensate for mpv auto-apply', () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);

      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kRecitationLeaseOwner);
      addTearDown(() => service.release(owner: kRecitationLeaseOwner));

      final notifier = container.read(recitationControllerProvider.notifier);

      // Paused + mpv already resumed → no toggle (stateStream sync only).
      notifier.state = const RecitationState(
        active: true,
        status: RecitationStatus.paused,
        surah: 1,
      );
      setPlayWhenReady(true);
      router.dispatch(MediaSessionCommand.play);
      await Future<void>.delayed(Duration.zero);
      expect(recitation.calls, isEmpty);

      // Playing + mpv already paused → no toggle.
      notifier.state = const RecitationState(
        active: true,
        status: RecitationStatus.playing,
        surah: 1,
      );
      setPlayWhenReady(false);
      router.dispatch(MediaSessionCommand.pause);
      await Future<void>.delayed(Duration.zero);
      expect(recitation.calls, isEmpty);

      // Paused + mpv still paused → explicit resume via toggle fallback.
      notifier.state = const RecitationState(
        active: true,
        status: RecitationStatus.paused,
        surah: 1,
      );
      setPlayWhenReady(false);
      router.dispatch(MediaSessionCommand.play);
      await Future<void>.delayed(Duration.zero);
      expect(recitation.calls, [_RecitationCall.toggle]);

      recitation.calls.clear();

      // Playing + mpv still playing → explicit pause via toggle fallback.
      notifier.state = const RecitationState(
        active: true,
        status: RecitationStatus.playing,
        surah: 1,
      );
      setPlayWhenReady(true);
      router.dispatch(MediaSessionCommand.pause);
      await Future<void>.delayed(Duration.zero);
      expect(recitation.calls, [_RecitationCall.toggle]);
    });

    test('recitation play from ended replays via toggle', () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);

      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kRecitationLeaseOwner);
      addTearDown(() => service.release(owner: kRecitationLeaseOwner));

      container.read(recitationControllerProvider.notifier).state =
          const RecitationState(
        active: true,
        status: RecitationStatus.ended,
        surah: 1,
      );
      setPlayWhenReady(true);

      router.dispatch(MediaSessionCommand.play);
      await Future<void>.delayed(Duration.zero);

      expect(recitation.calls, [_RecitationCall.toggle]);
    });

    test('recitation playPause always toggles', () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);

      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kRecitationLeaseOwner);
      addTearDown(() => service.release(owner: kRecitationLeaseOwner));

      container.read(recitationControllerProvider.notifier).state =
          const RecitationState(
        active: true,
        status: RecitationStatus.playing,
        surah: 1,
      );
      setPlayWhenReady(false);

      router.dispatch(MediaSessionCommand.playPause);
      await Future<void>.delayed(Duration.zero);

      expect(recitation.calls, [_RecitationCall.toggle]);
    });

    test('recitation lease routes stop/next/previous; SeekTo is mpv no-op',
        () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);

      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kRecitationLeaseOwner);
      addTearDown(() => service.release(owner: kRecitationLeaseOwner));

      router
        ..dispatch(MediaSessionCommand.stop)
        ..dispatch(MediaSessionCommand.next)
        ..dispatch(MediaSessionCommand.previous)
        ..dispatch(const MediaSessionCommand.seekTo(Duration(seconds: 5)));

      await Future<void>.delayed(Duration.zero);

      expect(recitation.calls, [
        _RecitationCall.stop,
        _RecitationCall.next,
        _RecitationCall.previous,
      ]);
      expect(recitation.seeks, isEmpty);
      expect(adhan.calls, isEmpty);
    });

    test('recitation seekBy routes next (forward) and previous (rewind)',
        () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);
      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kRecitationLeaseOwner);
      addTearDown(() => service.release(owner: kRecitationLeaseOwner));

      router
        ..dispatch(const MediaSessionCommand.seekBy(Duration(seconds: 15)))
        ..dispatch(const MediaSessionCommand.seekBy(Duration(seconds: -15)));

      await Future<void>.delayed(Duration.zero);
      expect(
        recitation.calls,
        [_RecitationCall.next, _RecitationCall.previous],
      );
    });

    test('adhan lease routes play->resume, pause->pause, stop->stop',
        () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);
      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kAdhanLeaseOwner);
      addTearDown(() => service.release(owner: kAdhanLeaseOwner));

      router
        ..dispatch(MediaSessionCommand.play)
        ..dispatch(MediaSessionCommand.pause)
        ..dispatch(MediaSessionCommand.stop)
        ..dispatch(MediaSessionCommand.playPause);

      await Future<void>.delayed(Duration.zero);
      expect(adhan.calls, [
        _AdhanCall.resume,
        _AdhanCall.pause,
        _AdhanCall.stop,
        _AdhanCall.stop,
      ]);
      expect(recitation.calls, isEmpty);
    });

    test('adhan lease ignores next/previous/seek', () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);
      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);
      await service.acquire(owner: kAdhanLeaseOwner);
      addTearDown(() => service.release(owner: kAdhanLeaseOwner));

      router
        ..dispatch(MediaSessionCommand.next)
        ..dispatch(MediaSessionCommand.previous)
        ..dispatch(const MediaSessionCommand.seekTo(Duration(seconds: 3)));

      await Future<void>.delayed(Duration.zero);
      expect(adhan.calls, isEmpty);
      expect(recitation.calls, isEmpty);
    });

    test('no lease owner ignores all commands', () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);
      final router =
          container.read(mediaSessionCommandRouterProvider.notifier);

      // No lease acquired — owner is null.
      expect(service.currentLeaseOwner, isNull);
      router
        ..dispatch(MediaSessionCommand.play)
        ..dispatch(MediaSessionCommand.stop)
        ..dispatch(MediaSessionCommand.next);

      await Future<void>.delayed(Duration.zero);
      expect(recitation.calls, isEmpty);
      expect(adhan.calls, isEmpty);
    });

    test('live OS stream dispatches to the current lease owner', () async {
      final recitation = _SpyRecitationController();
      final adhan = _SpyAudioPlayerController();
      final container = buildContainer(
        recitationSpy: recitation,
        adhanSpy: adhan,
      );
      addTearDown(container.dispose);
      // Reading the notifier builds the provider and subscribes to the
      // service's mediaSessionCommands stream.
      container.read(mediaSessionCommandRouterProvider.notifier);

      // Recitation owns the lease -> a stop command stops recitation.
      await service.acquire(owner: kRecitationLeaseOwner);
      addTearDown(() => service.release(owner: kRecitationLeaseOwner));
      handles.mediaSessionCommands.add(MediaSessionCommand.stop);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(recitation.calls, [_RecitationCall.stop]);
      expect(adhan.calls, isEmpty);

      // Switch the lease to adhan -> a play command resumes adhan.
      await service.release(owner: kRecitationLeaseOwner);
      await service.acquire(owner: kAdhanLeaseOwner);
      addTearDown(() => service.release(owner: kAdhanLeaseOwner));
      handles.mediaSessionCommands.add(MediaSessionCommand.play);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(recitation.calls, [_RecitationCall.stop]);
      expect(adhan.calls, [_AdhanCall.resume]);
    });
  });
}
