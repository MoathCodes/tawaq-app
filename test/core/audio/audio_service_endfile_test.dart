import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

import 'fake_audio_player.dart';

final _track = AudioTrack.network(
  id: 't1',
  title: 'Test',
  url: 'https://example.com/audio.mp3',
);

void main() {
  setUpAll(registerAudioServiceFallbacks);

  group('audio_service endFile + buffering', () {
    test('natural eof emits PlaybackCompleted without stop', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      setFakePlayerState(
        handles.player,
        const PlayerState(
          position: Duration(minutes: 2),
          duration: Duration(minutes: 2),
          completed: true,
        ),
      );
      handles.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackCompleted>());
      verifyNever(handles.player.stop);
    });

    test('network-drop eof emits PlaybackError', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 3),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      setFakePlayerState(
        handles.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(seconds: 10),
          duration: Duration(minutes: 3),
        ),
      );
      handles.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackError>());
      expect(
        (service.state as PlaybackError).message,
        contains('network drop'),
      );
    });

    test('file:// eof with inflated duration emits PlaybackCompleted', () async {
      final fileTrack = AudioTrack.network(
        id: 'cached',
        title: 'Cached',
        url: 'file:///tmp/surah.mp3',
      );
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 10),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(fileTrack, fadeIn: Duration.zero, owner: 'test');

      setFakePlayerState(
        handles.player,
        const PlayerState(
          position: Duration(minutes: 8),
          duration: Duration(minutes: 10),
          completed: true,
        ),
      );
      handles.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackCompleted>());
    });

    test('network eof near reported end emits PlaybackCompleted', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 3),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      setFakePlayerState(
        handles.player,
        const PlayerState(
          position: Duration(minutes: 2, seconds: 50),
          duration: Duration(minutes: 3),
          completed: true,
        ),
      );
      handles.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackCompleted>());
    });

    test('endFile.stop does not emit PlaybackError', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      expect(service.state, isA<PlaybackPlaying>());

      handles.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.stop, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackPlaying>());
      expect(service.state, isNot(isA<PlaybackError>()));
    });

    test('endFile.redirect does not emit PlaybackError', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      expect(service.state, isA<PlaybackPlaying>());

      handles.endFile.add(
        const MpvFileEndedEvent(reason: MpvEndFileReason.redirect, error: 0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackPlaying>());
      expect(service.state, isNot(isA<PlaybackError>()));
    });

    test('endFile.error emits PlaybackError', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      handles.endFile.add(
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
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          playWhenReady: true,
          duration: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      setFakePlayerState(
        handles.player,
        const PlayerState(
          playWhenReady: true,
          position: Duration(seconds: 30),
          duration: Duration(minutes: 2),
        ),
      );
      handles.buffering.add(true);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.state, isA<PlaybackBuffering>());
    });
  });
}
