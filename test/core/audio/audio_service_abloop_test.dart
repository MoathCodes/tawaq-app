import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';

import 'fake_audio_player.dart';

final _track = AudioTrack.network(
  id: 't1',
  title: 'Test',
  url: 'https://example.com/audio.mp3',
);

void main() {
  setUpAll(registerAudioServiceFallbacks);

  group('clearAbLoop', () {
    test('play clears A-B loop before opening adhan track', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'adhan');
      await service.play(_track, fadeIn: Duration.zero, owner: 'adhan');

      verifyInOrder([
        () => handles.player.setAbLoopA(null),
        () => handles.player.setAbLoopB(null),
        () => handles.player.setAbLoopCount(null),
        () => handles.player.open(any(), play: false),
      ]);
    });

    test('stop clears A-B loop', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'adhan');
      await service.play(_track, fadeIn: Duration.zero, owner: 'adhan');
      await service.stop(owner: 'adhan');

      verify(() => handles.player.setAbLoopA(null)).called(2);
      verify(() => handles.player.setAbLoopB(null)).called(2);
      verify(() => handles.player.setAbLoopCount(null)).called(2);
    });

    test('openAndSeekTo clears A-B loop before load', () async {
      final handles = buildFakeAudioPlayer();
      when(() => handles.player.open(any(), play: any(named: 'play'))).thenAnswer(
        (_) async {
          handles.seekCompleted.add(null);
        },
      );
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: 'recitation');
      await service.openAndSeekTo(
        _track,
        fadeIn: Duration.zero,
        owner: 'recitation',
      );

      verify(() => handles.player.setAbLoopA(null)).called(1);
      verify(() => handles.player.setAbLoopB(null)).called(1);
      verify(() => handles.player.setAbLoopCount(null)).called(1);
    });
  });
}
