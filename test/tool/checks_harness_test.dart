import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ship gate propagates failed generation, analysis, test and package commands', () async {
    final root = await Directory.systemTemp.createTemp('tawaq-checks-fixture-');
    addTearDown(() => root.delete(recursive: true));
    final tool = await Directory('${root.path}/tool').create();
    await File('tool/checks.sh').copy('${tool.path}/checks.sh');
    await File('tool/step8_shipgate_verify.sh')
        .copy('${tool.path}/step8_shipgate_verify.sh');
    await File('${tool.path}/codegen.sh').writeAsString(r'''#!/usr/bin/env bash
if [[ "$FAIL_STAGE" == codegen ]]; then exit 77; fi
''');
    final bin = await Directory('${root.path}/bin').create();
    for (final command in ['dart', 'flutter', 'python3']) {
      final file = File('${bin.path}/$command');
      await file.writeAsString(r'''#!/usr/bin/env bash
stage="$(basename "$0") $*"
if [[ "$FAIL_STAGE" == "$stage" ]]; then exit 77; fi
if [[ "$FAIL_STAGE" == package && "$PWD" == */packages/dorar_hadith ]]; then exit 77; fi
exit 0
''');
      await Process.run('chmod', ['+x', file.path]);
    }
    for (final package in [
      'dorar_hadith/dorar_hadith_flutter',
      'mushaf_reader/example',
      'hisn_elmoslem',
      'adhan_dart',
      'desktop_tray',
    ]) {
      await Directory('${root.path}/packages/$package').create(recursive: true);
    }
    final fixtures = await Directory('${tool.path}/fixtures').create();
    await File('tool/fixtures/dorar-test-storage.patch')
        .copy('${fixtures.path}/dorar-test-storage.patch');
    final dorar = '${root.path}/packages/dorar_hadith';
    await Process.run('git', ['init', '--quiet'], workingDirectory: dorar);
    for (final name in [
      'dorar_client_test.dart',
      'dorar_client_use_test.dart',
    ]) {
      final original = await Process.run('git', [
        'show',
        'HEAD:test/client/$name',
      ], workingDirectory: 'packages/dorar_hadith');
      expect(original.exitCode, 0, reason: '${original.stderr}');
      final target = File('$dorar/test/client/$name');
      await target.parent.create(recursive: true);
      await target.writeAsString(original.stdout as String);
    }
    for (final stage in [
      'codegen',
      'dart analyze',
      'flutter analyze --no-fatal-infos',
      'flutter test',
      "python3 -m unittest discover -s tool/release -p test_*.py",
      'package',
      'none',
    ]) {
      final result = await Process.run(
        'bash',
        ['tool/step8_shipgate_verify.sh'],
        workingDirectory: root.path,
        environment: {
          'PATH': '${bin.path}:${Platform.environment['PATH']}',
          'FAIL_STAGE': stage,
        },
      );
      expect(
        result.exitCode,
        stage == 'none' ? 0 : 77,
        reason: '$stage: ${result.stdout}\n${result.stderr}',
      );
    }
  });
}
