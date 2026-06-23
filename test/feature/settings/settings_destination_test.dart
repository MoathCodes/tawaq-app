import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_destination.dart';

void main() {
  group('destinationForKey', () {
    test('round-trips every destination labelKey', () {
      for (final destination in kSettingsDestinations) {
        expect(
          destinationForKey(destination.labelKey),
          isA<SettingsDestination>().having(
            (d) => d.labelKey,
            'labelKey',
            destination.labelKey,
          ),
        );
      }
    });

    test('null key defaults to appearance', () {
      expect(
        destinationForKey(null),
        isA<SettingsAppearanceDestination>(),
      );
    });

    test('unknown key defaults to appearance', () {
      expect(
        destinationForKey('deletedSection'),
        isA<SettingsAppearanceDestination>(),
      );
    });
  });

  group('visibleDestinations', () {
    test('excludes keyboard shortcuts when unsupported', () {
      final destinations = visibleDestinations(showKeyboardShortcuts: false);

      expect(destinations, hasLength(3));
      expect(
        destinations,
        isNot(contains(isA<SettingsKeyboardShortcutsDestination>())),
      );
    });

    test('includes keyboard shortcuts when supported', () {
      final destinations = visibleDestinations(showKeyboardShortcuts: true);

      expect(destinations, hasLength(4));
      expect(
        destinations.last,
        isA<SettingsKeyboardShortcutsDestination>(),
      );
    });
  });

  group('resolveVisibleDestination', () {
    test('falls back to appearance when destination is hidden', () {
      expect(
        resolveVisibleDestination(
          const SettingsKeyboardShortcutsDestination(),
          showKeyboardShortcuts: false,
        ),
        isA<SettingsAppearanceDestination>(),
      );
    });

    test('keeps visible destination', () {
      expect(
        resolveVisibleDestination(
          const SettingsLocationDestination(),
          showKeyboardShortcuts: false,
        ),
        isA<SettingsLocationDestination>(),
      );
    });
  });

  group('indexForDestination', () {
    test('returns correct index for location tab', () {
      expect(
        indexForDestination(
          const SettingsLocationDestination(),
          showKeyboardShortcuts: true,
        ),
        2,
      );
    });

    test('returns -1 for hidden destination', () {
      expect(
        indexForDestination(
          const SettingsKeyboardShortcutsDestination(),
          showKeyboardShortcuts: false,
        ),
        -1,
      );
    });
  });
}
