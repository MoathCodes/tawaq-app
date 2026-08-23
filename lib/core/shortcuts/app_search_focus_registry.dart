import 'package:flutter/foundation.dart';

/// Route-local handler invoked by the global `Ctrl+K` shortcut.
typedef AppSearchFocusHandler = VoidCallback;

/// Registers the active screen's search-focus action.
///
/// Only one handler is active at a time; the most recently mounted screen wins.
class AppSearchFocusRegistry {
  new _();

  /// Shared registry instance.
  static final AppSearchFocusRegistry instance = AppSearchFocusRegistry._();

  AppSearchFocusHandler? _handler;

  /// Registers [handler] as the active search-focus callback.
  void register(AppSearchFocusHandler handler) {
    _handler = handler;
  }

  /// Unregisters [handler] if it is still the active callback.
  void unregister(AppSearchFocusHandler handler) {
    if (_handler == handler) {
      _handler = null;
    }
  }

  /// Invokes the active handler. Returns false when no screen registered one.
  bool focus() {
    final handler = _handler;
    if (handler == null) {
      return false;
    }
    handler();
    return true;
  }
}
