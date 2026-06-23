import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_display.dart';

void main() {
  group('AppShortcut catalog', () {
    test('all shortcuts are unique singletons', () {
      expect(
        AppShortcut.all.toSet().length,
        AppShortcut.all.length,
      );
    });

    test('visible shortcuts stay in sync with catalog', () {
      for (final shortcut in visibleAppShortcuts) {
        expect(AppShortcut.all, contains(shortcut));
      }
    });

    test('no duplicate activators within the same scope', () {
      final duplicates = findDuplicateActivators();
      expect(
        duplicates,
        isEmpty,
        reason: 'Duplicate activators: $duplicates',
      );
    });
  });

  group('activatorDisplayTokens', () {
    test('includes modifier labels for desktop shortcuts', () {
      final tokens = activatorDisplayTokens(
        desktopModShortcut(LogicalKeyboardKey.keyK).first,
      );
      expect(tokens, contains('K'));
      expect(tokens.length, greaterThan(1));
    });

    test('maps arrow keys to unicode arrows', () {
      final tokens = activatorDisplayTokens(
        plainShortcut(LogicalKeyboardKey.arrowUp),
      );
      expect(tokens, ['↑']);
    });
  });
}
