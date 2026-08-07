import 'dart:io';

/// Whether the app is running on a supported desktop OS (Linux, Windows, macOS).
///
/// Tawaq targets desktop only; other platforms are out of scope.
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
