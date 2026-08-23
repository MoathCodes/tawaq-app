part of 'recitation_drawer.dart';

// The drawer shares the localized surah-name rule with the compact transport.

// --- header ---

/// Header row for the expanded recitation drawer.
class _DrawerHeader extends ConsumerWidget {
  /// Creates the drawer header.
  const _DrawerHeader({
    required this.reciterName,
    required this.riwayah,
    required this.isInitializing,
    required this.onGoToQuran,
  });

  final String reciterName;
  final String riwayah;
  final bool isInitializing;
  final VoidCallback? onGoToQuran;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final subtitleStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );

    final header = ref.watch(
      recitationControllerProvider.select(
        (p) => (
          surah: p.surah,
          rangeFrom: p.rangeFrom,
          rangeTo: p.rangeTo,
          active: p.active,
          repeatsRemaining: p.repeatsRemaining,
          currentAyah: p.currentAyah,
          isInitializing: p.isInitializing,
        ),
      ),
    );
    final settings = ref.watch(recitationSettingsProvider).value;
    final mushaf = ref.read(quranMushafControllerProvider);

    final surah = header.surah;
    final isMetadataLoading = isInitializing || header.isInitializing;
    final surahName = AyahReferenceLogic.surahName(
      isMetadataLoading || surah == null ? null : mushaf.getSurahSync(surah),
      surah ?? 0,
      preferArabic: Localizations.localeOf(context).languageCode == 'ar',
      fallbackName: '',
    );
    final rangeLabel = header.rangeFrom != null
        ? formatAyahRangeLabel(
            mushaf: mushaf,
            l10n: l10n,
            from: header.rangeFrom!,
            to: header.rangeTo,
          )
        : surahName;
    final ayahRepeat = settings?.ayahRepeatCount ?? 1;
    final rangeRepeat = settings?.rangeRepeatCount ?? 1;
    final showPlaybackStatus = header.active && rangeLabel.isNotEmpty;

    final identity = isMetadataLoading
        ? FSkeletonizer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reciter', style: theme.typography.body.md),
                const SizedBox(height: AppSpacing.xs),
                Text('Riwayah', style: subtitleStyle),
              ],
            ),
          )
        : Column(
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
                  repeatsRemaining: header.repeatsRemaining,
                  ayahRepeatCount: ayahRepeat,
                  currentAyah: header.currentAyah,
                ),
              ],
            ],
          );

    return MouseClick(
      disabled: isMetadataLoading,
      onClick: isMetadataLoading ? null : () => showReciterDialog(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: identity),
          const SizedBox(width: AppSpacing.md),
          FTooltip(
            tipBuilder: (_, _) => Text(l10n.quranRecitationGoToQuran),
            child: FButton.icon(
              variant: .ghost,
              onPress: isMetadataLoading || surah == null
                  ? null
                  : () => unawaited(
                      Future<void>(() {
                        onGoToQuran?.call();
                      }).then((_) {
                        ref
                            .read(recitationControllerProvider.notifier)
                            .goToPlaybackInMushaf();
                        if (context.mounted) Navigator.of(context).pop();
                      }),
                    ),
              child: const Icon(FLucideIcons.book),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FButton(
            prefix: const Icon(FLucideIcons.mic),
            onPress: isMetadataLoading
                ? null
                : () => showReciterDialog(context),
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
    useEffect(() {
      if (rangeRepeatCount > 1 &&
          repeatsRemaining < prevRepeats.value &&
          repeatsRemaining > 0) {
        pulseTick.value++;
      }
      prevRepeats.value = repeatsRemaining;
      return null;
    }, [repeatsRemaining, rangeRepeatCount]);

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
    // Status/chrome only — position ticks rebuild seek/time below.
    final chrome = ref.watch(
      recitationViewProvider.select(
        (view) => (
          isLoading: view.isLoading,
          isInitializing: view.isInitializing,
          canPlay: view.canPlay,
          isEnded: view.isEnded,
          isPlaying: view.isPlaying,
          bufferedRanges: view.bufferedRanges,
        ),
      ),
    );
    final controller = ref.read(recitationControllerProvider.notifier);
    final downloadProgress = ref.watch(recitationDownloadProgressProvider);
    final showDownload = chrome.isLoading && downloadProgress != null;

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
          isPlaying: chrome.isPlaying,
          isLoading: chrome.isLoading,
          isInitializing: chrome.isInitializing,
          canPlay: chrome.canPlay,
          isEnded: chrome.isEnded,
          onPlayPause: chrome.canPlay ? controller.togglePlayPause : null,
          surahLeftSlot: surahLeftSlot,
          surahRightSlot: surahRightSlot,
          ayahLeftSlot: ayahLeftSlot,
          ayahRightSlot: ayahRightSlot,
        ),
        const SizedBox(height: AppSpacing.lg),
        _DrawerSeekAndTime(
          bufferedRanges: chrome.bufferedRanges,
          onSeek: controller.seekTo,
        ),
      ],
    );
  }
}

