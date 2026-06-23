import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Default debounce interval for user input (search, filters, etc.).
const kAppDebounceDuration = Duration(milliseconds: 400);

/// Returns a debounced version of [callback] that resets on each invocation.
///
/// The debounce [duration] defaults to [kAppDebounceDuration]. Pending timers
/// are cancelled when the owning widget disposes.
VoidCallback useDebouncedCallback(
  VoidCallback callback, {
  Duration duration = kAppDebounceDuration,
}) {
  final timer = useRef<Timer?>(null);

  useEffect(
    () => () => timer.value?.cancel(),
    const [],
  );

  return useCallback(
    () {
      timer.value?.cancel();
      timer.value = Timer(duration, callback);
    },
    [callback, duration],
  );
}
