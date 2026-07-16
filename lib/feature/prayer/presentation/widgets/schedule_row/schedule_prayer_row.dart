import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_icon.dart'
    show PrayerIcon;
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_alert_picker.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_status_chips.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Relative subtitle for a schedule row (e.g. "in 2 hours", "30 mins ago").
String? _computePrayerRelativeTime({
  required DateTime prayerTime,
  required DateTime now,
  required bool isCurrentPrayer,
  required CompletionStatus status,
  required AppLocalizations l10n,
}) {
  if (isCurrentPrayer) {
    return l10n.currentPrayer;
  }

  final isFuture = prayerTime.isAfter(now);
  final difference = now.difference(prayerTime).abs();
  final hours = difference.inHours;
  final totalMinutes = difference.inMinutes;

  if (status != CompletionStatus.none) {
    if (isFuture) {
      return l10n.completed;
    }
    final timeAgo = hours > 0
        ? l10n.adhanHoursAgo(hours)
        : l10n.adhanMinsAgo(totalMinutes);
    return '${l10n.completed} - $timeAgo';
  }

  if (isFuture) {
    return hours > 0
        ? l10n.adhanHoursLeft(hours)
        : l10n.adhanMinsLeft(totalMinutes);
  } else {
    return hours > 0
        ? l10n.adhanHoursAgo(hours)
        : l10n.adhanMinsAgo(totalMinutes);
  }
}

/// A single prayer row in the schedule list with inline status logging.
class SchedulePrayerRow extends ConsumerWidget {
  /// Creates a [SchedulePrayerRow] instance.
  const SchedulePrayerRow({
    required this.row,
    required this.isToday,
    required this.currentPrayer,
    super.key,
  });

  /// The prayer schedule row data.
  final PrayerScheduleRow row;

  /// Whether the schedule list is showing today's calendar day.
  final bool isToday;

  /// Current obligatory prayer when [isToday]; otherwise null.
  final Prayer? currentPrayer;

  static const _animDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final completionDay = row.completionDate ??
        DateTime(
          row.prayerTime.year,
          row.prayerTime.month,
          row.prayerTime.day,
        );
    final completionStatus = ref.watch(
      completionStatusProvider(row.prayer, completionDay),
    );
    final isActive =
        currentPrayer != null &&
        isScheduleRowCurrent(
          rowPrayer: row.prayer,
          currentPrayer: currentPrayer!,
        );

    final icon = PrayerIcon(
      prayer: row.prayer,
      isActive: isActive,
      colors: colors,
      status: completionStatus,
    );
    final statusChips = ScheduleStatusChips(
      prayer: row.prayer,
      completionDay: completionDay,
      prayerTime: row.prayerTime,
    );
    final timeRail = _TimeRail(row: row);

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
          final isWide = isContainerAtLeast(
            context,
            constraints,
            FBreakpoint.md,
          );

          if (isWide) {
            return _WideScheduleRow(
              icon: icon,
              row: row,
              isActive: isActive,
              completionStatus: completionStatus,
              isToday: isToday,
              statusChips: statusChips,
              timeRail: timeRail,
            );
          }

          return _NarrowScheduleRow(
            icon: icon,
            row: row,
            isActive: isActive,
            completionStatus: completionStatus,
            isToday: isToday,
            statusChips: statusChips,
            timeRail: timeRail,
            footerInlineWithTrailing: row.formattedIqamahTime == null,
          );
        },
      ),
    );
  }
}

class _WideScheduleRow extends StatelessWidget {
  const _WideScheduleRow({
    required this.icon,
    required this.row,
    required this.isActive,
    required this.completionStatus,
    required this.isToday,
    required this.statusChips,
    required this.timeRail,
  });

  final Widget icon;
  final PrayerScheduleRow row;
  final bool isActive;
  final CompletionStatus completionStatus;
  final bool isToday;
  final Widget statusChips;
  final Widget timeRail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _IdentityColumn(
            row: row,
            isActive: isActive,
            showStatus: true,
            completionStatus: completionStatus,
            isToday: isToday,
            statusChips: statusChips,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        timeRail,
      ],
    );
  }
}

class _NarrowScheduleRow extends StatelessWidget {
  const _NarrowScheduleRow({
    required this.icon,
    required this.row,
    required this.isActive,
    required this.completionStatus,
    required this.isToday,
    required this.statusChips,
    required this.timeRail,
    required this.footerInlineWithTrailing,
  });

  final Widget icon;
  final PrayerScheduleRow row;
  final bool isActive;
  final CompletionStatus completionStatus;
  final bool isToday;
  final Widget statusChips;
  final Widget timeRail;
  final bool footerInlineWithTrailing;

  @override
  Widget build(BuildContext context) {
    if (footerInlineWithTrailing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _IdentityColumn(
                  row: row,
                  isActive: isActive,
                  showStatus: false,
                  completionStatus: completionStatus,
                  isToday: isToday,
                  statusChips: statusChips,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: statusChips),
              timeRail,
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _IdentityColumn(
                row: row,
                isActive: isActive,
                showStatus: false,
                completionStatus: completionStatus,
                isToday: isToday,
                statusChips: statusChips,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        statusChips,
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: timeRail,
        ),
      ],
    );
  }
}

class _IdentityColumn extends StatelessWidget {
  const _IdentityColumn({
    required this.row,
    required this.isActive,
    required this.showStatus,
    required this.completionStatus,
    required this.isToday,
    required this.statusChips,
  });

  final PrayerScheduleRow row;
  final bool isActive;
  final bool showStatus;
  final CompletionStatus completionStatus;
  final bool isToday;
  final Widget statusChips;

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
          style: theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        _RelativeTimeSubtitle(
          prayerTime: row.prayerTime,
          status: completionStatus,
          isCurrentPrayer: isActive,
          isToday: isToday,
        ),
        if (showStatus) ...[
          const SizedBox(height: AppSpacing.sm),
          statusChips,
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
    required this.isToday,
  });

  final DateTime prayerTime;
  final CompletionStatus status;
  final bool isCurrentPrayer;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    ref.watch(currentMinuteBucketProvider);
    final clockNow = ref.read(prayerDayProvider).value?.now;
    if (isToday && clockNow == null) {
      return const SizedBox.shrink();
    }
    final now = isToday
        ? clockNow!
        : DateTime(prayerTime.year, prayerTime.month, prayerTime.day);

    final subtitle = _computePrayerRelativeTime(
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
      style: theme.typography.body.sm.copyWith(
        color: isCurrentPrayer ? colors.primary : colors.mutedForeground,
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
              style: theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                height: 1.1,
              ),
            ),
            Text(
              time,
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.2,
              ),
            ),
          ],
        ),
        if (isDesktopPlatform) ...[
          const SizedBox(width: AppSpacing.xs),
          ScheduleAlertPicker.obligatory(
            mode: mode,
            eventLabel: eventLabel,
            alertKind: kind,
            hasSettings: settings != null,
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
