import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final workflow = loadYaml(
    File('.github/workflows/build-desktop.yml').readAsStringSync(),
  ) as YamlMap;
  final jobs = workflow['jobs'] as YamlMap;
  List<String> needs(String job) =>
      ((jobs[job] as YamlMap)['needs'] as YamlList?)?.cast<String>().toList() ??
      [];

  test(
    'every distribution platform waits for shared checks and native review',
    () {
      expect(needs('native_gate'), contains('checks'));
      for (final platform in ['linux', 'windows', 'macos']) {
        expect(needs(platform), containsAll(['checks', 'native_gate']));
        final condition = (jobs[platform] as YamlMap)['if'] as String;
        expect(condition, contains("needs.checks.result == 'success'"));
        expect(condition, contains("needs.native_gate.result == 'success'"));
        final steps = (jobs[platform] as YamlMap)['steps'] as YamlList;
        for (final step in steps.cast<YamlMap>()) {
          final command = step['run'] as String? ?? '';
          if (command.contains('shorebird release') &&
              !command.contains('--dry-run')) {
            expect(step['if'] as String, contains("action == 'release'"));
          }
          if (command.contains('shorebird patch')) {
            expect(step['if'] as String, contains("action == 'patch'"));
            expect(command, contains(r'--release-version "$PATCH_TARGET"'));
            expect(command, isNot(contains('latest')));
          }
        }
      }
    },
  );

  test(
    'public release requires all platforms and verifies privately staged bytes',
    () {
      expect(
        needs('release'),
        containsAll(['checks', 'native_gate', 'linux', 'windows', 'macos']),
      );
      final gate = jobs['native_gate'] as YamlMap;
      expect(gate['if'] as String, contains("action != 'build'"));
      expect(gate['environment'], 'coordinated-desktop-release');
      final steps = (jobs['release'] as YamlMap)['steps'] as YamlList;
      final download = steps.cast<YamlMap>().singleWhere(
        (step) => (step['uses'] as String? ?? '').startsWith(
          'actions/download-artifact',
        ),
      );
      expect((download['with'] as YamlMap)['name'], 'reviewed-candidate');
      final publish = steps.cast<YamlMap>().singleWhere(
        (step) => (step['run'] as String? ?? '').contains('gh release create'),
      );
      final command = publish['run'] as String;
      expect(command, contains('--draft'));
      expect(
        command.indexOf('publish_assets.py'),
        lessThan(command.indexOf('--draft=false')),
      );
      expect(workflow['concurrency']['cancel-in-progress'], isFalse);
    },
  );
}
