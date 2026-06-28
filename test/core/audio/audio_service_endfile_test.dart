import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

class _FakePlayer extends Mock implements PlayerApi {}

class _FakePlayerStream extends Mock implements PlayerStream {}

/// Typed controllers for every stream the service subscribes to or awaits.
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

_StreamHandles _buildFakePlayer({
  PlayerState initialState = const PlayerState(),
}) {
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
  when(() => player.state).thenReturn(initialState);
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

void _setState(_FakePlayer player, PlayerState s) {
  when(() => player.state).thenReturn(s);
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

  group('audio_service endFile + buffering', () {
    test('natural eof emits PlaybackIdle', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      _setState(
        h.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(minutes: 2),
          duration: Duration(minutes: 2),
        ),
      );
      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackIdle>());
    });

    test('network-drop eof emits PlaybackError', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 3),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      // Only 10s into a 3-minute track (>10% short) -> network drop.
      _setState(
        h.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(seconds: 10),
          duration: Duration(minutes: 3),
        ),
      );
      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackError>());
      expect(
        (service.state as PlaybackError).message,
        contains('network drop'),
      );
    });

    test('file:// eof with inflated duration emits PlaybackIdle', () async {
      final fileTrack = AudioTrack.network(
        id: 'cached',
        title: 'Cached',
        url: 'file:///tmp/surah.mp3',
      );
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 10),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(fileTrack, fadeIn: Duration.zero, owner: 'test');

      // Position far short of reported duration — still natural eof for cache.
      _setState(
        h.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(minutes: 8),
          duration: Duration(minutes: 10),
        ),
      );
      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackIdle>());
    });

    test('network eof near reported end emits PlaybackIdle', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 3),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      _setState(
        h.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(minutes: 2, seconds: 50),
          duration: Duration(minutes: 3),
        ),
      );
      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackIdle>());
    });

    test('endFile.stop does not emit PlaybackError', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      expect(service.state, isA<PlaybackPlaying>());

      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.stop, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackPlaying>());
      expect(service.state, isNot(isA<PlaybackError>()));
    });

    test('endFile.redirect does not emit PlaybackError', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      expect(service.state, isA<PlaybackPlaying>());

      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.redirect, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackPlaying>());
      expect(service.state, isNot(isA<PlaybackError>()));
    });

    test('endFile.error emits PlaybackError', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      h.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.error, error: 42),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackError>());
      expect(
        (service.state as PlaybackError).message,
        contains('endFile error'),
      );
    });

    test('mid-playback stall emits PlaybackBuffering', () async {
      final h = _buildFakePlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: h.player);
      addTearDown(() async {
        await h.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      _setState(
        h.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(seconds: 30),
          duration: Duration(minutes: 2),
        ),
      );
      h.buffering.add(true);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackBuffering>());
    });
  });
}
