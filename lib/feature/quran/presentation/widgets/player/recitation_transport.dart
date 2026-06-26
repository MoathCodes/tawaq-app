import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_equalizer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/theme/theme.dart';

/// Minimum allocated width before the reciter subtitle is shown.
const _kTransportSubtitleMinWidth = 300.0;

/// Compact inline transport that lives in the title bar.
///
/// Always visible so the user can open the player or resume from any screen.
class RecitationTransport extends ConsumerWidget {
  /// Creates a [RecitationTransport].
  const RecitationTransport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _TransportPill();
  }
}

class _TransportPill extends ConsumerWidget {
  const _TransportPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    final playback = ref.watch(recitationControllerProvider);
    final drawerOpen = ref.watch(recitationDrawerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final mushaf = ref.read(quranMushafControllerProvider);

    final isPlaying = playback.isPlaying;
    final isLoading = playback.isLoading || playback.downloading;
    final hasPending = playback.hasPendingReciter;
    final showMetadata = playback.active;

    final surah = playback.surah;
    final surahName = surah == null
        ? ''
        : mushaf.getSurahSync(surah)?.displayName ??
              l10n.quranSurahLabel('$surah');
    final selectedReciter = ref.watch(selectedReciterProvider).value;
    final currentReciterName =
        playback.reciter?.name ?? selectedReciter?.name ?? '';
    final reciterName = hasPending
        ? '${currentReciterName.isNotEmpty ? '$currentReciterName → ' : ''}'
              '${playback.pendingReciter!.name}'
        : currentReciterName;

    final titleStyle = theme.typography.body.sm.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final titleWidget = playback.currentAyah != null
        ? SurahNameWithSuffix(
            surahName: surahName,
            suffix: ' · ${playback.currentAyah}',
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : SurahNameText(
            surahName,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final showSubtitle =
            reciterName.isNotEmpty &&
            maxWidth >= _kTransportSubtitleMinWidth &&
            (showMetadata || hasPending);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: IntrinsicWidth(
            child: FTile(
              style: _compactTileStyle(theme),
              semanticsLabel: drawerOpen
                  ? l10n.quranRecitationClosePlayer
                  : l10n.quranRecitationOpenPlayer,
              prefix: _TransportControls(
                isPlaying: isPlaying,
                isLoading: isLoading,
                isPending: hasPending,
                canSkip: showMetadata,
                onPlayPause: controller.togglePlayPause,
                onSkipPrevious: controller.skipPrevious,
                onSkipNext: controller.skipNext,
                onCancelPending: controller.cancelPendingReciter,
              ),
              title: showMetadata || surahName.isNotEmpty
                  ? titleWidget
                  : const SizedBox.shrink(),
              subtitle: showSubtitle
                  ? Text(
                      reciterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              suffix: _TransportSuffix(
                isPlaying: isPlaying,
                drawerOpen: drawerOpen,
              ),
              onPress: ref.read(recitationDrawerProvider.notifier).toggle,
            ),
          ),
        );
      },
    );
  }
}

/// Play, skip and cancel controls shown at the start of the transport pill.
class _TransportControls extends StatelessWidget {
  const _TransportControls({
    required this.isPlaying,
    required this.isLoading,
    required this.isPending,
    required this.canSkip,
    required this.onPlayPause,
    required this.onSkipPrevious,
    required this.onSkipNext,
    required this.onCancelPending,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isPending;
  final bool canSkip;
  final Future<void> Function() onPlayPause;
  final Future<void> Function() onSkipPrevious;
  final Future<void> Function() onSkipNext;
  final VoidCallback onCancelPending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canSkip) ...[
          _TransportIcon(
            icon: FLucideIcons.skipBack,
            tooltip: l10n.quranRecitationPrevious,
            onPress: onSkipPrevious,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        _RoundPlayButton(
          isPlaying: isPlaying,
          isLoading: isLoading,
          isPending: isPending,
          onPressed: onPlayPause,
        ),
        if (isPending) ...[
          const SizedBox(width: AppSpacing.xs),
          _TransportIcon(
            icon: FLucideIcons.x,
            tooltip: l10n.quranRecitationCancel,
            onPress: onCancelPending,
          ),
        ],
        if (canSkip) ...[
          const SizedBox(width: AppSpacing.xs),
          _TransportIcon(
            icon: FLucideIcons.skipForward,
            tooltip: l10n.quranRecitationNext,
            onPress: onSkipNext,
          ),
        ],
      ],
    );
  }
}

/// Chevron and equalizer shown at the end of the transport pill.
class _TransportSuffix extends StatelessWidget {
  const _TransportSuffix({
    required this.isPlaying,
    required this.drawerOpen,
  });

  final bool isPlaying;
  final bool drawerOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPlaying) ...[
          RecitationEqualizer(
            color: colors.primary,
            animating: !drawerOpen,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Icon(
          drawerOpen ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
          size: 17,
          color: colors.mutedForeground,
        ),
      ],
    );
  }
}

class _RoundPlayButton extends StatelessWidget {
  const _RoundPlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.isPending,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isPending;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    if (isLoading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
        ),
      );
    }
    final button = FTappable(
      onPress: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          isPending
              ? FLucideIcons.check
              : isPlaying
              ? FLucideIcons.pause
              : FLucideIcons.play,
          size: 18,
          color: colors.primaryForeground,
        ),
      ),
    );
    if (isPending) {
      return FTooltip(
        tipBuilder: (_, _) => Text(context.l10n.quranRecitationApply),
        child: button,
      );
    }
    return button;
  }
}

class _TransportIcon extends StatelessWidget {
  const _TransportIcon({
    required this.icon,
    required this.onPress,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPress;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: MouseClick(
        onClick: onPress,
        child: Icon(icon, size: 18, color: colors.secondaryForeground),
      ),
    );
  }
}

/// A compact [FTileStyle] suitable for the constrained title bar pill.
FTileStyle _compactTileStyle(FThemeData theme) {
  final base = theme.tileStyles.primary;
  return base.copyWith(
    contentStyle: (base.contentStyle as FTileContentStyle).copyWith(
      suffixedPadding: const EdgeInsetsGeometryDelta.value(
        EdgeInsets.fromLTRB(6, 4, 8, 4),
      ),
      unsuffixedPadding: const EdgeInsetsGeometryDelta.value(
        EdgeInsets.fromLTRB(6, 4, 8, 4),
      ),
      prefixIconSpacing: 6,
      suffixIconSpacing: 4,
    ),
  );
}
