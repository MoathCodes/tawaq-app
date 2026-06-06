import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// Human-readable label for a single key in a shortcut combo.
String displayKeyLabel(LogicalKeyboardKey key) {
  return switch (key) {
    LogicalKeyboardKey.arrowUp => '↑',
    LogicalKeyboardKey.arrowDown => '↓',
    LogicalKeyboardKey.arrowLeft => '←',
    LogicalKeyboardKey.arrowRight => '→',
    LogicalKeyboardKey.space => 'Space',
    LogicalKeyboardKey.enter => 'Enter',
    LogicalKeyboardKey.comma => ',',
    LogicalKeyboardKey.shift => 'Shift',
    LogicalKeyboardKey.control => 'Ctrl',
    LogicalKeyboardKey.meta => '⌘',
    LogicalKeyboardKey.alt => 'Alt',
    _ => _normalizeKeyLabel(key.keyLabel),
  };
}

String _normalizeKeyLabel(String keyLabel) {
  if (keyLabel.length == 1) {
    return keyLabel.toUpperCase();
  }
  return keyLabel;
}

/// Ordered display tokens for a [SingleActivator].
List<String> activatorDisplayTokens(SingleActivator activator) {
  final tokens = <String>[];
  if (activator.meta) {
    tokens.add(usesMetaModifier ? '⌘' : 'Win');
  }
  if (activator.control) {
    tokens.add(usesMetaModifier ? '⌃' : 'Ctrl');
  }
  if (activator.alt) {
    tokens.add(usesMetaModifier ? '⌥' : 'Alt');
  }
  if (activator.shift) {
    tokens.add(usesMetaModifier ? '⇧' : 'Shift');
  }
  tokens.add(displayKeyLabel(activator.trigger));
  return tokens;
}
