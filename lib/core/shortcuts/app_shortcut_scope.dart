import 'package:flutter/material.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_bindings.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// Binds route/contextual catalog shortcuts to keyboard activators.
///
/// Uses Flutter's [CallbackShortcuts] with an optional [Focus] wrapper.
/// Global shortcuts belong in shell shortcut scope instead.
class AppShortcutScope extends StatefulWidget {
  /// Creates a shortcut scope.
  const new({
    required this.shortcuts,
    required this.handlers,
    required this.child,
    super.key,
    this.autofocus = false,
    this.shouldIgnore,
  });

  /// Shortcuts active in this scope (route or contextual only).
  final Set<ShortcutDef> shortcuts;

  /// Handlers keyed by [ShortcutDef].
  final Map<ShortcutDef, VoidCallback> handlers;

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
  Set<ShortcutDef>? _boundShortcuts;
  Map<ShortcutDef, VoidCallback>? _boundHandlers;

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
    if (_bindings != null &&
        _setEquals(_boundShortcuts, widget.shortcuts) &&
        identical(_boundHandlers, widget.handlers)) {
      return;
    }

    _boundShortcuts = Set<ShortcutDef>.from(widget.shortcuts);
    _boundHandlers = widget.handlers;
    _bindings = buildAppShortcutBindings(
      shortcuts: widget.shortcuts,
      handlers: widget.handlers,
      shouldSuppress: (shortcut) {
        if (widget.shouldIgnore?.call() ?? false) return true;
        return shouldSuppressForTextFieldFocus(shortcut);
      },
    );
  }

  bool _setEquals(Set<ShortcutDef>? a, Set<ShortcutDef> b) {
    if (a == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
