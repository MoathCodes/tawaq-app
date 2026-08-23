import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'recitation session domain has no framework or native adapter imports',
    () {
      final violations = <String>[];
      for (final entity in Directory(
        'lib/feature/quran/domain/recitation',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final forbidden in const [
          'package:flutter/',
          'package:flutter_riverpod/',
          'package:hooks_riverpod/',
          'package:riverpod_annotation/',
          'package:mpv_audio_kit/',
        ]) {
          if (source.contains(forbidden)) {
            violations.add('${entity.path}: $forbidden');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Keep framework and native dependencies behind adapters.',
      );
    },
  );

  test('Riverpod adapter only projects logical recitation state', () {
    final source = File(
      'lib/feature/quran/presentation/providers/recitation_provider.dart',
    ).readAsStringSync();
    final controller = source.substring(
      source.indexOf('class RecitationController'),
    );
    final writes = RegExp(r'\bstate\s*=').allMatches(controller).length;

    expect(
      writes,
      1,
      reason:
          'RecitationController may assign logical state only in the '
          'RecitationSession projection callback.',
    );
    expect(
      RegExp(r'onStateChanged: \(next\) => state = next')
          .allMatches(controller),
      hasLength(1),
    );
  });
}
