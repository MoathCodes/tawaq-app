import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// A [TapGestureRecognizer] that also fires a long-press callback.
///
/// This is designed for use with [TextSpan.recognizer], where only a single
/// [GestureRecognizer] can be attached to a span.
///
/// Behavior:
/// - Starts a timer on tap down.
/// - Fires [onLongPress] after [longPressTimeout] if the pointer is still down.
/// - Fires [onTap] on release only if long-press did not fire.
/// - Cancels on movement/cancel (i.e., when the recognizer loses the arena).
class TapAndLongPressGestureRecognizer extends TapGestureRecognizer {
  TapAndLongPressGestureRecognizer({super.debugOwner});

  Duration longPressTimeout = kLongPressTimeout;

  VoidCallback? onLongPress;

  Timer? _timer;
  bool _longPressFired = false;

  void _startTimer() {
    _timer?.cancel();
    _longPressFired = false;
    if (onLongPress == null) return;

    _timer = Timer(longPressTimeout, () {
      _longPressFired = true;
      onLongPress?.call();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  /// Wires internal timer behavior into the public callbacks.
  ///
  /// Call this once right after creating the recognizer.
  void configure({
    required VoidCallback? onTap,
    required VoidCallback? onLong,
  }) {
    onLongPress = onLong;

    // Start/stop timer based on tap lifecycle.
    onTapDown = (_) => _startTimer();
    onTapCancel = () {
      _cancelTimer();
      _longPressFired = false;
    };

    // Only fire tap if we didn't already long-press.
    this.onTap = () {
      _cancelTimer();
      if (_longPressFired) return;
      onTap?.call();
    };

    // Ensure timer is cleared on up as well.
    onTapUp = (_) => _cancelTimer();
  }
}
