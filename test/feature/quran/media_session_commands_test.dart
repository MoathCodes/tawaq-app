import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/feature/quran/presentation/providers/media_session_router_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

// Fake mpv player (mirrors test/core/audio/audio_service_endfile_test).

class _FakePlayer extends Mock implements PlayerApi {}

class _FakePlayerStream extends Mock implements PlayerStream {}

class _StreamHandles {
  _StreamHandles(this.player, this.stream);

  final _FakePlayer player;
  final _FakePlayerStream stream;

  final StreamController<bool> playing = StreamController<bool>.broadcast();
  final StreamController<MpvPlayerError> error =
      StreamController<MpvPlayerError>.broadcast();
  final StreamController<MpvFileEndedEvent> endFile =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<bool> buffering = StreamController<bool>.broadcast();
  final StreamController<bool> pausedForCache =
      StreamController<bool>.broadcast();
  final StreamController<void> seekCompleted = StreamController.broadcast();
  final StreamController<Duration> position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> duration =
      StreamController<Duration>.broadcast();
  final StreamController<int?> remainingAbLoops =
      StreamController<int?>.broadcast();
  final StreamController<MediaSessionCommand> mediaSessionCommands =
      StreamController<MediaSessionCommand>.broadcast();

  Future<void> dispose() async {
    await playing.close();
    await error.close();
    await endFile.close();
    await buffering.close();
    await pausedForCache.close();
    await seekCompleted.close();
    await position.close();
    await duration.close();
    await remainingAbLoops.close();
    await mediaSessionCommands.close();
  }
}

Future<void> _noop(Invocation _) async {}

_StreamHandles _buildFakePlayer() {
  final stream = _FakePlayerStream();
  final player = _FakePlayer();
  final h = _StreamHandles(player, stream);
  when(() => stream.playing).thenAnswer((_) => h.playing.stream);
  when(() => stream.error).thenAnswer((_) => h.error.stream);
  when(() => stream.endFile).thenAnswer((_) => h.endFile.stream);
  when(() => stream.buffering).thenAnswer((_) => h.buffering.stream);
  when(() => stream.pausedForCache)
      .thenAnswer((_) => h.pausedForCache.stream);
  when(() => stream.seekCompleted)
      .thenAnswer((_) => h.seekCompleted.stream);
  when(() => stream.position).thenAnswer((_) => h.position.stream);
  when(() => stream.duration).thenAnswer((_) => h.duration.stream);
  when(() => stream.remainingAbLoops)
      .thenAnswer((_) => h.remainingAbLoops.stream);
  when(() => stream.mediaSessionCommands)
      .thenAnswer((_) => h.mediaSessionCommands.stream);
  when(() => player.stream).thenReturn(stream);
  when(() => player.state).thenReturn(const PlayerState());
  when(() => player.open(any(), play: any(named: 'play')))
      .thenAnswer(_noop);
  when(player.play).thenAnswer(_noop);
  when(player.pause).thenAnswer(_noop);
  when(player.stop).thenAnswer(_noop);
  when(() => player.seek(
        any(),
        relative: any(named: 'relative'),
        exact: any(named: 'exact'),
      )).thenAnswer(_noop);
  when(() => player.setVolume(any())).thenAnswer(_noop);
  when(() => player.setMediaSession(any())).thenAnswer(_noop);
  when(() => player.setAudioClientName(any())).thenAnswer(_noop);
  when(() => player.setAbLoopA(any())).thenAnswer(_noop);
  when(() => player.setAbLoopB(any())).thenAnswer(_noop);
  when(() => player.setAbLoopCount(any())).thenAnswer(_noop);
  when(player.dispose).thenAnswer(_noop);
  return h;
}

// Spy notifiers that record dispatched calls.

enum _RecitationCall { toggle, stop, next, previous, seekTo }

class _SpyRecitationController extends RecitationController {
  final List<_RecitationCall> calls = [];
  final List<Duration> seeks = [];

  @override
  RecitationState build() => const RecitationState();

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

final AudioTrack _track = AudioTrack.network(
  id: 't',
  title: 'T',
  url: 'https://example.com/a.mp3',
);

void main() {
  setUpAll(() {
    registerFallbackValue(const Media('asset:///fallback'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(0.0);
    registerFallbackValue(const MediaSession());
    registerFallbackValue('');
  });

  late _StreamHandles handles;
  late TawaqAudioService service;

  setUp(() {
    handles = _buildFakePlayer();
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

  group('media session command router', () {
    test('recitation lease routes play/pause/stop/next/previous/seek',
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
        ..dispatch(MediaSessionCommand.play)
        ..dispatch(MediaSessionCommand.pause)
        ..dispatch(MediaSessionCommand.playPause)
        ..dispatch(MediaSessionCommand.stop)
        ..dispatch(MediaSessionCommand.next)
        ..dispatch(MediaSessionCommand.previous)
        ..dispatch(const MediaSessionCommand.seekTo(Duration(seconds: 5)));

      await Future<void>.delayed(Duration.zero);

      expect(recitation.calls, [
        _RecitationCall.toggle,
        _RecitationCall.toggle,
        _RecitationCall.toggle,
        _RecitationCall.stop,
        _RecitationCall.next,
        _RecitationCall.previous,
        _RecitationCall.seekTo,
      ]);
      expect(recitation.seeks, [const Duration(seconds: 5)]);
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

    test('rich MediaSession metadata published on load advertises actions',
        () async {
      // The service publishes a MediaSession with the full transport action
      // set whenever a track is opened. Capture the last setMediaSession arg.
      MediaSession? published;
      when(() => handles.player.setMediaSession(any())).thenAnswer((inv) async {
        published = inv.positionalArguments[0] as MediaSession?;
      });
      when(() => handles.player.state)
          .thenReturn(const PlayerState(duration: Duration(minutes: 3)));

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      expect(published, isNotNull);
      expect(published!.title, _track.title);
      expect(published!.artist, 'Tawaq');
      expect(published!.duration, const Duration(minutes: 3));
      expect(published!.actions, contains(MediaAction.play));
      expect(published!.actions, contains(MediaAction.pause));
      expect(published!.actions, contains(MediaAction.next));
      expect(published!.actions, contains(MediaAction.previous));
      expect(published!.actions, contains(MediaAction.seek));
      expect(published!.actions, contains(MediaAction.stop));
    });
  });
}
