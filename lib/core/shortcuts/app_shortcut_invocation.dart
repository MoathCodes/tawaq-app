import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runtime environment passed to global shortcut dispatch.
class AppShortcutInvocation {
  /// Creates an invocation context for global shortcut dispatch.
  const AppShortcutInvocation({
    required this.ref,
    required this.context,
  });

  /// Riverpod reference for reading notifiers.
  final WidgetRef ref;

  /// Build context for navigation and toasts.
  final BuildContext context;
}
