import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_icon.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared presentation for live alerts and inert settings examples.
class PrayerAlertCard extends StatelessWidget {
  const new({
    required this.prayer,
    required this.title,
    required this.timeLabel,
    required this.onDismiss,
    this.compact = false,
    this.showCloseButton = false,
    this.showPlayback = false,
    this.progress = 0,
    super.key,
  });
  final Prayer prayer;
  final String title;
  final String timeLabel;
  final Future<void> Function() onDismiss;
  final bool compact;
  final bool showCloseButton;
  final bool showPlayback;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final dismissLabel = showPlayback
        ? l10n.adhanStop
        : l10n.prayerAlertDismiss;
    final dismissIcon = showPlayback
        ? FLucideIcons.square
        : FLucideIcons.bellOff;
    final cardDecoration = BoxDecoration(
      color: colors.card,
      borderRadius: compact ? null : theme.radii.lg,
      border: compact
          ? null
          : Border.all(color: colors.primary.withValues(alpha: 0.45)),
      boxShadow: compact
          ? null
          : [
              BoxShadow(
                color: colors.barrier.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );

    final content = compact
        ? _CompactAlertBody(
            prayer: prayer,
            title: title,
            timeLabel: timeLabel,
            colors: colors,
            theme: theme,
            showPlayback: showPlayback,
            progress: progress,
            dismissLabel: dismissLabel,
            onDismiss: onDismiss,
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
            onDismiss: onDismiss,
          );

    return DecoratedBox(
      decoration: cardDecoration,
      child: compact
          ? content
          : ClipRRect(
              borderRadius: theme.radii.lg,
              child: SizedBox(width: double.infinity, child: content),
            ),
    );
  }
}

/// Dense layout for the morphed compact alert window.
class _CompactAlertBody extends StatelessWidget {
  const new({
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
              PrayerIcon(prayer: prayer, isActive: true, colors: colors),
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
  const new({
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
                  children: [Icon(dismissIcon, size: 16), Text(dismissLabel)],
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
  const new({
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
        PrayerIcon(prayer: prayer, isActive: true, colors: colors),
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
