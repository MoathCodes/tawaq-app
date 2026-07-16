part of 'recitation_drawer.dart';

// --- header ---

/// Header row for the expanded recitation drawer.
class _DrawerHeader extends ConsumerWidget {
  /// Creates the drawer header.
  const _DrawerHeader({
    required this.reciterName,
    required this.riwayah,
  });

  final String reciterName;
  final String riwayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final subtitleStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );

    final playback = ref.watch(recitationControllerProvider);
    final settings = ref.watch(recitationSettingsProvider).value;
    final mushaf = ref.read(quranMushafControllerProvider);

    final surah = playback.surah;
    final surahName = surah == null
        ? ''
        : mushaf.getSurahSync(surah)?.displayName ??
              l10n.quranSurahLabel('$surah');
    final rangeLabel = playback.rangeFrom != null
        ? formatAyahRangeLabel(
            mushaf: mushaf,
            l10n: l10n,
            from: playback.rangeFrom!,
            to: playback.rangeTo,
          )
        : surahName;
    final ayahRepeat = settings?.ayahRepeatCount ?? 1;
    final rangeRepeat = settings?.rangeRepeatCount ?? 1;
    final showPlaybackStatus = playback.active && rangeLabel.isNotEmpty;

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
                if (riwayah.isNotEmpty)
                  Text(
                    riwayah,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                if (showPlaybackStatus) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _DrawerPlaybackStatus(
                    rangeLabel: rangeLabel,
                    rangeRepeatCount: rangeRepeat,
                    repeatsRemaining: playback.repeatsRemaining,
                    ayahRepeatCount: ayahRepeat,
                    currentAyah: playback.currentAyah,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FTooltip(
            tipBuilder: (_, _) => Text(l10n.quranRecitationGoToQuran),
            child: FButton.icon(
              variant: .ghost,
              onPress: surah == null
                  ? null
                  : () => unawaited(
                        ref
                            .read(recitationControllerProvider.notifier)
                            .goToPlaybackInMushaf(context),
                      ),
              child: const Icon(FLucideIcons.book),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FButton(
            prefix: const Icon(FLucideIcons.mic),
            onPress: () => showReciterDialog(context),
            variant: .outline,
            child: Text(l10n.quranRecitationSwitchReciter),
          ),
        ],
      ),
    );
  }
}

/// Live playback status: range, current ayah, and repeat progress.
class _DrawerPlaybackStatus extends HookWidget {
  /// Creates a playback status line.
  const _DrawerPlaybackStatus({
    required this.rangeLabel,
    required this.rangeRepeatCount,
    required this.repeatsRemaining,
    required this.ayahRepeatCount,
    this.currentAyah,
  });

  final String rangeLabel;
  final int rangeRepeatCount;
  final int repeatsRemaining;
  final int ayahRepeatCount;
  final int? currentAyah;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final colors = theme.colors;
    final subtitleStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );

    final prevRepeats = useRef(repeatsRemaining);
    final pulseTick = useState(0);
    useEffect(
      () {
        if (rangeRepeatCount > 1 &&
            repeatsRemaining < prevRepeats.value &&
            repeatsRemaining > 0) {
          pulseTick.value++;
        }
        prevRepeats.value = repeatsRemaining;
        return null;
      },
      [repeatsRemaining, rangeRepeatCount],
    );

    final suffixParts = <String>[];
    final ayah = currentAyah;
    if (ayah != null) {
      suffixParts.add('${l10n.ayahLabel} $ayah');
    }
    if (ayahRepeatCount > 1) {
      suffixParts.add(
        '${l10n.quranRangeRepeatChip(ayahRepeatCount)} '
        '${l10n.quranRangeRepeatEachAyah}',
      );
    }
    if (rangeRepeatCount > 1) {
      final loopCurrent = rangeRepeatCount - repeatsRemaining + 1;
      suffixParts.add(
        l10n.quranRecitationSelectionLoopProgress(
          loopCurrent.clamp(1, rangeRepeatCount),
          rangeRepeatCount,
        ),
      );
    }
    final suffix = suffixParts.isEmpty ? '' : ' · ${suffixParts.join(' · ')}';

    final baseLabel = AyahRangeLabelText(
      rangeLabel,
      style: subtitleStyle,
      suffix: suffix,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (pulseTick.value == 0) return baseLabel;

    return baseLabel
        .animate(key: ValueKey(pulseTick.value))
        .fadeIn(duration: theme.durations.fast)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: theme.durations.normal,
          curve: Curves.easeOutCubic,
        );
  }
}

