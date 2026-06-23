import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
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
    final kind = alert.kind!;
    final prayer = alert.prayer!;
    final scheduledTime = alert.scheduledTime!;
    final playsSound = alert.playsSound;

    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final prayerName = prayer.getLocaleName(l10n);
    final timeLabel = DateFormat.Hm().format(scheduledTime);
    final title = switch (kind) {
      PrayerAlertKind.adhan => l10n.adhanAlertTitle(prayerName),
      PrayerAlertKind.iqamah => l10n.iqamahAlertTitle(prayerName),
      PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
    };
    final playbackState = ref.watch(audioPlayerControllerProvider);
    final showPlayback =
        playsSound && playbackState is! PlaybackIdle && playbackState is! PlaybackError;
    final position = useStream(
      ref.watch(tawaqAudioServiceProvider).positionStream,
    );
    final duration = useStream(
      ref.watch(tawaqAudioServiceProvider).durationStream,
    );
    final maxMs = duration.data?.inMilliseconds ?? 1;
    final progress = maxMs <= 0
        ? 0.0
        : ((position.data?.inMilliseconds ?? 0) / maxMs).clamp(0.0, 1.0);

    Future<void> dismiss() =>
        ref.read(prayerAlertDispatcherProvider.notifier).dismiss();

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
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: theme.radii.lg,
          border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: colors.barrier.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: theme.radii.lg,
          child: Column(
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
                child: Row(
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
                        onPress: () => unawaited(dismiss()),
                        child: const Icon(FLucideIcons.x, size: 18),
                      ),
                  ],
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
                      onPress: () => unawaited(dismiss()),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: AppSpacing.sm,
                        children: [
                          Icon(
                            showPlayback
                                ? FLucideIcons.square
                                : FLucideIcons.bellOff,
                            size: 16,
                          ),
                          Text(showPlayback ? l10n.adhanStop : l10n.prayerAlertDismiss),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
