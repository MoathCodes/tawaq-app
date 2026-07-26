import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/prayer_alert_copy.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_icon.dart';
import 'package:tawaq/theme/theme.dart';

/// Forui card shown during prayer alert presentation.
class AdhanAlertCard extends HookConsumerWidget {
  /// Creates [AdhanAlertCard].
  const AdhanAlertCard({
    this.showCloseButton = false,
    super.key,
  });

  /// Whether to show a dismiss control in the title row (overlay mode).
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(adhanAlertControllerProvider);
    final kind = alert.kind;
    final prayer = alert.prayer;
    final scheduledTime = alert.scheduledTime;
    if (kind == null || prayer == null || scheduledTime == null) {
      return const SizedBox.shrink();
    }

    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final prayerName = prayer.getLocaleName(l10n);
    final timeLabel = DateFormat.Hm().format(scheduledTime);
    final title = prayerAlertTitle(l10n, kind, prayerName);
    final playbackState = ref.watch(audioPlayerControllerProvider);
    final audioService = ref.watch(tawaqAudioServiceProvider);
    // Only mirror progress while adhan owns the shared player — otherwise the
    // bar reads stale recitation position/duration (often near EOF → full).
    final adhanOwnsPlayer =
        audioService.currentLeaseOwner == kAdhanLeaseOwner;
    final showPlayback =
        alert.playsSound &&
        adhanOwnsPlayer &&
        playbackState is! PlaybackIdle &&
        playbackState is! PlaybackError;
    final position = useStream(
      audioService.positionStream,
    );
    final duration = useStream(
      audioService.durationStream,
    );
    final maxMs = duration.data?.inMilliseconds ?? 0;
    final progress = maxMs <= 0
        ? 0.0
        : ((position.data?.inMilliseconds ?? 0) / maxMs).clamp(0.0, 1.0);

    Future<void> dismiss() =>
        ref.read(prayerAlertDispatcherProvider.notifier).dismiss();

    final dismissLabel =
        showPlayback ? l10n.adhanStop : l10n.prayerAlertDismiss;
    final dismissIcon =
        showPlayback ? FLucideIcons.square : FLucideIcons.bellOff;

    final cardDecoration = BoxDecoration(
      color: colors.card,
      borderRadius: alert.isCompactMorph ? null : theme.radii.lg,
      border: alert.isCompactMorph
          ? null
          : Border.all(color: colors.primary.withValues(alpha: 0.45)),
      boxShadow: alert.isCompactMorph
          ? null
          : [
              BoxShadow(
                color: colors.barrier.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );

    final content = alert.isCompactMorph
        ? _CompactAlertBody(
            prayer: prayer,
            title: title,
            timeLabel: timeLabel,
            colors: colors,
            theme: theme,
            showPlayback: showPlayback,
            progress: progress,
            dismissLabel: dismissLabel,
            onDismiss: dismiss,
          )
        : _OverlayAlertBody(
            prayer: prayer,
            title: title,
            timeLabel: timeLabel,
            colors: colors,
            theme: theme,
            showCloseButton: showCloseButton,
            showPlayback: showPlayback,
            progress: progress,
            dismissLabel: dismissLabel,
            dismissIcon: dismissIcon,
            onDismiss: dismiss,
          );

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          unawaited(dismiss());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DecoratedBox(
        decoration: cardDecoration,
        child: alert.isCompactMorph
            ? content
            : ClipRRect(
                borderRadius: theme.radii.lg,
                child: SizedBox(width: double.infinity, child: content),
              ),
      ),
    );
  }
}

/// Dense layout for the morphed compact alert window.
class _CompactAlertBody extends StatelessWidget {
  const _CompactAlertBody({
    required this.prayer,
    required this.title,
    required this.timeLabel,
    required this.colors,
    required this.theme,
    required this.showPlayback,
    required this.progress,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final Prayer prayer;
  final String title;
  final String timeLabel;
  final FColors colors;
  final FThemeData theme;
  final bool showPlayback;
  final double progress;
  final String dismissLabel;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              PrayerIcon(
                prayer: prayer,
                isActive: true,
                colors: colors,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeLabel,
                      style: theme.typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              FButton(
                variant: .secondary,
                onPress: () => unawaited(onDismiss()),
                child: Text(dismissLabel),
              ),
            ],
          ),
          if (showPlayback)
            ClipRRect(
              borderRadius: theme.radii.full,
              child: LinearProgressIndicator(
                value: progress == 0 ? null : progress,
                backgroundColor: colors.muted,
                color: colors.primary,
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }
}

/// Modal layout when the main window is already open.
class _OverlayAlertBody extends StatelessWidget {
  const _OverlayAlertBody({
    required this.prayer,
    required this.title,
    required this.timeLabel,
    required this.colors,
    required this.theme,
    required this.showCloseButton,
    required this.showPlayback,
    required this.progress,
    required this.dismissLabel,
    required this.dismissIcon,
    required this.onDismiss,
  });

  final Prayer prayer;
  final String title;
  final String timeLabel;
  final FColors colors;
  final FThemeData theme;
  final bool showCloseButton;
  final bool showPlayback;
  final double progress;
  final String dismissLabel;
  final IconData dismissIcon;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Color.lerp(colors.primary, colors.card, 0.88),
          ),
          child: _AlertHeader(
            prayer: prayer,
            title: title,
            timeLabel: timeLabel,
            colors: colors,
            theme: theme,
            showCloseButton: showCloseButton,
            onDismiss: onDismiss,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (showPlayback)
                ClipRRect(
                  borderRadius: theme.radii.full,
                  child: LinearProgressIndicator(
                    value: progress == 0 ? null : progress,
                    backgroundColor: colors.muted,
                    color: colors.primary,
                    minHeight: 4,
                  ),
                ),
              FButton(
                onPress: () => unawaited(onDismiss()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Icon(dismissIcon, size: 16),
                    Text(dismissLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader({
    required this.prayer,
    required this.title,
    required this.timeLabel,
    required this.colors,
    required this.theme,
    required this.showCloseButton,
    required this.onDismiss,
  });

  final Prayer prayer;
  final String title;
  final String timeLabel;
  final FColors colors;
  final FThemeData theme;
  final bool showCloseButton;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PrayerIcon(
          prayer: prayer,
          isActive: true,
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                timeLabel,
                style: theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (showCloseButton)
          FButton.icon(
            variant: .secondary,
            onPress: () => unawaited(onDismiss()),
            child: const Icon(FLucideIcons.x, size: 18),
          ),
      ],
    );
  }
}
