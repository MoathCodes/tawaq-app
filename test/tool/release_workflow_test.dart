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

  test('Windows candidate builds do not require a Shorebird login', () {
    final steps = (jobs['windows'] as YamlMap)['steps'] as YamlList;
    final candidate = steps.cast<YamlMap>().singleWhere(
      (step) => step['name'] == 'Candidate build (no upload)',
    );
    expect(candidate['if'] as String, contains("action == 'build'"));
    expect(candidate['run'] as String, contains('flutter build windows'));
    expect(candidate['run'] as String, isNot(contains('shorebird')));
  });

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

  group('beta delivery', () {
    YamlMap load(String name) =>
        loadYaml(File('.github/workflows/$name').readAsStringSync()) as YamlMap;
    List<YamlMap> stepsOf(YamlMap workflowFile, String job) =>
        ((workflowFile['jobs'][job] as YamlMap)['steps'] as YamlList)
            .cast<YamlMap>()
            .toList();
    String text(String name) =>
        File('.github/workflows/$name').readAsStringSync();
    final installerWords = RegExp(
      r'flutter build|iscc|shorebird|gh release|git tag|git push|set_pubspec_version',
    );

    test(
      'required PR and main checks never build, version, tag or publish',
      () {
        final quality = load('quality.yml');
        final triggers = quality['on'] as YamlMap;
        expect(triggers.keys.toSet(), {'push', 'pull_request'});
        expect((triggers['push'] as YamlMap)['branches'], ['main']);
        expect((triggers['pull_request'] as YamlMap)['branches'], ['main']);
        // Branch protection keys on these names.
        final names = [
          for (final job in (quality['jobs'] as YamlMap).values)
            (job as YamlMap)['name'],
        ];
        expect(names, ['App analyze and test', 'Local package quality']);
        expect(quality['permissions'], {'contents': 'read'});
        expect(text('quality.yml'), isNot(contains(installerWords)));
      },
    );

    test('desktop builds start only by hand; a beta tag never starts a stable release', () {
      final triggers = workflow['on'] as YamlMap;
      expect(triggers.keys.toSet(), {'push', 'workflow_dispatch'});
      final push = triggers['push'] as YamlMap;
      expect(push.keys.toSet(), {'tags'});
      final tags = (push['tags'] as YamlList).cast<String>();
      expect(tags, [r'v[0-9]+.[0-9]+.[0-9]+']);
      expect(
        tags.single.contains('*'),
        isFalse,
        reason: 'a v* filter would also match v1.0.0-beta.N',
      );
      final action =
          (triggers['workflow_dispatch']['inputs'] as YamlMap)['action']
              as YamlMap;
      expect(
        action['options'],
        containsAll(['release', 'patch', 'build', 'beta']),
      );
      expect(workflow['permissions'], {'contents': 'read'});
      final release = jobs['release'] as YamlMap;
      expect(release['if'] as String, contains("action != 'beta'"));
      expect(
        (jobs['native_gate'] as YamlMap)['if'] as String,
        contains("action != 'beta'"),
      );
      expect(
        (jobs['checks'] as YamlMap)['if'],
        "github.event.inputs.action != 'beta'",
      );
    });

    test('beta jobs build with plain Flutter and an up-front version, without Shorebird', () {
      final betaJobs = jobs.keys
          .cast<String>()
          .where((name) => name.startsWith('beta_'))
          .toList();
      expect(betaJobs, isNotEmpty);
      for (final name in betaJobs) {
        final job = jobs[name] as YamlMap;
        expect(
          job['if'] as String? ?? '',
          anyOf(contains("action == 'beta'"), contains('beta_plan'), isEmpty),
          reason: name,
        );
        final definition = job.toString().toLowerCase();
        expect(definition, isNot(contains('shorebird')), reason: name);
        expect(definition, isNot(contains('secrets.')), reason: name);
        expect(definition, isNot(contains('gh release')), reason: name);
        expect(
          definition,
          isNot(contains('set_pubspec_version')),
          reason: name,
        );
        expect(definition, isNot(contains('contents: write')), reason: name);
      }
      expect(needs('beta_windows'), ['beta_plan']);
      final build = stepsOf(
        workflow,
        'beta_windows',
      ).singleWhere((step) => step['name'] == 'Build Windows app');
      expect(
        build['run'],
        r'flutter build windows --release --build-name "$BETA_NAME" --build-number "$BETA_NUMBER"',
      );
      final toolchain = stepsOf(workflow, 'beta_windows').singleWhere(
        (step) => step['name'] == 'Record actual candidate toolchain',
      );
      expect(toolchain['run'], contains('--require-clean'));
      final upload = stepsOf(workflow, 'beta_windows').last;
      expect((upload['with'] as YamlMap)['retention-days'], 30);
      expect((upload['with'] as YamlMap)['name'], 'tawaq-beta-windows-x64');
    });

    test('beta planning fails early outside main and release branches', () {
      final guard = stepsOf(workflow, 'beta_plan').first;
      expect(guard['name'], 'Require a trusted branch');
      final script = guard['run'] as String;
      expect(script, contains(r'branch:main | branch:release/?*) ;;'));
      expect(script, contains('exit 1'));
      // The guard precedes checkout and every other planning step.
      expect(guard.containsKey('uses'), isFalse);
      expect(needs('beta_windows'), ['beta_plan']);
      // Mirrors the authoritative check in publish_beta.py.
      final publisher = File('tool/release/publish_beta.py').readAsStringSync();
      expect(publisher, contains(r"r'main|release/[^\s/][^\s]*'"));
    });

    test('beta checks are reused, awaited or run alongside the build, and gate the run', () {
      expect(needs('beta_wait_checks'), ['beta_plan']);
      expect(needs('beta_check_app'), ['beta_plan']);
      expect(needs('beta_check_packages'), ['beta_plan']);
      expect(
        (jobs['beta_wait_checks'] as YamlMap)['if'],
        "needs.beta_plan.outputs.checks_mode == 'wait'",
      );
      for (final job in ['beta_check_app', 'beta_check_packages']) {
        expect(
          (jobs[job] as YamlMap)['if'],
          "needs.beta_plan.outputs.checks_mode == 'run'",
        );
      }
      expect(
        needs('beta_result'),
        containsAll([
          'beta_plan',
          'beta_windows',
          'beta_wait_checks',
          'beta_check_app',
          'beta_check_packages',
        ]),
      );
      expect(
        (jobs['beta_result'] as YamlMap)['if'] as String,
        startsWith('always()'),
      );
      // Publish beta looks these jobs up by name.
      final publisher = File('tool/release/publish_beta.py').readAsStringSync();
      for (final job in ['beta_check_app', 'beta_check_packages']) {
        expect(publisher, contains((jobs[job] as YamlMap)['name']));
      }
    });

    test('Publish beta takes one exact run, rebuilds nothing, and alone may write releases', () {
      final publish = load('publish-beta.yml');
      final triggers = publish['on'] as YamlMap;
      expect(triggers.keys.toSet(), {'workflow_dispatch'});
      final inputs = triggers['workflow_dispatch']['inputs'] as YamlMap;
      expect(inputs.keys.toSet(), {'build_run_id', 'mode'});
      expect((inputs['mode'] as YamlMap)['default'], 'rehearse');
      expect(publish['permissions'], {'contents': 'read'});
      expect(publish['concurrency']['cancel-in-progress'], isFalse);
      final job = (publish['jobs'] as YamlMap)['publish'] as YamlMap;
      expect(job['permissions'], {'contents': 'write', 'actions': 'read'});
      expect(job['if'] as String, contains('default_branch'));
      final source = text('publish-beta.yml');
      expect(
        source,
        isNot(contains(RegExp(r'flutter|dart |checks\.sh|shorebird|iscc'))),
      );
      final download = stepsOf(publish, 'publish').singleWhere(
        (step) => (step['uses'] as String? ?? '').startsWith(
          'actions/download-artifact',
        ),
      );
      expect(
        (download['with'] as YamlMap)['run-id'],
        r'${{ inputs.build_run_id }}',
      );

      // Only the stable release job and this one can write repository contents.
      for (final file in Directory(
        '.github/workflows',
      ).listSync().whereType<File>()) {
        final parsed = loadYaml(file.readAsStringSync()) as YamlMap;
        final writers = [
          for (final entry in (parsed['jobs'] as YamlMap).entries)
            if ((entry.value as YamlMap)['permissions']?['contents'] == 'write')
              entry.key,
        ];
        expect(writers, switch (file.uri.pathSegments.last) {
          'build-desktop.yml' => ['release'],
          'publish-beta.yml' => ['publish'],
          _ => isEmpty,
        }, reason: file.path);
      }
    });

    test('live Aladhan comparisons run on a schedule; offline prayer tests stay required', () {
      final live = load('prayer-api-validation.yml');
      final triggers = live['on'] as YamlMap;
      expect(triggers.keys.toSet(), {'schedule', 'workflow_dispatch'});
      final source = text('prayer-api-validation.yml');
      expect(source, contains('test/api_validation_test.dart'));
      expect(source, contains('timeout-minutes'));
      final checks = File('tool/checks.sh').readAsStringSync();
      expect(
        checks,
        contains(
          "dart test --name '^(?!Prayer Times API Validation validates )'",
        ),
      );
      // The filter must still select every offline prayer test and drop only live ones.
      final filter = RegExp(r'^(?!Prayer Times API Validation validates )');
      expect(
        filter.hasMatch(
          'Prayer Times API Validation validates DST transition behavior (New York 2024)',
        ),
        isFalse,
      );
      expect(
        filter.hasMatch(
          'Prayer Times API Validation temporal ordering of prayers across diverse locations/dates',
        ),
        isTrue,
      );
      expect(filter.hasMatch('PrayerTimes calculates Fajr'), isTrue);
    });
  });
}
