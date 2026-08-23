import 'package:flutter/foundation.dart';

/// A cooperative cancellation token. Once canceled it cannot be un-canceled.
///
/// Long-running operations check [isCancelled] between units of work, or
/// register callbacks via [onCancel] for snappier interruption.
class CancellationToken {
  /// Creates a [CancellationToken].
  new();

  bool _cancelled = false;
  final List<VoidCallback> _callbacks = [];

  /// Whether [cancel] has been called.
  bool get isCancelled => _cancelled;

  /// Marks the token as canceled and fires registered callbacks. Subsequent
  /// calls are no-ops. Callback failures are swallowed so one failing listener
  /// does not block others.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final cb in List<VoidCallback>.of(_callbacks)) {
      try {
        cb();
      } on Object {
        // Swallow: a failing cancel listener must not block others.
      }
    }
    _callbacks.clear();
  }

  /// Registers [callback] to run when [cancel] is called. If already canceled,
  /// [callback] runs immediately.
  void onCancel(VoidCallback callback) {
    if (_cancelled) {
      callback();
      return;
    }
    _callbacks.add(callback);
  }
}

/// A [CancellationToken] that can never be canceled.
final CancellationToken neverCancelToken = CancellationToken();
