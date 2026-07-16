import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

import 'fake_audio_player.dart';

const _metadata = MediaSessionPublishMetadata(
  title: 'Al-Fatiha',
  artist: 'Mishary Alafasy',
  appName: 'Tawaq',
  album: 'Audio by mp3quran.net',
);

final _track = AudioTrack.network(
  id: 't1',
  title: 'Embedded Title',
  subtitle: 'Embedded Artist',
  url: 'https://example.com/audio.mp3',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerAudioServiceFallbacks);

  group('adhan media session identity', () {
    test('play publishes appName and desktopEntry on first setMediaSession',
        () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'adhan');
      await service.play(_track, fadeIn: Duration.zero, owner: 'adhan');

      final captured = verify(
        () => handles.player.setMediaSession(captureAny()),
      ).captured.first as MediaSession;

      expect(captured.appName, kMediaSessionAppName);
      expect(captured.desktopEntry, kMediaSessionDesktopEntry);
      expect(captured.title, 'Embedded Title');
      expect(captured.artist, 'Embedded Artist');
    });
  });

  group('publishMediaSession', () {
    test('publishes caller metadata with desktop entry and no auto nav', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          duration: Duration(minutes: 3),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.publishMediaSession(_metadata);

      final captured = verify(
        () => handles.player.setMediaSession(captureAny()),
      ).captured.single as MediaSession;

      expect(captured.title, 'Al-Fatiha');
      expect(captured.artist, 'Mishary Alafasy');
      expect(captured.album, 'Audio by mp3quran.net');
      expect(captured.appName, 'Tawaq');
      expect(captured.desktopEntry, kMediaSessionDesktopEntry);
      expect(captured.autoApplyPlaylistNavigation, isFalse);
      expect(captured.duration, const Duration(minutes: 3));
      expect(captured.artwork.toString(), startsWith('MediaSessionArtwork.custom'));
    });

    test('play uses published metadata instead of file tags', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'recitation');
      await service.publishMediaSession(_metadata);
      await service.play(_track, fadeIn: Duration.zero, owner: 'recitation');

      final captured = verify(
        () => handles.player.setMediaSession(captureAny()),
      ).captured.last as MediaSession;

      expect(captured.title, 'Al-Fatiha');
      expect(captured.artist, 'Mishary Alafasy');
      expect(captured.title, isNot('Embedded Title'));
      expect(captured.artist, isNot('Embedded Artist'));
    });

    test('refreshes duration when stream resolves', () async {
      const initialSession = MediaSession(
        title: 'Al-Fatiha',
        artist: 'Mishary Alafasy',
      );
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          mediaSession: initialSession,
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'recitation');
      await service.publishMediaSession(_metadata);
      await service.play(_track, fadeIn: Duration.zero, owner: 'recitation');

      setFakePlayerState(
        handles.player,
        const PlayerState(
          mediaSession: initialSession,
          duration: Duration(minutes: 4),
        ),
      );
      handles.duration.add(const Duration(minutes: 4));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final captured = verify(
        () => handles.player.setMediaSession(captureAny()),
      ).captured.last as MediaSession;

      expect(captured.duration, const Duration(minutes: 4));
    });

    test('stop clears published session', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'recitation');
      await service.publishMediaSession(_metadata);
      await service.play(_track, fadeIn: Duration.zero, owner: 'recitation');
      await service.stop(owner: 'recitation');

      verify(() => handles.player.setMediaSession(null)).called(1);
    });
  });

  group('resetPlaybackModes', () {
    test('resets loop gapless and prefetch on play', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      verify(() => handles.player.setLoop(Loop.off)).called(1);
      verify(() => handles.player.setGapless(Gapless.weak)).called(1);
      verify(() => handles.player.setPrefetchPlaylist(false)).called(1);
    });

    test('resets modes on stop', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      await service.stop(owner: 'test');

      verify(() => handles.player.setLoop(Loop.off)).called(2);
      verify(() => handles.player.setGapless(Gapless.weak)).called(2);
      verify(() => handles.player.setPrefetchPlaylist(false)).called(2);
    });
  });

  group('completion and playWhenReady', () {
    test('completed stream emits PlaybackCompleted without stop', () async {
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

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');

      final completions = <void>[];
      final sub = service.completionStream.listen(completions.add);

      setFakePlayerState(
        handles.player,
        const PlayerState(
          completed: true,
          duration: Duration(minutes: 2),
          position: Duration(minutes: 2),
        ),
      );
      handles.completed.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.state, isA<PlaybackCompleted>());
      expect(completions, hasLength(1));
      verifyNever(handles.player.stop);
      verify(handles.player.pause).called(1);
      await sub.cancel();
    });

    test('playWhenReady stream updates paused state', () async {
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

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      expect(service.state, isA<PlaybackPlaying>());

      setFakePlayerState(
        handles.player,
        const PlayerState(
          duration: Duration(minutes: 2),
        ),
      );
      handles.playWhenReady.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.state, isA<PlaybackPaused>());
      expect(service.playWhenReady, isFalse);
    });

    test('pauseAtEof keeps track loaded', () async {
      final handles = buildFakeAudioPlayer(
        initialState: const PlayerState(
          duration: Duration(minutes: 2),
          position: Duration(minutes: 2),
        ),
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'test');
      await service.play(_track, fadeIn: Duration.zero, owner: 'test');
      await service.pauseAtEof();

      expect(service.state, isA<PlaybackCompleted>());
      verifyNever(() => handles.player.setMediaSession(null));
    });
  });
}