// --- transport ---

/// Transport, seek bar, and elapsed time for the recitation drawer.
class _DrawerTransportSection extends HookConsumerWidget {
  /// Creates the transport section.
  const _DrawerTransportSection({
    required this.surahLeftSlot,
    required this.surahRightSlot,
    this.ayahLeftSlot,
    this.ayahRightSlot,
  });

  final SkipControl surahLeftSlot;
  final SkipControl surahRightSlot;
  final SkipControl? ayahLeftSlot;
  final SkipControl? ayahRightSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.watch(recitationControllerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final downloadProgress = ref.watch(recitationDownloadProgressProvider);
    final showDownload = playback.isLoading && downloadProgress != null;

    final timing = controller.currentTiming;
    final timeline = timing != null ? timelineFor(playback, timing) : null;
    final audioService = ref.watch(tawaqAudioServiceProvider);
    final playWhenReady =
        useStream(
          useMemoized(
            () => audioService.playWhenReadyStream,
            [audioService],
          ),
        ).data ??
        audioService.playWhenReady;
    final bufferedRanges =
        useStream(
          useMemoized(
            () => audioService.player.stream.demuxerCacheState.map(
              (s) => s.seekableRanges,
            ),
            [audioService],
          ),
        ).data ??
        const <CacheRange>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDownload) ...[
          _DrawerDownloadProgress(
            progress: downloadProgress,
            onCancel: controller.cancelDownload,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        RecitationDrawerTransportControls(
          isPlaying: playWhenReady,
          isLoading: playback.isLoading,
          isEnded: playback.isEnded,
          onPlayPause: controller.togglePlayPause,
          surahLeftSlot: surahLeftSlot,
          surahRightSlot: surahRightSlot,
          ayahLeftSlot: ayahLeftSlot,
          ayahRightSlot: ayahRightSlot,
        ),
        const SizedBox(height: AppSpacing.lg),
        _RecitationSegmentedSeekBar(
          playback: playback,
          timeline: timeline,
          bufferedRanges: bufferedRanges,
          isLoading: playback.isLoading,
          onSeek: controller.seekTo,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DrawerTimeLabel(
              playback.isEnded
                  ? l10n.quranRecitationEnded
                  : playback.currentAyah != null
                  ? '${formatPlaybackDuration(playback.position)} · '
                        '${l10n.ayahLabel} ${playback.currentAyah}'
                  : formatPlaybackDuration(playback.position),
            ),
            _DrawerTimeLabel(formatPlaybackDuration(playback.duration)),
          ],
        ),
      ],
    );
  }

}

/// Maps recitation state into the neutral [SegmentedSeekBar].
class _RecitationSegmentedSeekBar extends ConsumerWidget {
  const _RecitationSegmentedSeekBar({
    required this.playback,
    required this.timeline,
    required this.bufferedRanges,
    required this.onSeek,
    this.isLoading = false,
  });

  final RecitationState playback;
  final RecitationTimeline? timeline;
  final List<CacheRange> bufferedRanges;
  final ValueChanged<Duration> onSeek;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final durations = theme.durations;
    final isArabic = ref.watch(localeProvider) == 'ar';
    final mushaf = ref.read(quranMushafControllerProvider);
    final surah = playback.surah;

    String formatAyahNumber(int ayah) =>
        isArabic ? ayah.toHinduArabic() : '$ayah';

    final timing = timeline?.timing;
    final segments = timing == null
        ? const <SeekBarSegment>[]
        : [
            for (final a in timing.ayat)
              if (a.ayah > 0)
                SeekBarSegment(
                  index: a.ayah,
                  start: Duration(milliseconds: a.startMs),
                  end: Duration(milliseconds: a.endMs),
                ),
          ];

    final buffered = bufferedRanges
        .map((r) => (r.start, r.end))
        .toList(growable: false);

    RepeatStatus? repeat;
    if (playback.ayahRepeatCount > 1 && playback.currentAyah != null) {
      repeat = RepeatStatus(
        current: playback.ayahRepeatCount - playback.ayahRepeatsRemaining + 1,
        total: playback.ayahRepeatCount,
        segmentIndex: playback.currentAyah!,
      );
    }

