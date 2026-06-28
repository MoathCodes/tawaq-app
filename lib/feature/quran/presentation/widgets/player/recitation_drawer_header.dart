import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/theme/theme.dart';

/// Header row for the expanded recitation drawer.
class RecitationDrawerHeader extends ConsumerWidget {
  /// Creates the drawer header.
  const RecitationDrawerHeader({
    required this.reciterName,
    required this.riwayah,
    required this.rangeWidget,
    required this.showSubtitle,
    super.key,
  });

  final String reciterName;
  final String riwayah;
  final Widget? rangeWidget;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final subtitleStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );

    return MouseClick(
      onClick: () => showReciterDialog(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reciterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                if (showSubtitle)
                  Row(
                    children: [
                      if (riwayah.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            riwayah,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle,
                          ),
                        ),
                        if (rangeWidget != null)
                          Text(' · ', style: subtitleStyle),
                      ],
                      if (rangeWidget != null) Flexible(child: rangeWidget!),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          RecitationDrawerChipButton(
            icon: FLucideIcons.mic,
            label: l10n.quranRecitationSwitchReciter,
            onPress: () => showReciterDialog(context),
          ),
        ],
      ),
    );
  }
}

/// Compact chip button used in the recitation drawer.
class RecitationDrawerChipButton extends StatelessWidget {
  /// Creates a chip button.
  const RecitationDrawerChipButton({
    required this.icon,
    required this.label,
    required this.onPress,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return MouseClick(
      onClick: onPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.secondary,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.secondaryForeground),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: typography.body.xs.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatted ayah range label for drawer subtitles.
class RecitationDrawerRangeSubtitle extends StatelessWidget {
  /// Creates a range subtitle.
  const RecitationDrawerRangeSubtitle({
    required this.rangeLabel,
    required this.suffix,
    super.key,
  });

  final String rangeLabel;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AyahRangeLabelText(
      rangeLabel,
      style: theme.typography.body.xs.copyWith(
        color: theme.colors.mutedForeground,
      ),
      suffix: suffix,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
