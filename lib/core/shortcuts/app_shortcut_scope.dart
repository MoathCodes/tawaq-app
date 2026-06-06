import 'package:flutter/material.dart';
import 'package:forui/forui.dart' show FPopoverController;
import 'package:forui/widgets/popover.dart' show FPopoverController;
import 'package:tawaq/core/shortcuts/app_shortcut_bindings.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// Binds a set of registry shortcuts to keyboard activators.
///
/// Uses Flutter's [CallbackShortcuts] with an optional [Focus] wrapper — the
/// same pattern as pre-engine Quran/Fortress shortcuts. Screen-specific focus
/// (search fields, popovers) is delegated to Forui widgets via their own
/// [FocusNode] / [FPopoverController] APIs, not managed here.
class AppShortcutScope extends StatefulWidget {
  /// Creates a shortcut scope.
  const AppShortcutScope({
    required this.shortcuts,
    required this.handlers,
    required this.child,
    super.key,
    this.autofocus = false,
    this.shouldIgnore,
  });

  /// Shortcut IDs active in this scope.
  final Set<AppShortcutId> shortcuts;

  /// Handlers keyed by [AppShortcutId].
  final Map<AppShortcutId, VoidCallback> handlers;

  /// Child widget tree.
  final Widget child;

  /// Whether the inner [Focus] node requests focus on mount.
  final bool autofocus;

  /// When true, all shortcuts in this scope are ignored.
  final bool Function()? shouldIgnore;

  @override
  State<AppShortcutScope> createState() => _AppShortcutScopeState();
}

class _AppShortcutScopeState extends State<AppShortcutScope> {
  Map<ShortcutActivator, VoidCallback>? _bindings;
  Set<AppShortcutId>? _boundShortcuts;

  @override
  Widget build(BuildContext context) {
    if (!supportsKeyboardShortcuts) {
      return widget.child;
    }

    _ensureBindings();

    final bindings = _bindings;
    if (bindings == null || bindings.isEmpty) {
      return widget.child;
    }

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(
        autofocus: widget.autofocus,
        child: widget.child,
      ),
    );
  }

  void _ensureBindings() {
    if (_bindings != null && _setEquals(_boundShortcuts, widget.shortcuts)) {
      return;
    }

    _boundShortcuts = Set<AppShortcutId>.from(widget.shortcuts);
    _bindings = buildAppShortcutBindings(
      shortcuts: widget.shortcuts,
      handlers: {
        for (final id in widget.shortcuts)
          id: () => widget.handlers[id]?.call(),
      },
      shouldSuppress: (definition) {
        if (widget.shouldIgnore?.call() ?? false) return true;
        return shouldSuppressForTextFieldFocus(definition);
      },
    );
  }

  bool _setEquals(Set<AppShortcutId>? a, Set<AppShortcutId> b) {
    if (a == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