    final style = SegmentedSeekBarStyle(
      activeColor: colors.primary,
      inactiveColor: colors.mutedForeground,
      bufferedColor: colors.primary.withValues(alpha: 0.3),
      thumbColor: colors.primary,
      thumbBorderColor: colors.primaryForeground,
      repeatBadgeColor: colors.primary,
      repeatBadgeTextColor: colors.primaryForeground,
      repeatPulseColor: colors.primary,
      tooltipTextStyle: typography.body.xs.copyWith(
        color: colors.foreground,
        fontWeight: FontWeight.w600,
      ),
      tooltipBackgroundColor: colors.card,
      tooltipBorderColor: colors.border,
      segmentGapColor: colors.card,
      ayahGlowColor: colors.primary,
      thumbRadius: 8,
      trackHeight: 4,
      thumbTweenDuration: durations.fast,
      snapScaleDuration: durations.instant,
      pulseDuration: durations.slow,
      revealDuration: durations.normal,
    );

    return SegmentedSeekBar(
      position: playback.pendingSeekTarget ?? playback.position,
      duration: playback.duration,
      enabled: playback.duration.inMilliseconds > 0 && !isLoading,
      segments: segments,
      bufferedRanges: buffered,
      repeat: repeat,
      onSeek: onSeek,
      style: style,
      segmentLabel: (index) =>
          '${l10n.ayahLabel} ${formatAyahNumber(index)}',
      segmentNumberLabel: formatAyahNumber,
      segmentUthmaniExcerpt: surah == null
          ? null
          : (index) async {
              final ayah = await mushaf.getAyahBySurah(surah, index);
              final preview = ayahSearchPreviewText(ayah);
              return preview.isEmpty ? null : preview;
            },
      repeatLabel: l10n.quranRecitationRepeatProgress,
      unavailableLabel: l10n.quranRecitationUnavailable,
    );
  }
}

/// Download progress row shown while a surah is caching.
class _DrawerDownloadProgress extends StatelessWidget {
  /// Creates the download progress row.
  const _DrawerDownloadProgress({
    required this.progress,
    required this.onCancel,
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
  const _DrawerTimeLabel(this.text);

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
    required this.configuredRangeLabel,
    required this.ayahRepeatCount,
    required this.rangeRepeatCount,
  });

  final String configuredRangeLabel;
  final int ayahRepeatCount;
  final int rangeRepeatCount;

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

    final configParts = <String>[configuredRangeLabel];
    if (ayahRepeatCount > 1) {
      configParts.add(
        '${l10n.quranRangeRepeatChip(ayahRepeatCount)} '
        '${l10n.quranRangeRepeatEachAyah}',
      );
    }
    if (rangeRepeatCount > 1) {
      configParts.add(
        '${l10n.quranRangeRepeatChip(rangeRepeatCount)} '
        '${l10n.quranRecitationRepeatScopeSelection}',
      );
    }
    final rangeConfigSubtitle = configParts.join(' · ');

