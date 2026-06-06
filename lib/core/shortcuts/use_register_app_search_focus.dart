import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/core/shortcuts/app_search_focus_registry.dart';

/// Registers [handler] with [AppSearchFocusRegistry] while [enabled] is true.
void useRegisterAppSearchFocus(VoidCallback handler, {bool enabled = true}) {
  useEffect(() {
    if (!enabled) {
      return null;
    }
    AppSearchFocusRegistry.instance.register(handler);
    return () => AppSearchFocusRegistry.instance.unregister(handler);
  }, [handler, enabled]);
}
