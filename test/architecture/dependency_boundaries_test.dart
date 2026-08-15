import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _packageDirective = RegExp(
  "^(?:import|export) 'package:tawaq/([^']+)'",
  multiLine: true,
);

void main() {
  test('dependency boundaries gain no new violations', () {
    final actual = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.path.replaceFirst('lib/', '');
      for (final match in _packageDirective.allMatches(
        entity.readAsStringSync(),
      )) {
        final target = match.group(1)!;
        if (_isViolation(source, target)) {
          actual.add('$source -> $target');
        }
      }
    }

    final added = actual.difference(_legacyViolations);
    final removed = _legacyViolations.difference(actual);
    expect(
      added,
      isEmpty,
      reason: 'New architecture violations:\n${added.toList()..sort()}',
    );
    expect(
      removed,
      isEmpty,
      reason:
          'Delete repaired entries from _legacyViolations:\n'
          '${removed.toList()..sort()}',
    );
  });
}

bool _isViolation(String source, String target) {
  if (source.startsWith('app/')) return false;
  if (source.startsWith('core/')) {
    return target.startsWith('app/') || target.startsWith('feature/');
  }
  if (!source.startsWith('feature/')) return false;
  if (target.startsWith('app/')) return true;
  if (!target.startsWith('feature/')) return false;

  final sourceParts = source.split('/');
  final targetParts = target.split('/');
  final sourceFeature = sourceParts[1];
  final targetFeature = targetParts[1];
  final sourceLayer = sourceParts.length > 2 ? sourceParts[2] : '';
  final targetLayer = targetParts.length > 2 ? targetParts[2] : '';

  if (sourceFeature != targetFeature) {
    return !(sourceFeature == 'settings' &&
        sourceLayer == 'presentation' &&
        targetFeature == 'prayer');
  }
  if (sourceLayer == 'domain') {
    return targetLayer == 'data' || targetLayer == 'presentation';
  }
  return sourceLayer == 'data' && targetLayer == 'presentation';
}

// Shrinking baseline for pre-existing violations. New entries are forbidden,
// and repaired entries must be removed in the same change.
const _legacyViolations = <String>{
  'feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart -> feature/prayer/presentation/provider/prayer_day.dart',
  'feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart -> feature/quran/presentation/models/quran_mushaf_style.dart',
  'feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart -> feature/quran/presentation/models/quran_ui_models.dart',
  'feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart -> feature/quran/presentation/providers/quran_screen_settings_provider.dart',
  'feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart -> feature/quran/presentation/widgets/quran_semantics.dart',
  'feature/onboarding/presentation/providers/onboarding_state_provider.dart -> feature/prayer/presentation/provider/prayer_settings_provider.dart',
  'feature/onboarding/presentation/providers/onboarding_state_provider.dart -> feature/settings/presentation/provider/theme_settings_provider.dart',
  'feature/onboarding/presentation/widgets/onboarding_rerun_tile.dart -> app/routing/route_provider.dart',
  'feature/prayer/presentation/widgets/prayer_location_setup_alert.dart -> app/routing/route_provider.dart',
  'feature/prayer/presentation/widgets/prayer_location_setup_alert.dart -> feature/onboarding/presentation/providers/onboarding_state_provider.dart',
  'feature/settings/presentation/widgets/tabs/settings_appearance_tab.dart -> feature/onboarding/presentation/widgets/onboarding_rerun_tile.dart',
  'feature/settings/presentation/widgets/typography/typography_settings_section.dart -> feature/quran/presentation/models/quran_ui_models.dart',
  'feature/settings/presentation/widgets/typography/typography_settings_section.dart -> feature/quran/presentation/providers/quran_screen_settings_provider.dart',
  'feature/settings/presentation/widgets/typography/typography_settings_section.dart -> feature/quran/presentation/widgets/scale/quran_zoom_control.dart',
};
