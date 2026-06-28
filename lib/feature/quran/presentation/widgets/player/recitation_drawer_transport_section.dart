import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_seek_bar.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/theme/theme.dart';

/// Transport, seek bar, and elapsed time for the recitation drawer.
class RecitationDrawerTransportSection extends HookConsumerWidget {
  /// Creates the transport section.
  const RecitationDrawerTransportSection({
    required this.leftSlot,
    required this.rightSlot,
    super.key,
  });

  final SkipControl leftSlot;
  final SkipControl rightSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.watch(recitationControllerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final downloadProgress = ref.watch(recitationDownloadProgressProvider);
    final showDownload = playback.isLoading && downloadProgress != null;

    final timing = controller.currentTiming;
    final timeline = timing != null
        ? timelineFor(playback, timing)
        : null;
    final audioService = ref.watch(tawaqAudioServiceProvider);
    final bufferedRanges = useStream(
      useMemoized(
        () => audioService.player.stream.demuxerCacheState.map(
          (s) => s.seekableRanges,
        ),
        [audioService],
      ),
    ).data ?? const <CacheRange>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDownload) ...[
          RecitationDrawerDownloadProgress(
            progress: downloadProgress!,
            onCancel: controller.cancelDownload,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        RecitationTransportControls(
          isPlaying: playback.isPlaying,
          isLoading: playback.isLoading,
          onPlayPause: controller.togglePlayPause,
          leftSlot: leftSlot,
          rightSlot: rightSlot,
          density: RecitationTransportDensity.expanded,
        ),
        const SizedBox(height: AppSpacing.lg),
        RecitationSeekBar(
          playback: playback,
          timeline: timeline,
          bufferedRanges: bufferedRanges,
          onSeek: controller.seekTo,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RecitationDrawerTimeLabel(
              playback.currentAyah != null
                  ? '${_fmt(playback.position)} · '
                        '${l10n.ayahLabel} ${playback.currentAyah}'
                  : _fmt(playback.position),
            ),
            RecitationDrawerTimeLabel(_fmt(playback.duration)),
          ],
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Download progress row shown while a surah is caching.
class RecitationDrawerDownloadProgress extends StatelessWidget {
  /// Creates the download progress row.
  const RecitationDrawerDownloadProgress({
    required this.progress,
    required this.onCancel,
    super.key,
  });

  final DownloadProgress progress;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final fraction = progress.fraction;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: theme.radii.full,
            ),
            child: fraction == null
                ? null
                : FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: ColoredBox(color: colors.primary),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FTooltip(
          tipBuilder: (_, _) => Text(l10n.quranRecitationCancel),
          child: MouseClick(
            onClick: () => unawaited(onCancel()),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                FLucideIcons.x,
                size: 16,
                color: colors.destructive,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RecitationDrawerTimeLabel extends StatelessWidget {
  const RecitationDrawerTimeLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      text,
      style: theme.typography.body.xs.copyWith(
        color: theme.colors.mutedForeground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
