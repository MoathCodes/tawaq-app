import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/app/desktop/tray_menu.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('trayMenuRegistry', () {
    test('has expected order and length', () {
      expect(trayMenuRegistry, hasLength(3));
      expect(trayMenuRegistry[0], isA<TrayMenuShow>());
      expect(trayMenuRegistry[1], isA<TrayMenuSeparator>());
      expect(trayMenuRegistry[2], isA<TrayMenuQuit>());
    });
  });

  group('trayMenuEntryByKey', () {
    test('maps clickable entries by key', () {
      expect(trayMenuEntryByKey.keys, containsAll(['show', 'stop', 'quit']));
      expect(trayMenuEntryByKey, hasLength(3));
      expect(trayMenuEntryByKey['show'], isA<TrayMenuShow>());
      expect(trayMenuEntryByKey['stop'], isA<TrayMenuStop>());
      expect(trayMenuEntryByKey['quit'], isA<TrayMenuQuit>());
    });
  });

  group('buildTrayMenu', () {
    test('builds show and quit as plain items', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        windowVisible: false,
        alertActive: false,
      );
      expect(menu.items[0].key, 'show');
      expect(menu.items[0].label, l10n.trayShowApp);
      expect(menu.items[2].key, 'quit');
      expect(menu.items[2].label, l10n.trayQuit);
    });

    test('shows hide label when window is visible', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        windowVisible: true,
        alertActive: false,
      );
      expect(menu.items[0].label, l10n.trayHideApp);
    });

    test('builds separator at index 1', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        windowVisible: false,
        alertActive: false,
      );
      expect(menu.items[1].type, TrayMenuItemType.separator);
    });

    test('inserts stop above show when alert is active', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        windowVisible: false,
        alertActive: true,
      );
      expect(menu.items[0].key, 'stop');
      expect(menu.items[0].label, l10n.trayStopAdhan);
      expect(menu.items[1].key, 'show');
    });

    test('prepends disabled header when provided', () {
      final menu = buildTrayMenu(
        l10n: l10n,
        windowVisible: false,
        alertActive: false,
        headerLabel: 'Next: Maghrib · 6:42 PM · in 2h 14m',
      );
      expect(menu.items[0].disabled, isTrue);
      expect(menu.items[0].label, 'Next: Maghrib · 6:42 PM · in 2h 14m');
      expect(menu.items[1].type, TrayMenuItemType.separator);
      expect(menu.items[2].key, 'show');
    });
  });
}
