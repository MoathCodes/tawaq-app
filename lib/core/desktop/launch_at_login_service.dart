import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/desktop/linux_autostart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Applies a login-registration change through the configured native adapter.
final launchAtLoginUpdateProvider = Provider<Future<void> Function(bool)>(
  (ref) => (value) async {
    if (isDesktopPlatform) await LaunchAtLoginService.setEnabled(value: value);
  },
);

/// OS-level launch-at-login integration for desktop platforms.
abstract final class LaunchAtLoginService {
  static const _packageName = tawaqDesktopIdentity;
  static LinuxAutostart? _linux;

  static var _configured = false;

  /// Configures the launch-at-login plugin. Call once during desktop startup.
  static Future<void> setup() async {
    if (!isDesktopPlatform || _configured) return;

    final packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isLinux) {
      _linux = LinuxAutostart(
        executable: Platform.resolvedExecutable,
        environment: Platform.environment,
        legacyNames: ['tawaq', 'Tawaq', 'توّاق', packageInfo.appName],
      );
      _configured = true;
      return;
    }
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
    if (_linux != null) return _linux!.isEnabled();
    return launchAtStartup.isEnabled();
  }

  /// Registers or removes the app from the OS login items.
  static Future<void> setEnabled({required bool value}) async {
    if (!_configured) throw StateError('Login integration is not ready');
    if (_linux != null) {
      await _linux!.setEnabled(value: value);
      return;
    }
    if (value) {
      await launchAtStartup.enable();
      return;
    }
    await launchAtStartup.disable();
  }

  /// Aligns OS login-item state with the persisted user preference.
  static Future<void> syncWithPreference({required bool launchAtLogin}) async {
    if (!_configured) return;

    // Reconcile even an enabled entry so moved executables and legacy names
    // are repaired. This checks registration, not observed startup.
    if (_linux != null) {
      await _linux!.setEnabled(value: launchAtLogin);
      return;
    }
    final osEnabled = await isEnabled();
    if (osEnabled != launchAtLogin) await setEnabled(value: launchAtLogin);
  }
}
