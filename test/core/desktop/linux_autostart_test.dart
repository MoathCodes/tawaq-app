import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tawaq/core/desktop/linux_autostart.dart';

void main() {
  test(
    'registers a moved path under XDG and removes legacy entries idempotently',
    () async {
      final root = await Directory.systemTemp.createTemp('tawaq-autostart-');
      addTearDown(() => root.delete(recursive: true));
      final binary = File(p.join(root.path, 'app with spaces', 'Tawaq'));
      await binary.parent.create();
      await binary.writeAsString('fixture');
      final legacy = File(
        p.join(root.path, '.config', 'autostart', 'Tawaq.desktop'),
      );
      await legacy.parent.create(recursive: true);
      await legacy.writeAsString('[Desktop Entry]\nName=Tawaq\nExec=old\n');
      final service = LinuxAutostart(
        executable: binary.path,
        environment: {
          'HOME': root.path,
          'XDG_CONFIG_HOME': p.join(root.path, 'custom config'),
        },
      );
      await service.setEnabled(value: true);
      expect(await service.isEnabled(), isTrue);
      expect(service.registration.path, contains('custom config'));
      expect(await legacy.exists(), isFalse);
      expect(
        await service.registration.readAsString(),
        contains('Exec="${binary.path}"'),
      );
      await service.setEnabled(value: true);
      await service.setEnabled(value: false);
      await service.setEnabled(value: false);
      expect(await service.isEnabled(), isFalse);
    },
  );

  test(
    'Exec escapes percent and the desktop string/argument escape layers',
    () {
      expect(
        desktopExecArgument(r'/path/50% $cash "quoted" \file'),
        r'"/path/50%% \\$cash \\"quoted\\" \\\\file"',
      );
      expect(() => desktopExecArgument('/bad=path'), throwsArgumentError);
      expect(() => desktopExecArgument('/bad\npath'), throwsArgumentError);
    },
  );
}
