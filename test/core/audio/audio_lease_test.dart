import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/audio/audio_lease.dart';

void main() {
  group('AudioLeaseRegistry', () {
    test('acquire blocks for a different owner, unblocks on release', () async {
      final registry = AudioLeaseRegistry();
      addTearDown(registry.dispose);

      final lease1 = await registry.acquire(owner: 'recitation');
      var acquired2 = false;
      final f2 = registry.acquire(owner: 'adhan').then((lease) {
        acquired2 = true;
        return lease;
      });

      // A contended acquire must not complete while the lease is held.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(acquired2, isFalse);
      expect(registry.currentOwner, 'recitation');

      lease1.release();
      final lease2 = await f2;
      expect(acquired2, isTrue);
      expect(registry.currentOwner, 'adhan');
      lease2.release();
      expect(registry.currentOwner, isNull);
    });

    test('waiter queue does not miss a release that races the wait loop',
        () async {
      final registry = AudioLeaseRegistry();
      addTearDown(registry.dispose);

      final lease1 = await registry.acquire(owner: 'recitation');

      // Schedule release in the same event-loop turn as the contended acquire
      // starts waiting — the old broadcast `.first` pattern could miss this.
      final f2 = registry.acquire(owner: 'adhan');
      lease1.release();

      final lease2 = await f2.timeout(const Duration(seconds: 2));
      expect(registry.currentOwner, 'adhan');
      lease2.release();
    });

    test('force acquire steals from another owner without waiting', () async {
      final registry = AudioLeaseRegistry();
      addTearDown(registry.dispose);

      await registry.acquire(owner: 'recitation');
      expect(registry.currentOwner, 'recitation');

      final adhanLease =
          await registry.acquire(owner: 'adhan', force: true);
      expect(registry.currentOwner, 'adhan');

      adhanLease.release();
      expect(registry.currentOwner, isNull);
    });

    test('same-owner acquire renews one token; stale release is a no-op',
        () async {
      final registry = AudioLeaseRegistry();
      addTearDown(registry.dispose);

      final stale = await registry.acquire(owner: 'recitation');
      final current = await registry.acquire(owner: 'recitation');
      expect(registry.currentOwner, 'recitation');

      // Stale token must not clear the renewed hold.
      stale.release();
      expect(registry.currentOwner, 'recitation');

      current.release();
      expect(registry.currentOwner, isNull);
    });

    test('same-owner reentrancy does not shorten the watchdog', () {
      FakeAsync().run((fa) {
        String? releasedOwner;
        final registry = AudioLeaseRegistry(
          watchdogTimeout: const Duration(milliseconds: 100),
          onWatchdogForceRelease: (owner) => releasedOwner = owner,
        );

        // Fresh acquire arms the watchdog with a 100ms deadline (fires at
        // t=100). acquire() completes synchronously for an idle registry, so
        // no awaiting inside the fake zone is needed (await would deadlock).
        unawaited(registry.acquire(owner: 'recitation'));
        fa.flushMicrotasks();
        expect(registry.currentOwner, 'recitation');
        expect(releasedOwner, isNull);

        // Advance halfway — before the original deadline. The watchdog must
        // NOT have fired yet.
        fa
          ..elapse(const Duration(milliseconds: 50))
          ..flushMicrotasks();
        expect(releasedOwner, isNull);
        expect(registry.currentOwner, 'recitation');

        // Reentrant same-owner acquire must complete immediately and must NOT
        // restart the watchdog. If it did, the new deadline would be t=150
        // (50 + 100) rather than the original t=100.
        unawaited(registry.acquire(owner: 'recitation'));
        fa.flushMicrotasks();
        expect(registry.currentOwner, 'recitation');
        expect(releasedOwner, isNull);

        // Elapse just past the ORIGINAL deadline (t=110) but well before the
        // hypothetical restarted deadline (t=150). The watchdog must already
        // have fired at t=100 — proving the reentrant acquire preserved the
        // original deadline rather than resetting it.
        fa
          ..elapse(const Duration(milliseconds: 60)) // total elapsed: 110ms
          ..flushMicrotasks();

        expect(releasedOwner, 'recitation');
        expect(registry.currentOwner, isNull);

        unawaited(registry.dispose());
      });
    });

    test('dispose auto-releases and cleans up', () async {
      final registry = AudioLeaseRegistry();
      await registry.acquire(owner: 'recitation');
      expect(registry.currentOwner, 'recitation');

      // Must not throw and must clear the owner + cancel the watchdog.
      await registry.dispose();

      expect(registry.currentOwner, isNull);
      // Calling dispose again is idempotent.
      await registry.dispose();
      expect(registry.currentOwner, isNull);
    });

    test('keepAlive resets watchdog during active playback', () {
      FakeAsync().run((fa) {
        String? releasedOwner;
        final registry = AudioLeaseRegistry(
          watchdogTimeout: const Duration(milliseconds: 100),
          onWatchdogForceRelease: (owner) => releasedOwner = owner,
        );

        unawaited(registry.acquire(owner: 'recitation'));
        fa.flushMicrotasks();

        fa.elapse(const Duration(milliseconds: 80));
        registry.keepAlive(owner: 'recitation');
        fa.flushMicrotasks();

        fa.elapse(const Duration(milliseconds: 80));
        fa.flushMicrotasks();

        expect(releasedOwner, isNull);
        expect(registry.currentOwner, 'recitation');

        unawaited(registry.dispose());
      });
    });

    test('watchdog force-releases an unattended lease', () {
      FakeAsync().run((fa) {
        String? releasedOwner;
        final registry = AudioLeaseRegistry(
          watchdogTimeout: const Duration(milliseconds: 100),
          onWatchdogForceRelease: (owner) => releasedOwner = owner,
        );

        unawaited(registry.acquire(owner: 'recitation'));
        fa.flushMicrotasks();
        expect(registry.currentOwner, 'recitation');

        fa
          ..elapse(const Duration(milliseconds: 110))
          ..flushMicrotasks();

        expect(releasedOwner, 'recitation');
        expect(registry.currentOwner, isNull);

        unawaited(registry.dispose());
      });
    });

    test('dispose during contended acquire throws rather than deadlocks',
        () async {
      final registry = AudioLeaseRegistry();

      await registry.acquire(owner: 'recitation');
      // A second acquire for a different owner blocks on the waiter queue.
      Object? thrown;
      // On rejection we need a placeholder lease matching the return type;
      // produce one from a throwaway registry so the test never depends on
      // the private AudioLease._ constructor.
      final placeholder = AudioLeaseRegistry().acquire(owner: 'adhan');
      final f2 = registry.acquire(owner: 'adhan').catchError(
        (Object e) {
          thrown = e;
          return placeholder;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(thrown, isNull); // still blocked

      // Disposing mid-wait must not deadlock: the blocked acquire rejects.
      await registry.dispose();
      await f2;
      expect(thrown, isA<StateError>());
    });
  });
}
