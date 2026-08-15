import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_playback_policy.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_seek_pipeline.dart';

void main() {
  group('SeekPipeline', () {
    late List<Duration> seeks;
    late List<({Duration revertTo, Duration failedTarget})> failed;
    late List<Duration> timedOut;
    late Duration lastAccepted;
    late bool hasPending;
    late SeekPipeline pipeline;

    setUp(() {
      seeks = <Duration>[];
      failed = <({Duration revertTo, Duration failedTarget})>[];
      timedOut = <Duration>[];
      lastAccepted = Duration.zero;
      hasPending = false;
      pipeline = SeekPipeline(
        log: (_) {},
        seek: (position) async {
          seeks.add(position);
          return true;
        },
        onSeekFailed:
            ({
              required revertTo,
              required failedTarget,
            }) {
              failed.add((revertTo: revertTo, failedTarget: failedTarget));
            },
        onTimeout: ({required revertTo}) {
          timedOut.add(revertTo);
          hasPending = false;
        },
        lastAcceptedPosition: () => lastAccepted,
        hasPendingSeek: () => hasPending,
      );
    });

    tearDown(() {
      pipeline.dispose();
    });

    test('landsPending uses 500ms tolerance', () {
      const pending = Duration(seconds: 10);
      expect(
        SeekPipeline.landsPending(
          position: const Duration(milliseconds: 10499),
          pending: pending,
        ),
        isTrue,
      );
      expect(
        SeekPipeline.landsPending(
          position: const Duration(milliseconds: 10501),
          pending: pending,
        ),
        isFalse,
      );
      expect(pendingSeekToleranceMs, 500);
    });

    test('inTrack seek clears deferred and calls engine', () async {
      await pipeline.request(
        const Duration(seconds: 3),
        mode: SeekRequestMode.deferUntilLoaded,
      );
      expect(pipeline.hasDeferred, isTrue);

      await pipeline.request(
        const Duration(seconds: 5),
        mode: SeekRequestMode.inTrack,
      );
      expect(seeks, [const Duration(seconds: 5)]);
      expect(pipeline.hasDeferred, isFalse);
      expect(failed, isEmpty);
    });

    test('inTrack seek failure reports SeekFailed with failedTarget', () async {
      pipeline = SeekPipeline(
        log: (_) {},
        seek: (_) async => false,
        onSeekFailed:
            ({
              required revertTo,
              required failedTarget,
            }) {
              failed.add((revertTo: revertTo, failedTarget: failedTarget));
            },
        onTimeout: ({required revertTo}) {
          timedOut.add(revertTo);
        },
        lastAcceptedPosition: () => const Duration(seconds: 2),
        hasPendingSeek: () => hasPending,
      );

      const target = Duration(seconds: 9);
      await pipeline.request(target, mode: SeekRequestMode.inTrack);
      expect(failed, [
        (revertTo: const Duration(seconds: 2), failedTarget: target),
      ]);
    });

    test('flushDeferred applies scrub queued during load', () async {
      await pipeline.request(
        const Duration(seconds: 7),
        mode: SeekRequestMode.deferUntilLoaded,
      );
      expect(pipeline.deferredTarget, const Duration(seconds: 7));

      await pipeline.flushDeferred();
      expect(seeks, [const Duration(seconds: 7)]);
      expect(pipeline.hasDeferred, isFalse);

      await pipeline.flushDeferred();
      expect(seeks, [const Duration(seconds: 7)]);
    });

    test('timeout reverts after 2s without clearing activity', () async {
      hasPending = true;
      lastAccepted = const Duration(seconds: 1);
      pipeline.syncTimeout();

      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(timedOut, [const Duration(seconds: 1)]);
    });

    test('timeout restarts on activity (dispatch restart rule)', () async {
      hasPending = true;
      lastAccepted = const Duration(seconds: 4);
      pipeline.syncTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      pipeline.syncTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(timedOut, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(timedOut, [const Duration(seconds: 4)]);
    });

    test('syncTimeout cancels when pending clears', () async {
      hasPending = true;
      pipeline.syncTimeout();
      hasPending = false;
      pipeline.syncTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(timedOut, isEmpty);
    });

    test('clear drops deferred and timeout', () async {
      hasPending = true;
      await pipeline.request(
        const Duration(seconds: 8),
        mode: SeekRequestMode.deferUntilLoaded,
      );
      pipeline.syncTimeout();
      final genBefore = pipeline.generation;
      pipeline.clear();
      expect(pipeline.hasDeferred, isFalse);
      expect(pipeline.generation, genBefore + 1);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(timedOut, isEmpty);
    });

    test(
      'PlaySurah/Stop-style clear prevents orphaned scrub flush on new track',
      () async {
        await pipeline.request(
          const Duration(seconds: 12),
          mode: SeekRequestMode.deferUntilLoaded,
        );
        expect(pipeline.hasDeferred, isTrue);

        // New PlaySurah / Stop abandons the scrub-during-load slot.
        pipeline.clear();
        expect(pipeline.hasDeferred, isFalse);

        await pipeline.flushDeferred();
        expect(seeks, isEmpty);
      },
    );

    test(
      'clear during in-flight seek skips failure handling (AlertSuspend)',
      () async {
        final completer = Completer<bool>();
        pipeline = SeekPipeline(
          log: (_) {},
          seek: (_) => completer.future,
          onSeekFailed:
              ({
                required revertTo,
                required failedTarget,
              }) {
                failed.add((revertTo: revertTo, failedTarget: failedTarget));
              },
          onTimeout: ({required revertTo}) {},
          lastAcceptedPosition: () => Duration.zero,
          hasPendingSeek: () => true,
        );

        final inflight = pipeline.request(
          const Duration(seconds: 3),
          mode: SeekRequestMode.inTrack,
        );
        // Suspend critical section clears while engine seek is awaiting.
        pipeline.clear();
        completer.complete(false);
        await inflight;

        expect(failed, isEmpty);
      },
    );

    test(
      'older seek failure must not clear newer pending (failedTarget gate)',
      () async {
        final completerA = Completer<bool>();
        var pending = const Duration(seconds: 1);
        final reverted = <Duration>[];

        pipeline = SeekPipeline(
          log: (_) {},
          seek: (position) async {
            if (position == const Duration(seconds: 1)) {
              return completerA.future;
            }
            return true;
          },
          onSeekFailed:
              ({
                required revertTo,
                required failedTarget,
              }) {
                if (!shouldRevertPendingSeek(
                  currentPending: pending,
                  failedTarget: failedTarget,
                )) {
                  return;
                }
                reverted.add(failedTarget);
                pending = Duration.zero; // cleared
              },
          onTimeout: ({required revertTo}) {},
          lastAcceptedPosition: () => Duration.zero,
          hasPendingSeek: () => pending > Duration.zero,
        );

        // Older seek A in flight…
        final older = pipeline.request(
          const Duration(seconds: 1),
          mode: SeekRequestMode.inTrack,
        );
        // Newer seek B supersedes pending UI.
        pending = const Duration(seconds: 2);
        await pipeline.request(
          const Duration(seconds: 2),
          mode: SeekRequestMode.inTrack,
        );

        // A fails after B landed pending — must not wipe B.
        completerA.complete(false);
        await older;

        expect(reverted, isEmpty);
        expect(pending, const Duration(seconds: 2));
      },
    );
  });

  group('shouldRevertPendingSeek', () {
    test('matches failed target only', () {
      expect(
        shouldRevertPendingSeek(
          currentPending: const Duration(seconds: 5),
          failedTarget: const Duration(seconds: 5),
        ),
        isTrue,
      );
      expect(
        shouldRevertPendingSeek(
          currentPending: const Duration(seconds: 9),
          failedTarget: const Duration(seconds: 5),
        ),
        isFalse,
      );
      expect(
        shouldRevertPendingSeek(
          currentPending: null,
          failedTarget: const Duration(seconds: 5),
        ),
        isFalse,
      );
    });
  });

  group('chainEffectsTail', () {
    test(
      'serializes session seek work with load/SeekAudio-style batches',
      () async {
        final order = <String>[];
        var tail = Future<void>.value();

        Future<void> enqueue(String label, int delayMs) {
          return tail = chainEffectsTail(tail, () async {
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            order.add(label);
          });
        }

        // Mimic machine LoadSurah (slow) then UI _seekSession enqueue.
        final load = enqueue('load', 40);
        final seek = enqueue('sessionSeek', 1);
        await Future.wait([load, seek]);

        expect(order, ['load', 'sessionSeek']);
      },
    );

    test(
      'suspend critical section drains seeks then release; queued seek skips',
      () async {
        final order = <String>[];
        var tail = Future<void>.value();
        var suspended = false;
        Duration? pending = const Duration(seconds: 5);
        final engineSeeks = <Duration>[];

        Future<void> enqueue(Future<void> Function() work) {
          return tail = chainEffectsTail(tail, work);
        }

        // In-flight session seek (slow).
        final seekWork = enqueue(() async {
          order.add('seekStart');
          await Future<void>.delayed(const Duration(milliseconds: 30));
          if (suspended || pending == null) {
            order.add('seekSkipped');
            return;
          }
          engineSeeks.add(pending);
          order.add('seekDone');
        });

        // AlertSuspend: state first (clear pending), then mutex critical section.
        suspended = true;
        pending = null;
        final suspendWork = enqueue(() async {
          order.add('clear');
          order.add('pause');
          order.add('release');
        });

        // Late scrub enqueued after suspend — must not seek post-release.
        final lateSeek = enqueue(() async {
          if (suspended || pending == null) {
            order.add('lateSeekSkipped');
            return;
          }
          engineSeeks.add(pending);
          order.add('lateSeekDone');
        });

        await Future.wait([seekWork, suspendWork, lateSeek]);

        expect(order, [
          'seekStart',
          'seekSkipped',
          'clear',
          'pause',
          'release',
          'lateSeekSkipped',
        ]);
        expect(engineSeeks, isEmpty);
      },
    );

    test(
      'HighlightAyah applies after SeekAudio/LoadAyahLoop on I/O path',
      () async {
        final order = <String>[];
        // Mirrors controller peel: only sleep/persist are local; Highlight is I/O.
        const effects = [
          'SeekAudio',
          'LoadAyahLoop',
          'HighlightAyah',
          'PersistPlaybackState',
        ];
        final local = effects
            .where(
              (e) => e == 'PersistPlaybackState' || e == 'CancelSleepTimer',
            )
            .toList();
        final io = effects.where((e) => !local.contains(e)).toList();

        for (final effect in local) {
          order.add('local:$effect');
        }
        for (final effect in io) {
          await Future<void>.delayed(Duration.zero);
          order.add('io:$effect');
        }

        expect(order, [
          'local:PersistPlaybackState',
          'io:SeekAudio',
          'io:LoadAyahLoop',
          'io:HighlightAyah',
        ]);
        expect(
          io.indexOf('HighlightAyah'),
          greaterThan(io.indexOf('SeekAudio')),
        );
        expect(
          io.indexOf('HighlightAyah'),
          greaterThan(io.indexOf('LoadAyahLoop')),
        );
      },
    );
  });
}
