import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/desktop/tray_menu.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('trayMenuRegistry', () {
    test('has expected order and length', () {
      expect(trayMenuRegistry, hasLength(4));
      expect(trayMenuRegistry[0], isA<TrayMenuShow>());
      expect(trayMenuRegistry[1], isA<TrayMenuMute>());
      expect(trayMenuRegistry[2], isA<TrayMenuSeparator>());
      expect(trayMenuRegistry[3], isA<TrayMenuQuit>());
    });
  });

  group('trayMenuEntryByKey', () {
    test('maps clickable entries by key', () {
      expect(trayMenuEntryByKey.keys, containsAll(['show', 'mute', 'quit']));
      expect(trayMenuEntryByKey, hasLength(3));
      expect(trayMenuEntryByKey['show'], isA<TrayMenuShow>());
      expect(trayMenuEntryByKey['mute'], isA<TrayMenuMute>());
      expect(trayMenuEntryByKey['quit'], isA<TrayMenuQuit>());
    });
  });

  group('buildTrayMenu', () {
    test('builds show and quit as plain items', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        muteChecked: false,
        windowVisible: false,
      );
      expect(menu.items[0].key, 'show');
      expect(menu.items[0].label, l10n.trayShowApp);
      expect(menu.items[3].key, 'quit');
      expect(menu.items[3].label, l10n.trayQuit);
    });

    test('shows hide label when window is visible', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        muteChecked: false,
        windowVisible: true,
      );
      expect(menu.items[0].label, l10n.trayHideApp);
    });

    test('builds separator at index 2', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        muteChecked: false,
        windowVisible: false,
      );
      expect(menu.items[2].type, TrayMenuItemType.separator);
    });

    test('reflects mute checkbox checked state', () {
      final unchecked = buildTrayMenu(
        l10n: l10n,
        muteChecked: false,
        windowVisible: false,
      );
      final muteUnchecked = unchecked.items[1];
      expect(muteUnchecked.type, TrayMenuItemType.checkbox);
      expect(muteUnchecked.checked, isFalse);

      final checked = buildTrayMenu(
        l10n: l10n,
        muteChecked: true,
        windowVisible: false,
      );
      expect(checked.items[1].checked, isTrue);
      expect(checked.items[1].label, l10n.trayMuteAdhan);
    });
  });
}
