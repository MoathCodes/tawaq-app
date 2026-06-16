import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/use_cases/compute_prayer_relative_time.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/schedule_selected_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_icon.dart'
    show PrayerIcon;
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_alert_picker.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// A single prayer row in the schedule list with inline status logging.
class SchedulePrayerRow extends ConsumerWidget {
  /// Creates a [SchedulePrayerRow] instance.
  const SchedulePrayerRow({
    required this.row,
    super.key,
  });

  /// The prayer schedule row data.
  final PrayerScheduleRow row;

  static const _animDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final selectedDate = ref.watch(scheduleSelectedDateProvider);
    final now = ref.watch(currentLocationTimeProvider);
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final currentPrayer = isToday
        ? ref.watch(scheduleCurrentPrayerProvider)
        : null;
    final isActive =
        currentPrayer != null &&
        isScheduleRowCurrent(
          rowPrayer: row.prayer,
          currentPrayer: currentPrayer,
        );

    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: theme.radii.md,
        border: Border.all(
          color: isActive
              ? colors.primary.withValues(alpha: 0.5)
              : colors.border.withValues(alpha: 0.75),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= theme.breakpoints.sm;

          if (isWide) {
            return Row(
              children: [
                PrayerIcon(
                  prayer: row.prayer,
                  isActive: isActive,
                  colors: colors,
                  status: row.completionStatus,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _IdentityColumn(
                    row: row,
                    isActive: isActive,
                    showStatus: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _TimeRail(row: row),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrayerIcon(
                    prayer: row.prayer,
                    isActive: isActive,
                    colors: colors,
                    status: row.completionStatus,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _IdentityColumn(
                      row: row,
                      isActive: isActive,
                      showStatus: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _StatusSelector(row: row)),
                  _TimeRail(row: row),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityColumn extends StatelessWidget {
  const _IdentityColumn({
    required this.row,
    required this.isActive,
    required this.showStatus,
  });

  final PrayerScheduleRow row;
  final bool isActive;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          row.prayer.getLocaleName(l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        _RelativeTimeSubtitle(
          prayerTime: row.prayerTime,
          status: row.completionStatus,
          isCurrentPrayer: isActive,
        ),
        if (showStatus) ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusSelector(row: row),
        ],
      ],
    );
  }
}

class _RelativeTimeSubtitle extends ConsumerWidget {
  const _RelativeTimeSubtitle({
    required this.prayerTime,
    required this.status,
    required this.isCurrentPrayer,
  });

  final DateTime prayerTime;
  final CompletionStatus status;
  final bool isCurrentPrayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    final selectedDate = ref.watch(scheduleSelectedDateProvider);
    final clockNow = ref.watch(currentLocationTimeProvider);
    final isToday =
        selectedDate.year == clockNow.year &&
        selectedDate.month == clockNow.month &&
        selectedDate.day == clockNow.day;
    final now = isToday
        ? clockNow
        : DateTime(prayerTime.year, prayerTime.month, prayerTime.day);

    final subtitle = computePrayerRelativeTime(
      prayerTime: prayerTime,
      now: now,
      isCurrentPrayer: isCurrentPrayer,
      status: status,
      l10n: l10n,
    );

    if (subtitle == null) {
      return const SizedBox.shrink();
    }

    return Text(
      subtitle,
      style: theme.typography.sm.copyWith(
        color: isCurrentPrayer ? colors.primary : colors.mutedForeground,
      ),
    );
  }
}

class _StatusSelector extends ConsumerWidget {
  const _StatusSelector({required this.row});

  final PrayerScheduleRow row;

  static const _buttonSize = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: CompletionStatus.values
          .where((status) => status != CompletionStatus.none)
          .map(
            (status) => _StatusButton(
              row: row,
              status: status,
              isSelected: status == row.completionStatus,
            ),
          )
          .toList(),
    );
  }
}

class _StatusButton extends ConsumerWidget {
  const _StatusButton({
    required this.row,
    required this.status,
    required this.isSelected,
  });

  final PrayerScheduleRow row;
  final CompletionStatus status;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final now = ref.watch(currentLocationTimeProvider);
    final enable = row.prayerTime.isBefore(now);
    final completionDay =
        row.completionDate ?? DateTime(now.year, now.month, now.day);
    final accent = status.getBadgeColor(colors);
    final icon = status.getIcon();
    final l10n = context.l10n;

    return MouseClick(
      disabled: !enable,
      onClick: enable
          ? () => unawaited(
              ref
                  .read(prayerCompletionActionsProvider.notifier)
                  .setPrayerStatus(
                    prayer: row.prayer,
                    completionDay: completionDay,
                    status: status,
                  ),
            )
          : null,
      semanticsLabel: PrayerSemantics.statusOption(
        l10n: l10n,
        status: status,
        enabled: enable,
      ),
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enable ? 1 : 0.45,
          child: AnimatedContainer(
            duration: theme.durations.fast,
            width: _StatusSelector._buttonSize,
            height: _StatusSelector._buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? accent
                  : colors.secondary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accent : colors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isSelected ? colors.background : colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeRail extends StatelessWidget {
  const _TimeRail({required this.row});

  final PrayerScheduleRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (row.formattedIqamahTime != null) ...[
          _ObligatoryAlertTimeSlot(
            prayer: row.prayer,
            time: row.formattedIqamahTime!,
            kind: PrayerAlertKind.iqamah,
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: colors.border.withValues(alpha: 0.65),
          ),
        ],
        _ObligatoryAlertTimeSlot(
          prayer: row.prayer,
          time: row.formattedAdhanTime,
          kind: PrayerAlertKind.adhan,
        ),
      ],
    );
  }
}

class _ObligatoryAlertTimeSlot extends ConsumerWidget {
  const _ObligatoryAlertTimeSlot({
    required this.prayer,
    required this.time,
    required this.kind,
  });

  final Prayer prayer;
  final String time;
  final PrayerAlertKind kind;

  static const List<ScheduleAlertMode> _modes = [
    ScheduleAlertMode.off,
    ScheduleAlertMode.sound,
    ScheduleAlertMode.notifyOnly,
  ];

  static const Set<ScheduleAlertMode> _interactiveModes = {
    ScheduleAlertMode.off,
    ScheduleAlertMode.sound,
    ScheduleAlertMode.notifyOnly,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final settings = ref.watch(adhanSettingsProvider).value;
    final prayerName = prayer.getLocaleName(l10n);
    final mode = settings == null
        ? ScheduleAlertMode.off
        : adhanSettingsModeFor(
            settings,
            kind,
            prayer,
          );

    final (label, eventLabel) = switch (kind) {
      PrayerAlertKind.iqamah => (
        l10n.iqamah,
        l10n.scheduleAlertEventIqamah(prayerName),
      ),
      _ => (
        l10n.adhan,
        l10n.scheduleAlertEventAdhan(prayerName),
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.typography.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                height: 1.1,
              ),
            ),
            Text(
              time,
              style: theme.typography.sm.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.2,
              ),
            ),
          ],
        ),
        if (isDesktopPlatform) ...[
          const SizedBox(width: AppSpacing.xs),
          ScheduleAlertPicker(
            mode: mode,
            modes: _modes,
            interactiveModes: settings == null ? {} : _interactiveModes,
            eventLabel: eventLabel,
            alertKind: kind,
            onChanged: settings == null
                ? null
                : (next) => ref
                      .read(adhanSettingsProvider.notifier)
                      .setAlertMode(kind, prayer, next),
          ),
        ],
      ],
    );
  }
}
