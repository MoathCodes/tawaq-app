import 'dart:async';

/// Lease owner for Quran recitation playback.
const kRecitationLeaseOwner = 'recitation';

/// Lease owner for adhan / iqamah alert sound.
const kAdhanLeaseOwner = 'adhan';

/// Lightweight ownership token returned by [AudioLeaseRegistry.acquire].
///
/// Same-owner re-acquire renews a single generation: only the latest token
/// can release. Stale tokens from earlier same-owner acquires are no-ops.
final class AudioLease {
  new _(this.owner, this._generation, this._releaseIfCurrent);

  /// Logical owner identifier (e.g. 'recitation', 'adhan').
  final String owner;

  final int _generation;
  final void Function(int generation) _releaseIfCurrent;

  /// Releases the lease when this token is still the active generation.
  /// Safe to call multiple times; stale tokens are no-ops.
  void release() => _releaseIfCurrent(_generation);
}

/// Pure async-coordination ownership lease.
///
/// Has no mpv dependency — unit-testable in isolation. Contended [acquire]
/// waits on an explicit Completer queue (not a broadcast stream) so a release
/// that races the wait-loop check cannot be missed. The audio service
/// composes one instance to keep playback ownership decoupled from mpv.
class AudioLeaseRegistry {
  /// Creates a registry.
  ///
  /// The [watchdogTimeout] bounds how long an owner may hold an unattended
  /// lease before [onWatchdogForceRelease] is invoked and the lease is
  /// force-released. Defaults to 30 seconds.
  new({
    this.watchdogTimeout = const Duration(seconds: 30),
    this.onWatchdogForceRelease,
  });

  /// Maximum time an owner may hold an unattended lease before the watchdog
  /// force-releases it.
  final Duration watchdogTimeout;

  /// Invoked immediately before the watchdog force-releases an unattended
  /// lease. May be null; in that case the lease is still force-released but no
  /// notification is emitted.
  final void Function(String owner)? onWatchdogForceRelease;

  final _waiters = <Completer<void>>[];
  Timer? _watchdog;
  String? _owner;
  int _generation = 0;
  bool _disposed = false;

  /// Current lease owner, or null when idle.
  String? get currentOwner => _owner;

  /// True when [owner] currently holds an active lease.
  bool hasValidLease(String owner) => _owner == owner;

  /// Resets the watchdog deadline for [owner] while it holds the lease.
  ///
  /// Call periodically during active playback so long sessions are not
  /// force-released by the unattended-lease watchdog.
  void keepAlive({required String owner}) {
    if (_disposed || _owner != owner) return;
    _armWatchdog(owner);
  }

  /// Acquires exclusive ownership of the lease.
  ///
  /// If another owner currently holds the lease, this call waits on a Completer
  /// queue until it is released or the watchdog force-releases it. When
  /// [force] is true, any other owner is released immediately so the caller
  /// never blocks (used by prayer alerts that must not hang the coordinator
  /// queue).
  ///
  /// Same-owner re-acquire renews one token generation (re-arms the watchdog)
  /// without stacking dual-release handles — only the latest token releases.
  ///
  /// Returns a lease token whose [AudioLease.release] releases the registry
  /// when it is still the active generation.
  Future<AudioLease> acquire({
    required String owner,
    bool force = false,
  }) async {
    if (force && _owner != null && _owner != owner) {
      releaseCurrent();
    }

    while (!_disposed && _owner != null && _owner != owner) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }

    if (_disposed) {
      throw StateError('AudioLeaseRegistry disposed during acquire');
    }

    if (_owner == owner) {
      // Renew one token: bump generation so prior tokens no-op. Do not restart
      // the watchdog — that preserves the original unattended deadline; callers
      // that need extension use [keepAlive].
      _generation++;
      return AudioLease._(owner, _generation, _releaseIfCurrent);
    }

    _generation++;
    _owner = owner;
    _armWatchdog(owner);
    return AudioLease._(owner, _generation, _releaseIfCurrent);
  }

  void _releaseIfCurrent(int generation) {
    if (_disposed || _generation != generation || _owner == null) return;
    releaseCurrent();
  }

  void _armWatchdog(String owner) {
    _watchdog?.cancel();
    _watchdog = Timer(watchdogTimeout, () {
      if (_owner == owner) {
        onWatchdogForceRelease?.call(owner);
        releaseCurrent();
      }
    });
  }

  /// Releases the current lease. Idempotent: safe to call when idle or after a
  /// prior release. Cancels the watchdog, clears the owner, and wakes waiters.
  void releaseCurrent() {
    _watchdog?.cancel();
    _watchdog = null;
    _owner = null;
    _wakeWaiters();
  }

  void _wakeWaiters() {
    if (_waiters.isEmpty) return;
    final pending = List<Completer<void>>.of(_waiters);
    _waiters.clear();
    for (final waiter in pending) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  /// Cancels the watchdog, clears the owner, wakes waiters, and marks disposed.
  /// Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _watchdog?.cancel();
    _watchdog = null;
    _owner = null;
    _wakeWaiters();
  }
}
