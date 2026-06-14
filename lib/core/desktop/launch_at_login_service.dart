import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tawaq/core/utils/platform.dart';

/// OS-level launch-at-login integration for desktop platforms.
abstract final class LaunchAtLoginService {
  static const _packageName = 'me.moathdev.tawaq';

  static var _configured = false;

  /// Configures the launch-at-login plugin. Call once during desktop startup.
  static Future<void> setup() async {
    if (!isDesktopPlatform || _configured) return;

    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      packageName: _packageName,
    );
    _configured = true;
  }

  /// Whether launch-at-login is registered with the OS.
  static Future<bool> isEnabled() async {
    if (!_configured) return false;
    return launchAtStartup.isEnabled();
  }

  /// Registers or removes the app from the OS login items.
  static Future<void> setEnabled({required bool value}) async {
    if (!_configured) return;
    if (value) {
      await launchAtStartup.enable();
      return;
    }
    await launchAtStartup.disable();
  }

  /// Aligns OS login-item state with the persisted user preference.
  static Future<void> syncWithPreference({required bool launchAtLogin}) async {
    if (!_configured) return;

    final osEnabled = await isEnabled();
    if (launchAtLogin && !osEnabled) {
      await launchAtStartup.enable();
      return;
    }
    if (!launchAtLogin && osEnabled) {
      await launchAtStartup.disable();
    }
  }
}
