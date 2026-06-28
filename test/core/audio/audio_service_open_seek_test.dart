import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

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

final AudioTrack _track = AudioTrack.network(
  id: 't1',
  title: 'Test',
  url: 'https://example.com/audio.mp3',
);

void main() {
  setUpAll(() {
    registerFallbackValue(const Media('asset:///fallback'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(0.0);
    registerFallbackValue(const MediaSession());
    registerFallbackValue('');
  });

  group('openAndSeekTo', () {
    test('waits for file load before seeking', () async {
      final h = _buildFakePlayer();
      final seekCalls = <Duration>[];
      var openCompleted = false;

      when(() => h.player.open(any(), play: any(named: 'play'))).thenAnswer(
        (_) async {
          openCompleted = true;
        },
      );
      when(
        () => h.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      ).thenAnswer((inv) async {
        seekCalls.add(inv.positionalArguments[0] as Duration);
        h.seekCompleted.add(null);
      });

      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');

      final done = service.openAndSeekTo(
        _track,
        start: const Duration(seconds: 30),
        fadeIn: Duration.zero,
        owner: 'test',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(openCompleted, isTrue);
      expect(seekCalls, isEmpty);

      h.seekCompleted.add(null);
      await done;

      expect(seekCalls, [const Duration(seconds: 30)]);
      verify(() => h.player.play()).called(1);
    });

    test('skips seek when start is zero', () async {
      final h = _buildFakePlayer();
      when(() => h.player.open(any(), play: any(named: 'play'))).thenAnswer(
        (_) async {
          h.seekCompleted.add(null);
        },
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');

      await service.openAndSeekTo(
        _track,
        fadeIn: Duration.zero,
        owner: 'test',
      );

      verifyNever(
        () => h.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
      verify(() => h.player.play()).called(1);
    });
  });

  group('seek', () {
    test('returns false when no track is loaded', () async {
      final h = _buildFakePlayer();
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      final ok = await service.seek(
        const Duration(seconds: 10),
        owner: 'test',
      );

      expect(ok, isFalse);
      verifyNever(
        () => h.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
    });

    test('seeks when a track is active', () async {
      final h = _buildFakePlayer();
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      final ok = await service.seek(
        const Duration(seconds: 15),
        owner: 'test',
      );

      expect(ok, isTrue);
      verify(
        () => h.player.seek(
          const Duration(seconds: 15),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      ).called(1);
    });

    test('returns false after stop clears the active track', () async {
      final h = _buildFakePlayer();
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      await service.stop(owner: 'test');

      expect(service.state, isA<PlaybackIdle>());

      final ok = await service.seek(
        const Duration(seconds: 5),
        owner: 'test',
      );

      expect(ok, isFalse);
      verifyNever(
        () => h.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
    });
  });
}
