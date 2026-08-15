import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_tabs.dart';

void main() {
  group('tabForKey', () {
    test('round-trips every tab key', () {
      for (final tab in kSettingsTabs) {
        expect(tabForKey(tab.key).key, tab.key);
      }
    });

    test('null key defaults to appearance', () {
      expect(tabForKey(null).key, kSettingsDefaultTabKey);
    });

    test('unknown key defaults to appearance', () {
      expect(tabForKey('deletedSection').key, kSettingsDefaultTabKey);
    });
  });

  group('visibleTabs', () {
    test('excludes keyboard shortcuts when unsupported', () {
      final tabs = visibleTabs(showKeyboardShortcuts: false);

      expect(tabs, hasLength(3));
      expect(
        tabs.map((t) => t.key),
        isNot(contains(SettingsTabId.keyboardShortcuts.wireValue)),
      );
    });

    test('includes keyboard shortcuts when supported', () {
      final tabs = visibleTabs(showKeyboardShortcuts: true);

      expect(tabs, hasLength(4));
      expect(tabs.last.key, SettingsTabId.keyboardShortcuts.wireValue);
    });
  });

  group('resolveVisibleTabKey', () {
    test('falls back to appearance when tab is hidden', () {
      expect(
        resolveVisibleTabKey(
          'keyboardShortcutsTabTitle',
          showKeyboardShortcuts: false,
        ),
        kSettingsDefaultTabKey,
      );
    });

    test('keeps visible tab key', () {
      expect(
        resolveVisibleTabKey(
          kSettingsLocationTabKey,
          showKeyboardShortcuts: false,
        ),
        kSettingsLocationTabKey,
      );
    });
  });

  group('indexForTabKey', () {
    test('returns correct index for location tab', () {
      expect(
        indexForTabKey(
          kSettingsLocationTabKey,
          showKeyboardShortcuts: true,
        ),
        2,
      );
    });

    test('returns -1 for hidden tab', () {
      expect(
        indexForTabKey(
          'keyboardShortcutsTabTitle',
          showKeyboardShortcuts: false,
        ),
        -1,
      );
    });
  });

  group('resolveSettingsRouteTab', () {
    test('invalid URL restores persisted checkpoint', () {
      expect(
        resolveSettingsRouteTab(
          routeKey: 'removed-tab',
          persistedKey: SettingsTabId.location.wireValue,
          showKeyboardShortcuts: true,
        ),
        SettingsTabId.location.wireValue,
      );
    });

    test('platform-inapplicable URL restores persisted checkpoint', () {
      expect(
        resolveSettingsRouteTab(
          routeKey: SettingsTabId.keyboardShortcuts.wireValue,
          persistedKey: SettingsTabId.prayerTimes.wireValue,
          showKeyboardShortcuts: false,
        ),
        SettingsTabId.prayerTimes.wireValue,
      );
    });
  });

  group('settingsTabIsSettled', () {
    test('rejects midpoint swipe and tap animation states', () {
      expect(
        settingsTabIsSettled(indexIsChanging: false, offset: -0.5),
        isFalse,
      );
      expect(
        settingsTabIsSettled(indexIsChanging: true, offset: 0),
        isFalse,
      );
    });

    test('accepts a fully settled tab', () {
      expect(
        settingsTabIsSettled(indexIsChanging: false, offset: 0),
        isTrue,
      );
    });
  });
}
