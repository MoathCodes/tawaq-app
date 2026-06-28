part of 'recitation_drawer.dart';

// --- header ---

/// Header row for the expanded recitation drawer.
class _DrawerHeader extends ConsumerWidget {
  /// Creates the drawer header.
  const _DrawerHeader({
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
          _DrawerChipButton(
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
class _DrawerChipButton extends StatelessWidget {
  /// Creates a chip button.
  const _DrawerChipButton({
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
class _DrawerRangeSubtitle extends StatelessWidget {
  /// Creates a range subtitle.
  const _DrawerRangeSubtitle({
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

// --- transport ---


/// Transport, seek bar, and elapsed time for the recitation drawer.
class _DrawerTransportSection extends HookConsumerWidget {
  /// Creates the transport section.
  const _DrawerTransportSection({
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
          _DrawerDownloadProgress(
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
            _DrawerTimeLabel(
              playback.currentAyah != null
                  ? '${_fmt(playback.position)} · '
                        '${l10n.ayahLabel} ${playback.currentAyah}'
                  : _fmt(playback.position),
            ),
            _DrawerTimeLabel(_fmt(playback.duration)),
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
class _DrawerDownloadProgress extends StatelessWidget {
  /// Creates the download progress row.
  const _DrawerDownloadProgress({
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

class _DrawerTimeLabel extends StatelessWidget {
  const _DrawerTimeLabel(this.text, {super.key});

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

// --- actions ---

/// Offline files, range/repeat, and sleep timer tiles in the drawer.
class _DrawerActionsSection extends ConsumerWidget {
  /// Creates the actions section.
  const _DrawerActionsSection({
    required this.rangeLabel,
    required this.rangeWidget,
    required this.surahName,
    required this.repeatSuffix,
    super.key,
  });

  final String rangeLabel;
  final Widget? rangeWidget;
  final String surahName;
  final String repeatSuffix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.watch(recitationControllerProvider);

    final sleepLabel = switch (playback.sleep) {
      RecitationSleep.off => l10n.quranRecitationSleepOff,
      RecitationSleep.endOfAyah => l10n.quranRecitationSleepEndOfAyah,
      RecitationSleep.endOfRange => l10n.quranRecitationSleepEndOfRange,
      RecitationSleep.endOfSurah => l10n.quranRecitationSleepEndOfSurah,
      RecitationSleep.after10 => l10n.quranRecitationSleepAfter('10'),
      RecitationSleep.after20 => l10n.quranRecitationSleepAfter('20'),
      RecitationSleep.after30 => l10n.quranRecitationSleepAfter('30'),
    };

    return FTileGroup(
      children: [
        FTile(
          prefix: const Icon(FLucideIcons.folder),
          title: Text(l10n.quranRecitationOfflineFiles),
          subtitle: _DrawerCacheSizeSubtitle(
            bytesAsync: ref.watch(totalCacheBytesProvider),
          ),
          onPress: () => showOfflineFilesDialog(context),
        ),
        FTile(
          prefix: const Icon(FLucideIcons.repeat),
          title: Text(l10n.quranRecitationRangeRepeat),
          subtitle: rangeWidget != null
              ? _DrawerRangeSubtitle(
                  rangeLabel: rangeLabel,
                  suffix: repeatSuffix,
                )
              : Text(surahName),
          onPress: () => showRangeRepeatDialog(context),
        ),
        FTile(
          prefix: const Icon(FLucideIcons.moon),
          title: Text(l10n.quranRecitationSleepTimer),
          subtitle: Text(sleepLabel),
          onPress: () => showSleepTimerDialog(context),
        ),
      ],
    );
  }
}

class _DrawerCacheSizeSubtitle extends StatelessWidget {
  const _DrawerCacheSizeSubtitle({required this.bytesAsync, super.key});

  final AsyncValue<int> bytesAsync;

  @override
  Widget build(BuildContext context) {
    final bytes = bytesAsync.value ?? 0;
    return Text(formatByteSize(bytes));
  }
}

// --- settings ---


/// Volume slider and playback toggles in the recitation drawer.
class _DrawerSettingsSection extends ConsumerWidget {
  /// Creates the settings section.
  const _DrawerSettingsSection({
    required this.isNarrow,
    required this.persistedVolume,
    super.key,
  });

  final bool isNarrow;
  final double persistedVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final controller = ref.read(recitationControllerProvider.notifier);
    final settings = ref.watch(recitationSettingsProvider).value;

    final volumeSlider = PersistedVolumeSlider(
      persistedVolume: persistedVolume,
      onPreview: (v) => unawaited(controller.setVolumePreview(v)),
      onCommit: (v) => unawaited(controller.commitVolume(v)),
    );

    final autoScrollToggle = FTooltip(
      tipBuilder: (_, _) => Text(l10n.quranRecitationAutoScrollDesc),
      child: _DrawerToggleChip(
        label: l10n.quranRecitationAutoScroll,
        value: settings?.autoScroll ?? true,
        onChange: (v) => ref
            .read(recitationSettingsProvider.notifier)
            .setAutoScroll(value: v),
      ),
    );

    final highlightToggle = FTooltip(
      tipBuilder: (_, _) => Text(l10n.quranRecitationHighlightDesc),
      child: _DrawerToggleChip(
        label: l10n.quranRecitationHighlight,
        value: settings?.highlightAyah ?? true,
        onChange: (v) => ref
            .read(recitationSettingsProvider.notifier)
            .setHighlightAyah(value: v),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                FLucideIcons.volume2,
                size: 17,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: volumeSlider),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [autoScrollToggle, highlightToggle],
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          FLucideIcons.volume2,
          size: 17,
          color: colors.mutedForeground,
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 110, child: volumeSlider),
        const Spacer(),
        autoScrollToggle,
        const SizedBox(width: AppSpacing.md),
        highlightToggle,
      ],
    );
  }
}

class _DrawerToggleChip extends StatelessWidget {
  const _DrawerToggleChip({
    required this.label,
    required this.value,
    required this.onChange,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FSwitch(value: value, onChange: onChange),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: typography.body.xs.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.secondaryForeground,
          ),
        ),
      ],
    );
  }
}