/// Seek bar + elapsed/duration labels — the only drawer subtree that watches
/// position so chrome does not rebuild on every tick.
class _DrawerSeekAndTime extends ConsumerWidget {
  const _DrawerSeekAndTime({
    required this.bufferedRanges,
    required this.onSeek,
  });

  final List<PlaybackBufferRange> bufferedRanges;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(recitationViewProvider);
    final playback = view.session;
    final controller = ref.read(recitationControllerProvider.notifier);
    final timing = controller.currentTiming;
    final timeline = timing != null ? timelineFor(playback, timing) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecitationSegmentedSeekBar(
          playback: playback,
          position: playback.pendingSeekTarget ?? view.position,
          duration: view.duration,
          timeline: timeline,
          bufferedRanges: bufferedRanges,
          isLoading: playback.isLoading,
          onSeek: onSeek,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DrawerTimeLabel(
              playback.isEnded
                  ? l10n.quranRecitationEnded
                  : playback.currentAyah != null
                  ? '${formatPlaybackDuration(view.position)} · '
                        '${l10n.ayahLabel} ${playback.currentAyah}'
                  : formatPlaybackDuration(view.position),
            ),
            _DrawerTimeLabel(formatPlaybackDuration(view.duration)),
          ],
        ),
      ],
    );
  }
}

/// Maps recitation state into the neutral [SegmentedSeekBar].
class _RecitationSegmentedSeekBar extends HookConsumerWidget {
  const _RecitationSegmentedSeekBar({
    required this.playback,
    required this.position,
    required this.duration,
    required this.timeline,
    required this.bufferedRanges,
    required this.onSeek,
    this.isLoading = false,
  });

  final RecitationState playback;
  final Duration position;
  final Duration duration;
  final RecitationTimeline? timeline;
  final List<PlaybackBufferRange> bufferedRanges;
  final ValueChanged<Duration> onSeek;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final durations = theme.durations;
    final isArabic = ref.watch(localeProvider).value == 'ar';
    final mushaf = ref.read(quranMushafControllerProvider);
    final surah = playback.surah;

    String formatAyahNumber(int ayah) =>
        isArabic ? ayah.toHinduArabic() : '$ayah';

    final timing = timeline?.timing;
    final segments = useMemoized(
      () => timing == null
          ? const <SeekBarSegment>[]
          : [
              for (final a in timing.ayat)
                if (a.ayah > 0)
                  SeekBarSegment(
                    index: a.ayah,
                    start: Duration(milliseconds: a.startMs),
                    end: Duration(milliseconds: a.endMs),
                  ),
            ],
      [timing],
    );

    final buffered = useMemoized(
      () => bufferedRanges
          .map((range) => (range.start, range.end))
          .toList(growable: false),
      [bufferedRanges],
    );

