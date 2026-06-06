import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether the app is running on a desktop platform (Linux, Windows, macOS).
bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
