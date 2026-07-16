import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
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

  group('openAndSeekTo', () {
    test('waits for file load before seeking', () async {
      final handles = buildFakeAudioPlayer();
      final seekCalls = <Duration>[];
      var openCompleted = false;

      when(() => handles.player.open(any(), play: any(named: 'play'))).thenAnswer(
        (_) async {
          openCompleted = true;
        },
      );
      when(
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      ).thenAnswer((inv) async {
        seekCalls.add(inv.positionalArguments[0] as Duration);
        handles.seekCompleted.add(null);
      });

      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
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

      handles.seekCompleted.add(null);
      await done;

      expect(seekCalls, [const Duration(seconds: 30)]);
      verify(handles.player.play).called(1);
    });

    test('skips seek when start is zero', () async {
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

      await service.acquire(owner: 'test');

      await service.openAndSeekTo(
        _track,
        fadeIn: Duration.zero,
        owner: 'test',
      );

      verifyNever(
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
      verify(handles.player.play).called(1);
    });
  });

  group('seek', () {
    test('returns false when no track is loaded', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      final ok = await service.seek(
        const Duration(seconds: 10),
        owner: 'test',
      );

      expect(ok, isFalse);
      verifyNever(
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
    });

    test('seeks when a track is active', () async {
      final handles = buildFakeAudioPlayer();
      when(
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      ).thenAnswer((_) async {
        handles.seekCompleted.add(null);
      });
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
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
        () => handles.player.seek(
          const Duration(seconds: 15),
          relative: any(named: 'relative'),
          exact: true,
        ),
      ).called(1);
    });

    test('deleteResumeConfig called before openAndSeekTo load', () async {
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

      await service.acquire(owner: 'test');
      await service.openAndSeekTo(
        _track,
        fadeIn: Duration.zero,
        owner: 'test',
      );
      verify(
        () => handles.player.deleteResumeConfig(filename: any(named: 'filename')),
      ).called(1);
    });

    test('returns false after stop clears the active track', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
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
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
    });

    test('re-acquires idle lease when track is still loaded', () async {
      final handles = buildFakeAudioPlayer();
      when(
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      ).thenAnswer((_) async {
        handles.seekCompleted.add(null);
      });
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: kRecitationLeaseOwner);
      await service.play(
        _track,
        fadeIn: Duration.zero,
        owner: kRecitationLeaseOwner,
      );
      await service.release(owner: kRecitationLeaseOwner);

      expect(service.currentLeaseOwner, isNull);
      expect(service.hasActiveTrack, isTrue);

      final ok = await service.seek(
        const Duration(seconds: 5),
        owner: kRecitationLeaseOwner,
      );

      expect(ok, isTrue);
      expect(service.currentLeaseOwner, kRecitationLeaseOwner);
      verify(
        () => handles.player.seek(
          const Duration(seconds: 5),
          relative: any(named: 'relative'),
          exact: true,
        ),
      ).called(1);
    });

    test('returns false when another owner holds the lease', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.acquire(owner: kAdhanLeaseOwner);
      await service.play(
        _track,
        fadeIn: Duration.zero,
        owner: kAdhanLeaseOwner,
      );

      final ok = await service.seek(
        const Duration(seconds: 5),
        owner: kRecitationLeaseOwner,
      );

      expect(ok, isFalse);
      verifyNever(
        () => handles.player.seek(
          any(),
          relative: any(named: 'relative'),
          exact: any(named: 'exact'),
        ),
      );
    });
  });

  group('lease keepAlive during playback', () {
    test('position ticks refresh lease past watchdog deadline', () {
      FakeAsync().run((fa) {
        final registry = AudioLeaseRegistry(
          
        );
        final handles = buildFakeAudioPlayer(
          initialState: const PlayerState(playWhenReady: true),
        );
        final service = TawaqAudioService(
          player: handles.player,
          leaseRegistry: registry,
        );

        unawaited(() async {
          await service.acquire(owner: kRecitationLeaseOwner);
          await service.play(
            _track,
            fadeIn: Duration.zero,
            owner: kRecitationLeaseOwner,
          );
        }());
        fa.flushMicrotasks();

        expect(registry.currentOwner, kRecitationLeaseOwner);
        expect(service.hasActiveTrack, isTrue);

        for (var i = 0; i < 4; i++) {
          fa.elapse(const Duration(seconds: 11));
          handles.position.add(Duration(seconds: (i + 1) * 11));
          fa.flushMicrotasks();
        }

        expect(registry.currentOwner, kRecitationLeaseOwner);

        unawaited(handles.dispose());
        unawaited(service.dispose());
      });
    });
  });
}
