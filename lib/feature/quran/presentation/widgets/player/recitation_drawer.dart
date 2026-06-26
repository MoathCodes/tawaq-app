import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_playback.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/lifted_surah_ayah_selectors.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/offline_files_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/queue_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/sleep_timer_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// The full recitation transport that drops down under the title bar when the
/// user expands the compact transport. Rendered as an overlay (scrim + panel)
/// so it floats above the routed content on any screen.
class RecitationDrawerOverlay extends ConsumerWidget {
  /// Creates a [RecitationDrawerOverlay].
  const RecitationDrawerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(recitationDrawerProvider);
    final colors = context.theme.colors;

    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        opacity: open ? 1 : 0,
        duration: context.theme.durations.fast,
        curve: Curves.easeOut,
        child: open
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: MouseClick(
                      onClick: ref
                          .read(recitationDrawerProvider.notifier)
                          .close,
                      child: ColoredBox(
                        color: colors.barrier.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: _DrawerPanel(),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _DrawerPanel extends ConsumerWidget {
  const _DrawerPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final isRtl = context.l10n.localeName.contains('ar');

    final playback = ref.watch(recitationControllerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final settings = ref.watch(recitationSettingsProvider).value;
    final settingsNotifier = ref.read(recitationSettingsProvider.notifier);
    final mushaf = ref.read(quranMushafControllerProvider);

    final isPlaying = playback.isPlaying;
    final isLoading = playback.isLoading;
    final hasPending = playback.hasPendingReciter;

    final surah = playback.surah;
    final surahName = surah == null
        ? ''
        : mushaf.getSurahSync(surah)?.displayName ??
              l10n.quranSurahLabel('$surah');
    final reciterName = playback.reciter?.name ?? '';
    final pendingReciterName = playback.pendingReciter?.name ?? '';
    final riwayah = playback.moshaf?.name ?? '';
    final pendingRiwayah = playback.pendingMoshaf?.name ?? '';
    final rangeLabel = playback.rangeFrom != null
        ? formatAyahRangeLabel(
            mushaf: mushaf,
            l10n: l10n,
            from: playback.rangeFrom!,
            to: playback.rangeTo,
          )
        : playback.isRange
        ? '$surahName · ${playback.rangeStart}–${playback.rangeEnd}'
        : surahName;
    final subtitleStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );
    final rangeWidget = rangeLabel.isEmpty
        ? null
        : AyahRangeLabelText(
            rangeLabel,
            style: subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    final showSubtitle = riwayah.isNotEmpty || rangeWidget != null;

    final repeat = settings?.repeatCount ?? 1;
    final volume = settingsNotifier.volumePreview ?? settings?.volume ?? 100;

    final sleepLabel = switch (playback.sleep) {
      RecitationSleep.off => l10n.quranRecitationSleepOff,
      RecitationSleep.endOfAyah => l10n.quranRecitationSleepEndOfAyah,
      RecitationSleep.endOfRange => l10n.quranRecitationSleepEndOfRange,
      RecitationSleep.endOfSurah => l10n.quranRecitationSleepEndOfSurah,
      RecitationSleep.after10 => l10n.quranRecitationSleepAfter('10'),
      RecitationSleep.after20 => l10n.quranRecitationSleepAfter('20'),
      RecitationSleep.after30 => l10n.quranRecitationSleepAfter('30'),
    };

    final timing = playback.moshaf?.hasTiming == true
        ? controller.currentTiming
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(320.0, 680.0)
            : 620.0;
        final isNarrow = width < 480;
        final transportGap = isNarrow ? AppSpacing.md : AppSpacing.lg;

        return Container(
          width: width,
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.vertical(
              bottom: context.theme.radii.xl.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.barrier.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Now playing + switch reciter.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: hasPending
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      reciterName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.typography.body.md.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.mutedForeground,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                    ),
                                    child: Icon(
                                      FLucideIcons.arrowRight,
                                      size: 16,
                                      color: colors.mutedForeground,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      pendingReciterName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.typography.body.md.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (showSubtitle)
                                Row(
                                  children: [
                                    if (pendingRiwayah.isNotEmpty) ...[
                                      Flexible(
                                        child: Text(
                                          pendingRiwayah,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: subtitleStyle,
                                        ),
                                      ),
                                      if (rangeWidget != null)
                                        Text(' · ', style: subtitleStyle),
                                    ],
                                    if (rangeWidget != null)
                                      Flexible(child: rangeWidget),
                                  ],
                                ),
                            ],
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
                                    if (rangeWidget != null)
                                      Flexible(child: rangeWidget),
                                  ],
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (hasPending) ...[
                    _ChipButton(
                      icon: FLucideIcons.x,
                      label: l10n.quranRecitationCancel,
                      onPress: controller.cancelPendingReciter,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  _ChipButton(
                    icon: FLucideIcons.mic,
                    label: l10n.quranRecitationSwitchReciter,
                    onPress: () => showReciterDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ScrubberSection(
                playback: playback,
                timing: timing,
                onSeek: controller.seekTo,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Main transport row.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TransportIcon(
                    icon: !isRtl
                        ? FLucideIcons.skipBack
                        : FLucideIcons.skipForward,
                    onPress: !isRtl
                        ? controller.skipNext
                        : controller.skipPrevious,
                    tooltip: !isRtl
                        ? l10n.quranRecitationNext
                        : l10n.quranRecitationPrevious,
                  ),
                  SizedBox(width: transportGap),
                  _BigPlayButton(
                    isPlaying: isPlaying,
                    isLoading: isLoading,
                    isPending: hasPending,
                    onPress: controller.togglePlayPause,
                  ),
                  SizedBox(width: transportGap),
                  _TransportIcon(
                    icon: !isRtl
                        ? FLucideIcons.skipForward
                        : FLucideIcons.skipBack,
                    onPress: !isRtl
                        ? controller.skipPrevious
                        : controller.skipNext,
                    tooltip: !isRtl
                        ? l10n.quranRecitationPrevious
                        : l10n.quranRecitationNext,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Action grid: two forui tile groups side by side.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FTileGroup(
                      children: [
                        FTile(
                          prefix: const Icon(FLucideIcons.repeat),
                          title: Text(l10n.quranRecitationRangeRepeat),
                          subtitle: AyahRangeLabelText(
                            rangeLabel,
                            style: theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                            suffix: ' · $repeat×',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FTileGroup(
                      children: [
                        FTile(
                          prefix: const Icon(FLucideIcons.listMusic),
                          title: Text(l10n.quranRecitationQueue),
                          subtitle: Text(l10n.quranRecitationQueueSubtitle),
                          onPress: () => showQueueDialog(context),
                        ),
                        FTile(
                          prefix: const Icon(FLucideIcons.folder),
                          title: Text(l10n.quranRecitationOfflineFiles),
                          subtitle: Text(l10n.quranRecitationOfflineSubtitle),
                          onPress: () => showOfflineFilesDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 1, color: colors.border),
              const SizedBox(height: AppSpacing.md),
              // Volume + toggles.
              if (isNarrow) ...[
                Row(
                  children: [
                    Icon(
                      FLucideIcons.volume2,
                      size: 17,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FSlider(
                        control: FSliderControl.managedContinuous(
                          initial: FSliderValue(
                            max: (volume / 100).clamp(0.0, 1.0),
                          ),
                          onChange: (value) => unawaited(
                            controller.setVolumePreview(value.max * 100),
                          ),
                        ),
                        onEnd: (value) => unawaited(
                          controller.commitVolume(value.max * 100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FTooltip(
                      tipBuilder: (_, _) =>
                          Text(l10n.quranRecitationAutoScrollDesc),
                      child: _ToggleChip(
                        label: l10n.quranRecitationAutoScroll,
                        value: settings?.autoScroll ?? true,
                        onChange: (v) => ref
                            .read(recitationSettingsProvider.notifier)
                            .setAutoScroll(value: v),
                      ),
                    ),
                    FTooltip(
                      tipBuilder: (_, _) =>
                          Text(l10n.quranRecitationHighlightDesc),
                      child: _ToggleChip(
                        label: l10n.quranRecitationHighlight,
                        value: settings?.highlightAyah ?? true,
                        onChange: (v) => ref
                            .read(recitationSettingsProvider.notifier)
                            .setHighlightAyah(value: v),
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Icon(
                      FLucideIcons.volume2,
                      size: 17,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 110,
                      child: FSlider(
                        control: FSliderControl.managedContinuous(
                          initial: FSliderValue(
                            max: (volume / 100).clamp(0.0, 1.0),
                          ),
                          onChange: (value) => unawaited(
                            controller.setVolumePreview(value.max * 100),
                          ),
                        ),
                        onEnd: (value) =>
                            unawaited(controller.commitVolume(value.max * 100)),
                      ),
                    ),
                    const Spacer(),
                    FTooltip(
                      tipBuilder: (_, _) =>
                          Text(l10n.quranRecitationAutoScrollDesc),
                      child: _ToggleChip(
                        label: l10n.quranRecitationAutoScroll,
                        value: settings?.autoScroll ?? true,
                        onChange: (v) => ref
                            .read(recitationSettingsProvider.notifier)
                            .setAutoScroll(value: v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FTooltip(
                      tipBuilder: (_, _) =>
                          Text(l10n.quranRecitationHighlightDesc),
                      child: _ToggleChip(
                        label: l10n.quranRecitationHighlight,
                        value: settings?.highlightAyah ?? true,
                        onChange: (v) => ref
                            .read(recitationSettingsProvider.notifier)
                            .setHighlightAyah(value: v),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ScrubberSection extends StatelessWidget {
  const _ScrubberSection({
    required this.playback,
    required this.timing,
    required this.onSeek,
  });

  final RecitationPlayback playback;
  final SurahTiming? timing;
  final Future<void> Function(Duration position) onSeek;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = playback.duration;
    final position = playback.position;

    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SeekBar(
          progress: progress,
          enabled: duration.inMilliseconds > 0,
          timing: timing,
          duration: duration,
          onSeek: (fraction) => unawaited(
            onSeek(
              Duration(
                milliseconds: (duration.inMilliseconds * fraction).round(),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TimeLabel(
              playback.currentAyah != null
                  ? '${_DrawerPanel._fmt(position)} · '
                        '${l10n.ayahLabel} ${playback.currentAyah}'
                  : _DrawerPanel._fmt(position),
            ),
            _TimeLabel(_DrawerPanel._fmt(duration)),
          ],
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onPress,
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

class _TransportIcon extends StatelessWidget {
  const _TransportIcon({
    required this.icon,
    required this.onPress,
    required this.tooltip,
    this.size = 24,
  });

  final IconData icon;
  final Future<void> Function() onPress;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: MouseClick(
        onClick: () => unawaited(onPress()),
        child: Icon(icon, size: size, color: colors.secondaryForeground),
      ),
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.isPending,
    required this.onPress,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isPending;
  final Future<void> Function() onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    if (isLoading) {
      return const SizedBox(
        width: 58,
        height: 58,
        child: Center(child: FCircularProgress()),
      );
    }
    return MouseClick(
      onClick: () => unawaited(onPress()),
      child: Container(
        width: 58,
        height: 58,
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
          size: 26,
          color: colors.primaryForeground,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChange,
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

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.text);

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

/// Scrubber backed by [FSlider]. With ayah timing data the slider is discrete
/// and snaps to each ayah section; otherwise it falls back to continuous scrub.
class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.progress,
    required this.onSeek,
    required this.enabled,
    required this.duration,
    this.timing,
  });

  final double progress;
  final ValueChanged<double> onSeek;
  final bool enabled;
  final Duration duration;
  final SurahTiming? timing;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _dragging = false;
  double _dragValue = 0;
  List<FSliderMark>? _cachedMarks;
  int? _cachedTimingKey;
  int? _cachedDurationMs;

  List<FSliderMark> _buildMarks(BuildContext context) {
    final timing = widget.timing;
    final totalMs = widget.duration.inMilliseconds;
    final timingKey = Object.hash(timing?.surah, timing?.readId, timing?.ayat);
    if (_cachedMarks != null &&
        _cachedTimingKey == timingKey &&
        _cachedDurationMs == totalMs) {
      return _cachedMarks!;
    }

    if (timing == null || totalMs <= 0) {
      _cachedMarks = const [];
      _cachedTimingKey = timingKey;
      _cachedDurationMs = totalMs;
      return _cachedMarks!;
    }

    final typography = context.theme.typography.body.xs.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    final values = <double>{0.0, 1.0};
    final ayahByValue = <double, int>{};

    for (final a in timing.ayat) {
      if (a.ayah <= 0) continue;
      final fraction = (a.startMs / totalMs).clamp(0.0, 1.0);
      values.add(fraction);
      ayahByValue[fraction] = a.ayah;
    }

    final sorted = values.toList()..sort();
    _cachedMarks = [
      for (final value in sorted)
        FSliderMark.mark(
          value: value,
          label: ayahByValue[value] == null
              ? null
              : Text('${ayahByValue[value]}', style: typography),
        ),
    ];
    _cachedTimingKey = timingKey;
    _cachedDurationMs = totalMs;
    return _cachedMarks!;
  }

  @override
  Widget build(BuildContext context) {
    final marks = _buildMarks(context);
    final discrete = marks.isNotEmpty;
    final streamed = widget.progress.clamp(0.0, 1.0);
    final value = (_dragging ? _dragValue : streamed).clamp(0.0, 1.0);

    final slider = FSlider(
      key: ValueKey(
        'recitation-seek-${widget.timing?.surah}-'
        '${widget.timing?.readId}-${widget.duration.inMilliseconds}',
      ),
      marks: marks,
      tooltipControls: const FSliderTooltipControls.disabled(),
      control: discrete
          ? FSliderControl.liftedDiscrete(
              value: FSliderValue(max: value),
              onChange: widget.enabled
                  ? (v) => setState(() {
                      _dragging = true;
                      _dragValue = v.max;
                    })
                  : (_) {},
            )
          : FSliderControl.liftedContinuous(
              value: FSliderValue(max: value),
              onChange: widget.enabled
                  ? (v) => setState(() {
                      _dragging = true;
                      _dragValue = v.max;
                    })
                  : (_) {},
            ),
      onEnd: widget.enabled
          ? (v) {
              setState(() => _dragging = false);
              widget.onSeek(v.max);
            }
          : null,
    );

    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: slider,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.progress != oldWidget.progress) {
      _dragValue = widget.progress.clamp(0.0, 1.0);
    }
    if (widget.timing?.surah != oldWidget.timing?.surah ||
        widget.duration != oldWidget.duration) {
      _dragging = false;
    }
  }
}
