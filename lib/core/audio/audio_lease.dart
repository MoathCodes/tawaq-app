import 'dart:async';

/// Lease owner for Quran recitation playback.
const kRecitationLeaseOwner = 'recitation';

/// Lease owner for adhan / iqamah alert sound.
const kAdhanLeaseOwner = 'adhan';

/// Lightweight ownership token returned by [AudioLeaseRegistry.acquire].
///
/// The token is a thin callback handle: calling [release] releases the lease
/// that produced it. Safe to call multiple times.
final class AudioLease {
  AudioLease._(this.owner, this._release);

  /// Logical owner identifier (e.g. 'recitation', 'adhan').
  final String owner;

  final void Function() _release;

  /// Releases the lease. Safe to call multiple times.
  void release() => _release();
}

/// Pure async-coordination ownership lease over a broadcast stream.
///
/// Has no mpv dependency — unit-testable in isolation. [acquire] blocks while
/// another owner holds the lease and unblocks when it is released or the
/// watchdog force-releases it. The audio service composes one instance to
/// keep its playback ownership logic decoupled from the native player.
class AudioLeaseRegistry {
  /// Creates a registry.
  ///
  /// The [watchdogTimeout] bounds how long an owner may hold an unattended
  /// lease before [onWatchdogForceRelease] is invoked and the lease is
  /// force-released. Defaults to 30 seconds.
  AudioLeaseRegistry({
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

  final _controller = StreamController<void>.broadcast();
  Timer? _watchdog;
  String? _owner;
  bool _disposed = false;

  /// Stream that fires on every acquire/release (for contended callers).
  Stream<void> get leaseStream => _controller.stream;

  /// Current lease owner, or null when idle.
  String? get currentOwner => _owner;

  /// True when [owner] currently holds an active lease.
  bool hasValidLease(String owner) => _owner == owner;

  /// Acquires exclusive ownership of the lease.
  ///
  /// If another owner currently holds the lease, this call waits (blocking on
  /// [leaseStream]) until it is released or the watchdog force-releases it.
  /// Reentrant acquires for the *same* owner return immediately with a new
  /// [AudioLease] token WITHOUT restarting the watchdog — this preserves the
  /// original deadline for the in-flight owner.
  ///
  /// Returns a lease token whose [AudioLease.release] releases the registry.
  Future<AudioLease> acquire({required String owner}) async {
    // Wait while another owner holds the lease. Guard against disposal mid-wait
    // so a contended acquire never deadlocks or throws on a closed stream.
    while (!_disposed && _owner != null && _owner != owner) {
      await _controller.stream.first;
    }
    if (_disposed) {
      throw StateError('AudioLeaseRegistry disposed during acquire');
    }
    if (_owner != owner) {
      // Fresh acquire (idle or different owner): (re)arm the watchdog.
      _watchdog?.cancel();
      _owner = owner;
      _controller.add(null);
      _watchdog = Timer(watchdogTimeout, () {
        if (_owner == owner) {
          onWatchdogForceRelease?.call(owner);
          releaseCurrent();
        }
      });
    }
    return AudioLease._(owner, releaseCurrent);
  }

  /// Releases the current lease. Idempotent: safe to call when idle or after a
  /// prior release. Cancels the watchdog, clears the owner, and emits.
  void releaseCurrent() {
    _watchdog?.cancel();
    _watchdog = null;
    _owner = null;
    _controller.add(null);
  }

  /// Cancels the watchdog, clears the owner, and closes the lease stream.
  /// Idempotent.
  Future<void> dispose() async {
    _disposed = true;
    _watchdog?.cancel();
    _watchdog = null;
    _owner = null;
    await _controller.close();
  }
}
