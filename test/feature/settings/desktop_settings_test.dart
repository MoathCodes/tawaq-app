import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/settings/data/models/desktop_settings.dart';

void main() {
  group('DesktopSettings', () {
    test('defaults include launch-at-login fields', () {
      const settings = DesktopSettings();

      expect(settings.launchAtLogin, isFalse);
      expect(settings.launchAtLoginHintSeen, isFalse);
      expect(settings.forceMacStyleWindowControls, isFalse);
    });

    test('fromJson fills missing launch-at-login keys with defaults', () {
      final settings = DesktopSettings.fromJson({
        'minimizeToTrayOnClose': true,
        'minimizeToTray': false,
        'launchToTray': true,
      });

      expect(settings.launchAtLogin, isFalse);
      expect(settings.launchAtLoginHintSeen, isFalse);
      expect(settings.forceMacStyleWindowControls, isFalse);
      expect(settings.launchToTray, isTrue);
    });

    test('toJson round-trips launch-at-login fields', () {
      const settings = DesktopSettings(
        launchAtLogin: true,
        launchAtLoginHintSeen: true,
        launchToTray: true,
        forceMacStyleWindowControls: true,
      );

      final restored = DesktopSettings.fromJson(settings.toJson());

      expect(restored, settings);
    });
  });
}