    RepeatStatus? repeat;
    if (playback.ayahRepeatCount > 1 && playback.currentAyah != null) {
      repeat = RepeatStatus(
        remaining: playback.ayahRepeatsRemaining,
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
      ayahGlowColor: colors.primary,
      thumbRadius: 8,
      trackHeight: 4,
      previewRadius: theme.radii.md,
      thumbTweenDuration: durations.fast,
      snapScaleDuration: durations.instant,
      pulseDuration: durations.slow,
      revealDuration: durations.normal,
    );

    // Non-Hafs: numbers only — Hafs Uthmani would be missing/wrong for extra
    // timing verses. Keep full timing segments so scrub still matches audio.
    final showUthmaniExcerpt = seekBarShowsUthmaniExcerpt(
      playback.moshaf?.name,
    );

    return SegmentedSeekBar(
      position: position,
      duration: duration,
      enabled: duration.inMilliseconds > 0 && !isLoading,
      segments: segments,
      bufferedRanges: buffered,
      repeat: repeat,
      onSeek: onSeek,
      style: style,
      segmentLabel: (index) => '${l10n.ayahLabel} ${formatAyahNumber(index)}',
      segmentNumberLabel: formatAyahNumber,
      segmentContentKey: (surah: surah, moshaf: playback.moshaf?.id),
      segmentUthmaniExcerpt: !showUthmaniExcerpt || surah == null
          ? null
          : (index) async {
              final ayah = await mushafAyahOrNull(mushaf, surah, index);
              if (ayah == null) return null;
              final preview = ayahSearchPreviewText(ayah);
              return preview.isEmpty ? null : preview;
            },
      repeatLabel: l10n.quranRecitationRepeatProgress,
      remainingLabel: l10n.quranRecitationPlaysRemaining,
      semanticsLabel: l10n.quranRecitationSeekBarLabel,
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
              child: Icon(FLucideIcons.x, size: 16, color: colors.destructive),
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
    final actions = ref.watch(
      recitationControllerProvider.select(
        (p) => (
          sleep: p.sleep,
          isLoading: p.isLoading,
          reciter: p.reciter,
          moshaf: p.moshaf,
          surah: p.surah,
        ),
      ),
    );

    final sleepLabel = switch (actions.sleep) {
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

    final offline = ref.watch(
      recitationOfflineStoreProvider.select(
        (state) => (
          totalBytes: state.value?.totalBytes ?? 0,
          saveProgress: state.value?.saveProgress,
          error: state.value?.error,
        ),
      ),
    );
    final saveSnapshot = offline.saveProgress;
    final reciter = actions.reciter;
    final moshaf = actions.moshaf;
    final surah = actions.surah;
    final isExplicitSaving =
        saveSnapshot != null &&
        reciter != null &&
        moshaf != null &&
        surah != null &&
        saveSnapshot.matches(
          reciterId: reciter.id,
          moshafId: moshaf.id,
          surah: surah,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTileGroup(
          children: [
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
            FTile(
              prefix: const Icon(FLucideIcons.folder),
              title: Text(l10n.quranRecitationOfflineFiles),
              subtitle: _DrawerCacheSizeSubtitle(bytes: offline.totalBytes),
              onPress: () => showOfflineFilesDialog(context),
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
        if (offline.error case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          Stack(
            children: [
              FAlert(
                variant: .destructive,
                icon: const Icon(FLucideIcons.triangleAlert),
                title: Text(
                  l10n.errorOccurredWhile(l10n.quranRecitationSaveOffline),
                ),
                subtitle: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 36),
                  child: Text(error),
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.sm,
                end: AppSpacing.sm,
                child: FTooltip(
                  tipBuilder: (_, _) => Text(l10n.cancel),
                  child: FButton.icon(
                    variant: .ghost,
                    onPress: ref
                        .read(recitationOfflineStoreProvider.notifier)
                        .clearError,
                    child: const Icon(FLucideIcons.x, size: 16),
                  ),
                ),
              ),
            ],
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
    final hasAyahTiming = controller.hasAyahTiming;

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
            semanticsLabel: l10n.quranRecitationHighlightDesc,
            leadingLabel: true,
            enabled: hasAyahTiming,
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
            child: Icon(
              FLucideIcons.triangleAlert,
              semanticLabel: l10n.quranRecitationHighlightNonHafsWarning,
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
                children: [autoScrollToggle, highlightToggle],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
