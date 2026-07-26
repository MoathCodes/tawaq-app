import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';

import 'fake_audio_player.dart';

AudioTrack get _track => AudioTrack.asset(
      id: 't',
      title: 'Track',
      assetPath: 'assets/audio/adhan/default.mp3',
    );

AudioTrack get _otherTrack => AudioTrack.asset(
      id: 't2',
      title: 'Other',
      assetPath: 'assets/audio/adhan/other.mp3',
    );

void main() {
  setUpAll(registerAudioServiceFallbacks);

  group('TawaqAudioService fade + lease transport', () {
    test('cancel mid-fade settles the awaited Completer', () {
      FakeAsync().run((fa) {
        final handles = buildFakeAudioPlayer();
        final service = TawaqAudioService(player: handles.player);

        unawaited(
          service.play(
            _track,
            fadeIn: const Duration(milliseconds: 400),
            owner: 'adhan',
          ),
        );
        fa.flushMicrotasks();

        // Let the fade ramp for a couple of steps, then start a fade-out stop.
        fa
          ..elapse(const Duration(milliseconds: 80))
          ..flushMicrotasks();

        var stopDone = false;
        unawaited(
          service
              .stop(
                fadeOut: const Duration(milliseconds: 400),
                owner: 'adhan',
              )
              .then((_) => stopDone = true),
        );
        fa.flushMicrotasks();

        // Supersede the fade-out with a new play — cancel must settle stop().
        unawaited(
          service.play(
            _otherTrack,
            fadeIn: Duration.zero,
            owner: 'adhan',
          ),
        );
        fa
          ..flushMicrotasks()
          ..elapse(const Duration(milliseconds: 50))
          ..flushMicrotasks();

        expect(stopDone, isTrue);

        unawaited(handles.dispose());
        unawaited(service.dispose());
      });
    });

    test('gated pause/resume reject non-owner', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(
        _track,
        fadeIn: Duration.zero,
        owner: kRecitationLeaseOwner,
      );

      clearInteractions(handles.player);

      expect(await service.pause(owner: kAdhanLeaseOwner), isFalse);
      expect(await service.resume(owner: kAdhanLeaseOwner), isFalse);
      verifyNever(handles.player.pause);
      verifyNever(handles.player.play);

      expect(await service.pause(owner: kRecitationLeaseOwner), isTrue);
      verify(handles.player.pause).called(1);

      expect(await service.resume(owner: kRecitationLeaseOwner), isTrue);
      verify(handles.player.play).called(1);
    });

    test('null-owner and wrong-owner stop are no-ops while adhan holds',
        () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(
        _track,
        fadeIn: Duration.zero,
        owner: kAdhanLeaseOwner,
      );
      expect(service.currentLeaseOwner, kAdhanLeaseOwner);
      expect(service.hasActiveTrack, isTrue);
      clearInteractions(handles.player);

      // Omitted owner must not impersonate the current holder.
      await service.stop();
      expect(service.currentLeaseOwner, kAdhanLeaseOwner);
      expect(service.hasActiveTrack, isTrue);
      verifyNever(handles.player.stop);

      // Recitation owner must not stop an in-flight adhan.
      await service.stop(owner: kRecitationLeaseOwner);
      expect(service.currentLeaseOwner, kAdhanLeaseOwner);
      expect(service.hasActiveTrack, isTrue);
      verifyNever(handles.player.stop);

      // force still reclaims the engine.
      await service.stop(force: true);
      expect(service.currentLeaseOwner, isNull);
      expect(service.hasActiveTrack, isFalse);
      verify(handles.player.stop).called(1);
    });

    test('gated pause/resume reject omitted owner', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(
        _track,
        fadeIn: Duration.zero,
        owner: kAdhanLeaseOwner,
      );
      clearInteractions(handles.player);

      expect(await service.pause(), isFalse);
      expect(await service.resume(), isFalse);
      verifyNever(handles.player.pause);
      verifyNever(handles.player.play);
    });

    test('force steal stops prior session before transfer', () async {
      final handles = buildFakeAudioPlayer();
      final service = TawaqAudioService(player: handles.player);
      addTearDown(() async {
        await handles.dispose();
        await service.dispose();
      });

      await service.play(
        _track,
        fadeIn: Duration.zero,
        owner: kRecitationLeaseOwner,
      );
      expect(service.currentLeaseOwner, kRecitationLeaseOwner);
      expect(service.hasActiveTrack, isTrue);

      await service.play(
        _otherTrack,
        fadeIn: Duration.zero,
        owner: kAdhanLeaseOwner,
        force: true,
      );

      expect(service.currentLeaseOwner, kAdhanLeaseOwner);
      expect(service.hasActiveTrack, isTrue);
      // Prior session was unloaded via steal before the new open.
      verify(handles.player.stop).called(greaterThanOrEqualTo(1));
      verify(
        () => handles.player.open(any(), play: any(named: 'play')),
      ).called(greaterThanOrEqualTo(2));
    });

    test('watchdog clears the engine after force-release', () {
      FakeAsync().run((fa) {
        final handles = buildFakeAudioPlayer();
        final service = TawaqAudioService(
          player: handles.player,
          watchdogTimeout: const Duration(milliseconds: 80),
        );

        unawaited(
          service.play(
            _track,
            fadeIn: Duration.zero,
            owner: kRecitationLeaseOwner,
          ),
        );
        fa.flushMicrotasks();
        expect(service.currentLeaseOwner, kRecitationLeaseOwner);
        expect(service.hasActiveTrack, isTrue);
        clearInteractions(handles.player);

        fa
          ..elapse(const Duration(milliseconds: 100))
          ..flushMicrotasks();

        expect(service.currentLeaseOwner, isNull);
        expect(service.hasActiveTrack, isFalse);
        verify(handles.player.stop).called(1);

        unawaited(handles.dispose());
        unawaited(service.dispose());
      });
    });
  });
}
