import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_registry.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_display.dart';

void main() {
  group('appShortcutRegistry', () {
    test('every AppShortcutId has a registry entry', () {
      for (final id in AppShortcutId.values) {
        expect(appShortcutById.containsKey(id), isTrue, reason: id.name);
      }
    });

    test('registry size matches enum length', () {
      expect(appShortcutRegistry.length, AppShortcutId.values.length);
    });

    test('visible shortcuts have unique ids', () {
      final ids = appShortcutRegistry.map((definition) => definition.id);
      expect(ids.toSet().length, ids.length);
    });

    test('no duplicate activators within the same scope', () {
      final duplicates = findDuplicateActivatorsInRegistry();
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
