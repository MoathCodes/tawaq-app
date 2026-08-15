import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/theme/theme.dart';

/// Visual density for shared recitation transport controls.
enum RecitationTransportDensity {
  /// Compact title-bar pill controls.
  compact,

  /// Expanded drawer controls.
  expanded,
}

/// Skip icon button shared by the compact transport and expanded drawer.
class RecitationTransportIcon extends StatelessWidget {
  const RecitationTransportIcon({
    required this.icon,
    required this.onPress,
    required this.tooltip,
    this.density = RecitationTransportDensity.compact,
    super.key,
  });

  final IconData icon;
  final Future<void> Function() onPress;
  final String tooltip;
  final RecitationTransportDensity density;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final iconSize = switch (density) {
      RecitationTransportDensity.compact => 18.0,
      RecitationTransportDensity.expanded => 24.0,
    };

    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: MouseClick(
        semanticsTooltip: tooltip,
        onClick: () => unawaited(onPress()),
        child: Icon(icon, size: iconSize, color: colors.secondaryForeground),
      ),
    );
  }
}

/// Circular play/pause button shared by the compact transport and drawer.
class RecitationPlayButton extends StatelessWidget {
  const RecitationPlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onPress,
    this.isEnded = false,
    this.density = RecitationTransportDensity.compact,
    super.key,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isEnded;
  final Future<void> Function() onPress;
  final RecitationTransportDensity density;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (size, iconSize, progressSize) = switch (density) {
      RecitationTransportDensity.compact => (
        36.0,
        18.0,
        FCircularProgressSizeVariant.sm,
      ),
      RecitationTransportDensity.expanded => (
        58.0,
        26.0,
        FCircularProgressSizeVariant.md,
      ),
    };

    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: FCircularProgress(size: progressSize),
        ),
      );
    }

    return MouseClick(
      onClick: () => unawaited(onPress()),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          isEnded
              ? FLucideIcons.rotateCcw
              : isPlaying
              ? FLucideIcons.pause
              : FLucideIcons.play,
          size: iconSize,
          color: colors.primaryForeground,
        ),
      ),
    );
  }
}

/// A recitation skip action (plays the previous or next ayah/surah).
typedef SkipAction = Future<void> Function();

/// The icon, accessibility label, and action for one skip-control slot.
typedef SkipControl = ({
  IconData icon,
  String label,
  SkipAction onPress,
});

/// Returns the left skip-control slot for the current text direction.
///
/// Slots are visual positions — callers must lay out transport rows in LTR
/// so RTL mirroring is not cancelled by [Row]'s directionality.
///
/// [icon] is always the left-pointing glyph for this slot; only the action and
/// label mirror in RTL (left = next).
SkipControl leftSkipControl({
  required bool isRtl,
  required SkipAction skipPrevious,
  required SkipAction skipNext,
  required String previousLabel,
  required String nextLabel,
  IconData icon = FLucideIcons.skipBack,
}) {
  if (isRtl) {
    return (
      icon: icon,
      label: nextLabel,
      onPress: skipNext,
    );
  }
  return (
    icon: icon,
    label: previousLabel,
    onPress: skipPrevious,
  );
}

/// Returns the right skip-control slot for the current text direction.
///
/// See [leftSkipControl] — [icon] stays right-pointing; RTL swaps action/label
/// only (right = previous).
SkipControl rightSkipControl({
  required bool isRtl,
  required SkipAction skipPrevious,
  required SkipAction skipNext,
  required String previousLabel,
  required String nextLabel,
  IconData icon = FLucideIcons.skipForward,
}) {
  if (isRtl) {
    return (
      icon: icon,
      label: previousLabel,
      onPress: skipPrevious,
    );
  }
  return (
    icon: icon,
    label: nextLabel,
    onPress: skipNext,
  );
}

/// Drawer transport with optional ayah-level skips flanking surah-level skips.
class RecitationDrawerTransportControls extends StatelessWidget {
  const RecitationDrawerTransportControls({
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPause,
    required this.surahLeftSlot,
    required this.surahRightSlot,
    this.ayahLeftSlot,
    this.ayahRightSlot,
    this.isEnded = false,
    super.key,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isEnded;
  final Future<void> Function() onPlayPause;
  final SkipControl surahLeftSlot;
  final SkipControl surahRightSlot;
  final SkipControl? ayahLeftSlot;
  final SkipControl? ayahRightSlot;

  @override
  Widget build(BuildContext context) {
    // Keep visual left/right stable; [leftSkipControl]/[rightSkipControl]
    // already swap actions/icons for RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (ayahLeftSlot != null) ...[
            RecitationTransportIcon(
              icon: ayahLeftSlot!.icon,
              tooltip: ayahLeftSlot!.label,
              onPress: ayahLeftSlot!.onPress,
              density: RecitationTransportDensity.expanded,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          RecitationTransportIcon(
            icon: surahLeftSlot.icon,
            tooltip: surahLeftSlot.label,
            onPress: surahLeftSlot.onPress,
            density: RecitationTransportDensity.expanded,
          ),
          const SizedBox(width: AppSpacing.lg),
          RecitationPlayButton(
            isPlaying: isPlaying,
            isLoading: isLoading,
            isEnded: isEnded,
            onPress: onPlayPause,
            density: RecitationTransportDensity.expanded,
          ),
          const SizedBox(width: AppSpacing.lg),
          RecitationTransportIcon(
            icon: surahRightSlot.icon,
            tooltip: surahRightSlot.label,
            onPress: surahRightSlot.onPress,
            density: RecitationTransportDensity.expanded,
          ),
          if (ayahRightSlot != null) ...[
            const SizedBox(width: AppSpacing.sm),
            RecitationTransportIcon(
              icon: ayahRightSlot!.icon,
              tooltip: ayahRightSlot!.label,
              onPress: ayahRightSlot!.onPress,
              density: RecitationTransportDensity.expanded,
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered play/pause with optional skip controls for both transport surfaces.
class RecitationTransportControls extends StatelessWidget {
  const RecitationTransportControls({
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPause,
    required this.leftSlot,
    required this.rightSlot,
    this.isEnded = false,
    this.density = RecitationTransportDensity.compact,
    this.showSkip = true,
    super.key,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isEnded;
  final Future<void> Function() onPlayPause;
  final SkipControl leftSlot;
  final SkipControl rightSlot;
  final RecitationTransportDensity density;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    final gap = switch (density) {
      RecitationTransportDensity.compact => AppSpacing.xs,
      RecitationTransportDensity.expanded => AppSpacing.lg,
    };

    // Keep visual left/right stable; [leftSkipControl]/[rightSkipControl]
    // already swap actions/icons for RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSkip) ...[
            RecitationTransportIcon(
              icon: leftSlot.icon,
              tooltip: rightSlot.label,
              onPress: rightSlot.onPress,
              density: density,
            ),
            SizedBox(width: gap),
          ],
          RecitationPlayButton(
            isPlaying: isPlaying,
            isLoading: isLoading,
            isEnded: isEnded,
            onPress: onPlayPause,
            density: density,
          ),
          if (showSkip) ...[
            SizedBox(width: gap),
            RecitationTransportIcon(
              icon: rightSlot.icon,
              tooltip: leftSlot.label,
              onPress: leftSlot.onPress,
              density: density,
            ),
          ],
        ],
      ),
    );
  }
}
