import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('tawaq-omarchy-test-');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('reads the active modern Omarchy palette', () {
    final current = Directory(
      '${root.path}/.local/state/omarchy/current/theme',
    )..createSync(recursive: true);
    File('${current.path}/colors.toml').writeAsStringSync('''
mode = "dark"
accent = "#BB9AF7"
background = "#05010C"
foreground = "#FFFFFF"
''');
    final source = OmarchyThemeSource(
      home: root.path,
      isLinux: true,
      environment: {'OMARCHY_PATH': root.path},
    );

    final snapshot = source.read();
    expect(snapshot.isAvailable, isTrue);
    expect(snapshot.colorToken('accent'), '#BB9AF7');
  });

  test('does not expose a palette outside an Omarchy session', () {
    final current = Directory(
      '${root.path}/.local/state/omarchy/current/theme',
    )..createSync(recursive: true);
    File('${current.path}/colors.toml')
        .writeAsStringSync('background = "#000000"');

    final source = OmarchyThemeSource(
      home: root.path,
      isLinux: true,
      environment: const {'XDG_CURRENT_DESKTOP': 'Hyprland'},
    );

    expect(source.isOmarchySession, isFalse);
    expect(source.read().isAvailable, isFalse);
  });

  test('supports legacy active-theme locations', () {
    final current = Directory('${root.path}/.config/omarchy/current/theme')
      ..createSync(recursive: true);
    File('${current.path}/colors.toml').writeAsStringSync(
      'accent = "#BB9AF7"\nbackground = "#05010C"',
    );

    final source = OmarchyThemeSource(
      home: root.path,
      isLinux: true,
      environment: const {'DESKTOP_SESSION': 'omarchy'},
    );

    expect(source.read().isAvailable, isTrue);
  });
}
