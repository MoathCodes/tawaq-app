import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/theme/theme.dart';

/// Bottom prev/next controls for fortress reading (RTL layout).
class FortressReadingNavBar extends StatelessWidget {
  /// Creates a nav bar.
  const FortressReadingNavBar({
    required this.center,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.studyDua,
    super.key,
  });

  /// Center label (e.g. remaining count).
  final Widget center;

  /// When set and [FortressDuaItem.hasFocusStudyAction], shows study control
  /// in the center cluster above [center].
  final FortressDuaItem? studyDua;

  /// Whether previous is enabled.
  final bool canGoPrevious;

  /// Whether next is enabled.
  final bool canGoNext;

  /// Goes to the previous thikr.
  final VoidCallback? onPrevious;

  /// Goes to the next thikr.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showStudy =
        studyDua != null && studyDua!.hasFocusStudyAction;

    return NonSelectable(
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FortressLabeledNavButton(
          label: FortressA11y.navActionLabel(l10n, isPrevious: true),
          enabled: canGoPrevious,
          onPress: onPrevious,
          prefix: const Icon(FLucideIcons.chevronLeft, size: 18),
          child: Text(l10n.fortressPrevious),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStudy) FortressDuaStudyNavAction(dua: studyDua!),
              if (showStudy) const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: center,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FortressLabeledNavButton(
          label: FortressA11y.navActionLabel(l10n, isPrevious: false),
          enabled: canGoNext,
          onPress: onNext,
          prefix: const Icon(FLucideIcons.chevronRight, size: 18),
          child: Text(l10n.next),
        ),
      ],
      ),
    );
  }
}
