import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/utils/platform.dart';

/// Whether keyboard shortcuts are enabled on this platform.
bool get supportsKeyboardShortcuts => isDesktopPlatform;

/// Whether the current desktop OS uses the Meta (⌘) modifier in UI labels.
bool get usesMetaModifier =>
    !kIsWeb && Platform.isMacOS;

/// Returns desktop-friendly modifier+key activators (Control on Linux/Windows,
/// Meta on macOS).
List<SingleActivator> desktopModShortcut(
  LogicalKeyboardKey key, {
  bool shift = false,
  bool alt = false,
}) {
  if (usesMetaModifier) {
    return [
      SingleActivator(key, meta: true, shift: shift, alt: alt),
    ];
  }
  return [
    SingleActivator(key, control: true, shift: shift, alt: alt),
  ];
}

/// Plain activator without modifiers.
SingleActivator plainShortcut(LogicalKeyboardKey key) =>
    SingleActivator(key);

/// Stable string key for duplicate detection in debug/tests.
String activatorKey(SingleActivator activator) {
  final parts = <String>[
    if (activator.control) 'control',
    if (activator.meta) 'meta',
    if (activator.shift) 'shift',
    if (activator.alt) 'alt',
    activator.trigger.keyLabel,
  ];
  return parts.join('+');
}