    final saveSnapshot = ref.watch(recitationOfflineSaveProgressProvider);
    final playDownloadProgress = ref.watch(recitationDownloadProgressProvider);
    final cached =
        ref.watch(cachedRecitationsSnapshotProvider).value?.files ?? const [];
    final optimisticSaved = ref.watch(optimisticOfflineSavedProvider);
    final reciter = playback.reciter;
    final moshaf = playback.moshaf;
    final surah = playback.surah;
    final isCached = reciter != null &&
        moshaf != null &&
        surah != null &&
        cached.any(
          (f) =>
              f.reciterId == reciter.id &&
              f.moshafId == moshaf.id &&
              f.surah == surah,
        );
    final isOptimisticSaved = reciter != null &&
        moshaf != null &&
        surah != null &&
        optimisticSaved.any(
          (k) =>
              k.reciterId == reciter.id &&
              k.moshafId == moshaf.id &&
              k.surah == surah,
        );
    final isSaved = isCached || isOptimisticSaved;
    final isExplicitSaving = saveSnapshot != null &&
        reciter != null &&
        moshaf != null &&
        surah != null &&
        saveSnapshot.matches(
          reciterId: reciter.id,
          moshafId: moshaf.id,
          surah: surah,
        );
    // Play-download progress lives only in the transport section to avoid a
    // duplicate progress row; still reflect auto-save on the tile subtitle.
    final isPlayDownloading =
        playback.isLoading && playDownloadProgress != null;
    final isSaving = isExplicitSaving || isPlayDownloading;
    final saveSubtitle = isSaving
        ? l10n.quranRecitationSavingOffline
        : isSaved
        ? l10n.quranRecitationSavedOffline
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FLucideIcons.folder),
              title: Text(l10n.quranRecitationOfflineFiles),
              subtitle: _DrawerCacheSizeSubtitle(
                bytes: ref
                        .watch(cachedRecitationsSnapshotProvider)
                        .value
                        ?.totalBytes ??
                    0,
              ),
              onPress: () => showOfflineFilesDialog(context),
            ),
            if (surah != null)
              FTile(
                prefix: Icon(
                  isSaved ? FLucideIcons.circleCheck : FLucideIcons.download,
                ),
                title: Text(l10n.quranRecitationSaveOffline),
                subtitle: saveSubtitle == null ? null : Text(saveSubtitle),
                onPress: isSaved || isSaving
                    ? null
                    : () => unawaited(
                        ref
                            .read(recitationControllerProvider.notifier)
                            .saveCurrentSurahOffline(),
                      ),
              ),
            FTile(
              prefix: const Icon(FLucideIcons.repeat),
              title: Text(l10n.quranRecitationRangeRepeat),
              subtitle: Text(rangeConfigSubtitle),
              onPress: () => showRangeRepeatDialog(context),
            ),
            FTile(
              prefix: const Icon(FLucideIcons.moon),
              title: Text(l10n.quranRecitationSleepTimer),
              subtitle: Text(sleepLabel),
              onPress: () => showSleepTimerDialog(context),
            ),
          ],
        ),
        // Explicit offline-save progress only — play downloads use transport.
        if (isExplicitSaving) ...[
          const SizedBox(height: AppSpacing.sm),
          _DrawerDownloadProgress(
            progress: saveSnapshot.progress,
            onCancel: ref
                .read(recitationControllerProvider.notifier)
                .cancelOfflineSave,
          ),
        ],
      ],
    );
  }
}

class _DrawerCacheSizeSubtitle extends StatelessWidget {
  const _DrawerCacheSizeSubtitle({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
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
  });

  final bool isNarrow;
  final double persistedVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;
    final controller = ref.read(recitationControllerProvider.notifier);
    final settings = ref.watch(recitationSettingsProvider).value;
    final moshaf = ref.watch(selectedRecitationProvider).value?.moshaf;
    final nonHafs = moshaf != null && !isHafsRiwayah(moshaf.name);
    final highlightOn = settings?.highlightAyah ?? true;
    final showHighlightWarning = nonHafs && highlightOn;

    final volumeSlider = PersistedVolumeSlider(
      persistedVolume: persistedVolume,
      onPreview: (v) => unawaited(controller.setVolumePreview(v)),
      onCommit: (v) => unawaited(controller.commitVolume(v)),
    );

    final autoScrollToggle = FTooltip(
      tipBuilder: (_, _) => Text(l10n.quranRecitationAutoScrollDesc),
      child: FSwitch(
        leadingLabel: true,
        label: Text(l10n.quranRecitationAutoScroll),
        value: settings?.autoScroll ?? true,
        onChange: (v) => ref
            .read(recitationSettingsProvider.notifier)
            .setAutoScroll(value: v),
      ),
    );

    final highlightToggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FTooltip(
          tipBuilder: (_, _) => Text(l10n.quranRecitationHighlightDesc),
          child: FSwitch(
            leadingLabel: true,
            label: Text(l10n.quranRecitationHighlight),
            value: highlightOn,
            onChange: (v) => ref
                .read(recitationSettingsProvider.notifier)
                .setHighlightAyah(value: v),
          ),
        ),
        if (nonHafs) ...[
          const SizedBox(width: AppSpacing.xs),
          FTooltip(
            tipBuilder: (_, _) =>
                Text(l10n.quranRecitationHighlightNonHafsWarning),
            child: const Icon(
              FLucideIcons.triangleAlert,
              size: 16,
              // color: colors.destructive,
            ),
          ),
        ],
      ],
    );

    final highlightWarningAlert = showHighlightWarning
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Opacity(
              opacity: 0.88,
              child: FAlert(
                icon: const Icon(FLucideIcons.triangleAlert, size: 16),
                title: Text(
                  l10n.quranRecitationHighlightNonHafsWarning,
                  style: theme.typography.body.sm,
                ),
              ),
            ),
          )
        : null;

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?highlightWarningAlert,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?highlightWarningAlert,
        Row(
          children: [
            Expanded(flex: 2, child: volumeSlider),
            const Spacer(),
            Expanded(
              flex: 4,
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  autoScrollToggle,
                  highlightToggle,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
