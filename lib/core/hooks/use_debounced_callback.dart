import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Default debounce interval for user input (search, filters, etc.).
const kAppDebounceDuration = Duration(milliseconds: 400);

/// Debounced [call] with an explicit [cancel] for pending timers.
final class DebouncedCallback {
  new _({
    required this._schedule,
    required this.cancel,
  });

  final VoidCallback _schedule;

  /// Cancels any pending timer without invoking the callback.
  final VoidCallback cancel;

  /// Schedules (or reschedules) the debounced callback.
  void call() => _schedule();
}

/// Returns a debounced version of [callback] that resets on each invocation.
///
/// The debounce [duration] defaults to [kAppDebounceDuration]. Pending timers
/// are cancelled when the owning widget disposes. Call [DebouncedCallback.cancel]
/// to drop a pending invocation (e.g. when syncing the field from external state).
DebouncedCallback useDebouncedCallback(
  VoidCallback callback, {
  Duration duration = kAppDebounceDuration,
}) {
  final timer = useRef<Timer?>(null);

  useEffect(
    () => () => timer.value?.cancel(),
    const [],
  );

  final schedule = useCallback(
    () {
      timer.value?.cancel();
      timer.value = Timer(duration, callback);
    },
    [callback, duration],
  );

  final cancel = useCallback(
    () {
      timer.value?.cancel();
      timer.value = null;
    },
    const [],
  );

  return DebouncedCallback._(schedule: schedule, cancel: cancel);
}
