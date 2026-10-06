import 'dart:io';

import 'package:path/path.dart' as p;

/// The stable XDG desktop identity shared by installs and startup registration.
const tawaqDesktopIdentity = 'me.moathdev.tawaq';

/// Encodes one executable argument using Desktop Entry string and Exec rules.
String desktopExecArgument(String executable) {
  if (executable.contains('=') ||
      executable.contains('\n') ||
      executable.contains('\r')) {
    throw ArgumentError.value(
      executable,
      'executable',
      'Invalid desktop executable',
    );
  }
  final quoted = executable
      .replaceAllMapped(RegExp(r'[\\"`$]'), (match) => '\\${match[0]}')
      .replaceAll('%', '%%');
  return '"${quoted.replaceAll('\\', '\\\\')}"';
}

/// Owns only Tawaq's registrations, respecting nondefault XDG configuration.
class LinuxAutostart {
  LinuxAutostart({
    required this.executable,
    required this.environment,
    this.legacyNames = const ['tawaq', 'Tawaq', 'توّاق'],
  });
  final String executable;
  final Map<String, String> environment;
  final List<String> legacyNames;

  String get _configHome {
    final configured = environment['XDG_CONFIG_HOME'];
    if (configured != null && p.isAbsolute(configured)) return configured;
    final home = environment['HOME'];
    if (home == null || home.isEmpty) throw StateError('HOME is unavailable');
    return p.join(home, '.config');
  }

  File get registration =>
      File(p.join(_configHome, 'autostart', '$tawaqDesktopIdentity.desktop'));
  String get _entry =>
      '[Desktop Entry]\nType=Application\nName=Tawaq\nExec=${desktopExecArgument(executable)}\nIcon=$tawaqDesktopIdentity\nTerminal=false\nX-GNOME-Autostart-enabled=true\n';

  Future<bool> isEnabled() async {
    final file = registration;
    if (!await file.exists()) return false;
    return await file.readAsString() == _entry;
  }

  Future<void> setEnabled({required bool value}) async {
    final file = registration;
    if (value) {
      if (!File(executable).existsSync())
        throw FileSystemException('Executable is unavailable', executable);
      await file.parent.create(recursive: true);
      final staging = File('${file.path}.staging');
      try {
        await staging.writeAsString(_entry, flush: true);
        await staging.rename(file.path);
      } finally {
        if (await staging.exists()) await staging.delete();
      }
    } else if (await file.exists()) {
      await file.delete();
    }
    // The old plugin wrote appName.desktop, including outside XDG_CONFIG_HOME.
    // Remove only known Tawaq names and entries whose Name identifies Tawaq.
    final roots = {
      _configHome,
      if (environment['HOME'] != null) p.join(environment['HOME']!, '.config'),
    };
    for (final root in roots) {
      for (final name in legacyNames) {
        final legacy = File(p.join(root, 'autostart', '$name.desktop'));
        if (!await legacy.exists() || legacy.path == file.path) continue;
        final text = await legacy.readAsString();
        if (RegExp(
          r'^Name=(Tawaq|tawaq|توّاق)\s*$',
          multiLine: true,
        ).hasMatch(text))
          await legacy.delete();
      }
    }
  }
}
