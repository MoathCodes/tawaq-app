import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Presentation helpers for [FortressCategory] icons and loading placeholders.
extension FortressCategoryUiX on FortressCategory {
  /// Icon derived from Hisn recurrence.
  IconData get icon => iconForRecurrence(recurrence);
}

/// Maps Hisn recurrence to a sidebar/card icon.
IconData iconForRecurrence(HisnRecurrence recurrence) => switch (recurrence) {
  HisnRecurrence.daily => FLucideIcons.sunrise,
  HisnRecurrence.weekly => FLucideIcons.clock,
  HisnRecurrence.monthly => FLucideIcons.sparkles,
  HisnRecurrence.yearly => FLucideIcons.calendar,
};

/// Placeholder categories shown while Hisn data loads.
///
/// [count] is the number of skeleton rows to synthesize.
List<FortressCategory> fortressCategoryPlaceholders({
  required AppLocalizations l10n,
  int count = 8,
}) {
  return List.generate(
    count,
    (i) => FortressCategory(
      chapterId: -i - 1,
      title: l10n.loading,
      recurrence: HisnRecurrence.daily,
      supplicationCount: 0,
    ),
  );
}
