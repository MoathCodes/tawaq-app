import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// Shared activator sets referenced by the registry.

/// Toggle theme: Ctrl/Cmd+Shift+D.
List<SingleActivator> get toggleThemeActivators =>
    desktopModShortcut(LogicalKeyboardKey.keyD, shift: true);

/// Toggle locale: Ctrl/Cmd+Shift+L.
List<SingleActivator> get toggleLocaleActivators =>
    desktopModShortcut(LogicalKeyboardKey.keyL, shift: true);

/// Open settings: Ctrl/Cmd+,.
List<SingleActivator> get openSettingsActivators =>
    desktopModShortcut(LogicalKeyboardKey.comma);

/// Focus search: Ctrl/Cmd+K.
List<SingleActivator> get focusSearchActivators =>
    desktopModShortcut(LogicalKeyboardKey.keyK);

/// Next mushaf page (RTL): Left arrow.
SingleActivator get quranPageNextActivator =>
    plainShortcut(LogicalKeyboardKey.arrowLeft);

/// Previous mushaf page: Right arrow.
SingleActivator get quranPagePrevActivator =>
    plainShortcut(LogicalKeyboardKey.arrowRight);

/// Next mushaf page: Space.
SingleActivator get quranPageNextSpaceActivator =>
    plainShortcut(LogicalKeyboardKey.space);

/// Next ayah in study panel.
List<SingleActivator> get quranAyahNextActivators => [
      plainShortcut(LogicalKeyboardKey.arrowLeft),
      plainShortcut(LogicalKeyboardKey.arrowDown),
    ];

/// Previous ayah in study panel.
List<SingleActivator> get quranAyahPrevActivators => [
      plainShortcut(LogicalKeyboardKey.arrowRight),
      plainShortcut(LogicalKeyboardKey.arrowUp),
    ];

/// Fortress count decrement.
List<SingleActivator> get fortressCountActivators => [
      plainShortcut(LogicalKeyboardKey.space),
      plainShortcut(LogicalKeyboardKey.enter),
    ];

/// Next thikr in fortress focus reading (RTL page-turn, matches study panel).
List<SingleActivator> get fortressThikrNextActivators => [
      plainShortcut(LogicalKeyboardKey.arrowLeft),
      plainShortcut(LogicalKeyboardKey.arrowDown),
    ];

/// Previous thikr in fortress focus reading.
List<SingleActivator> get fortressThikrPrevActivators => [
      plainShortcut(LogicalKeyboardKey.arrowRight),
      plainShortcut(LogicalKeyboardKey.arrowUp),
    ];
