import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_thikr_body.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// How [FortressDuaContent] composes thikr, virtue, and study sections.
enum FortressDuaContentMode {
  /// Category list: plain excerpt or full text (no mushaf widgets).
  previewCollapsed,

  /// Category list: expanded row with virtue and inline study.
  previewExpanded,

  /// Focus reading: mushaf-backed thikr only (virtue shown separately).
  focusReading,

  /// On-demand study sheet or inline study block.
  study,
}

/// Unified thikr + virtue + study presentation for browse and reading flows.
class FortressDuaContent extends ConsumerWidget {
  /// Creates dua content for the given [mode].
  const FortressDuaContent({
    required this.dua,
    required this.mode,
    this.muted = false,
    this.proseStyle,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final FortressDuaItem dua;
  final FortressDuaContentMode mode;
  final bool muted;
  final TextStyle? proseStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (mode) {
      FortressDuaContentMode.previewCollapsed => _ThikrPreviewText(
        dua: dua,
        isExpanded: false,
      ),
      FortressDuaContentMode.previewExpanded => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThikrPreviewText(dua: dua, isExpanded: true),
          if (dua.hasVirtue) ...[
            const SizedBox(height: AppSpacing.md),
            FortressDuaVirtueLine(virtue: dua.virtue!),
          ],
          if (dua.hasStudyContent) ...[
            const SizedBox(height: AppSpacing.lg),
            FortressDuaStudyContent(dua: dua, compact: true),
          ],
        ],
      ),
      FortressDuaContentMode.focusReading => FortressThikrBody(
        dua: dua,
        muted: muted,
        proseStyle: proseStyle,
        textAlign: textAlign,
      ),
      FortressDuaContentMode.study => FortressDuaStudyContent(dua: dua),
    };
  }
}

class _ThikrPreviewText extends StatelessWidget {
  const _ThikrPreviewText({
    required this.dua,
    required this.isExpanded,
  });

  final FortressDuaItem dua;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isQuran = dua.isQuranicPassage;

    var style = theme.typography.body.sm.copyWith(
      color: isExpanded ? theme.colors.foreground : theme.colors.mutedForeground,
      height: isQuran ? 2 : 1.6,
      fontSize: isQuran ? (isExpanded ? 22 : 20) : null,
      fontWeight: isExpanded && isQuran ? FontWeight.w600 : FontWeight.w500,
    );
    if (isQuran) {
      style = style.copyWith(fontFamily: FontFamily.uthmanicHafs);
    }

    return Text(
      dua.text,
      style: style,
      textAlign: TextAlign.start,
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? null : TextOverflow.ellipsis,
    );
  }
}

/// Virtue line constrained for focus-reading footer chrome.
class FortressFocusVirtueFooter extends StatelessWidget {
  /// Creates a virtue footer.
  const FortressFocusVirtueFooter({
    required this.virtue,
    required this.horizontalPadding,
    super.key,
  });

  final String virtue;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        AppSpacing.sm,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kFortressReadingMaxWidth),
          child: FortressDuaVirtueLine(virtue: virtue),
        ),
      ),
    );
  }
}
