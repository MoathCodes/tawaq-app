import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_alert_picker.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Compact grouped strip for Sunnah-related times above the daily schedule.
class SunnahTimesCard extends ConsumerWidget {
  /// Creates a [SunnahTimesCard].
  const SunnahTimesCard({super.key});

  static const List<Prayer> _sunnahPrayers = [
    Prayer.sunrise,
    Prayer.fajrAfter,
    Prayer.ishaBefore,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;
    final prayerTimes = ref.watch(currentPrayerTimesProvider());
    final day = ref.watch(prayerDayProvider).value;
    final now = day?.now ?? ref.watch(currentLocationTimeProvider);
    final formatter = ref.watch(timeFormatterProvider);

    final entries = _sunnahPrayers
        .map((prayer) {
          final time = prayerTimes.timeForPrayer(prayer);
          final timeline = day?.timeline;
          final fajrToday = timeline?.fajrToday;
          final displayTime = switch (prayer) {
            Prayer.ishaBefore
                when timeline != null &&
                    fajrToday != null &&
                    now != null &&
                    now.isBefore(fajrToday) =>
              timeline.lastThirdToday,
            Prayer.fajrAfter
                when timeline != null &&
                    fajrToday != null &&
                    now != null &&
                    now.isBefore(fajrToday) =>
              timeline.middleOfNightToday,
            _ => time,
          };

          return (
            prayer: prayer,
            timeLabel: formatter.format(displayTime),
          );
        })
        .toList(growable: false);

    final gradientColors = entries
        .map((entry) => _sunnahAccent(colors, entry.prayer))
        .toList(growable: false);

    return Semantics(
      container: true,
      label: l10n.sunnahTimes,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: theme.radii.md,
          border: Border.all(color: colors.border.withValues(alpha: 0.75)),
        ),
        child: ClipRRect(
          borderRadius: theme.radii.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                ),
                child: const SizedBox(height: 2),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      FLucideIcons.moonStar,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.sunnahTimes,
                      style: theme.typography.xs.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.mutedForeground,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: colors.border.withValues(alpha: 0.65),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useColumns =
                        constraints.maxWidth >= context.theme.breakpoints.sm;

                    if (useColumns) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < entries.length; i++) ...[
                              if (i > 0)
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  color: colors.border.withValues(alpha: 0.65),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: _SunnahStripCell(
                                    prayer: entries[i].prayer,
                                    timeLabel: entries[i].timeLabel,
                                    colors: colors,
                                    theme: theme,
                                    layout: _SunnahCellLayout.compact,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < entries.length; i++) ...[
                          if (i > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: colors.border.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: _SunnahStripCell(
                              prayer: entries[i].prayer,
                              timeLabel: entries[i].timeLabel,
                              colors: colors,
                              theme: theme,
                              layout: _SunnahCellLayout.row,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SunnahCellLayout { row, compact }

class _SunnahStripCell extends ConsumerWidget {
  const _SunnahStripCell({
    required this.prayer,
    required this.timeLabel,
    required this.colors,
    required this.theme,
    required this.layout,
  });

  final Prayer prayer;
  final String timeLabel;
  final FColors colors;
  final FThemeData theme;
  final _SunnahCellLayout layout;

  static const List<ScheduleAlertMode> _modes = [
    ScheduleAlertMode.off,
    ScheduleAlertMode.notifyOnly,
  ];

  static const Set<ScheduleAlertMode> _interactiveModes = {
    ScheduleAlertMode.off,
    ScheduleAlertMode.notifyOnly,
  };

  static const _iconSize = 28.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(adhanSettingsProvider).value;
    final prayerName = prayer.getLocaleName(l10n);
    final accent = _sunnahAccent(colors, prayer);
    final mode = settings == null
        ? ScheduleAlertMode.off
        : adhanSettingsModeFor(
            settings,
            PrayerAlertKind.sunnah,
            prayer,
          );

    final icon = ExcludeSemantics(
      child: Container(
        width: _iconSize,
        height: _iconSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Icon(
          prayer.icon,
          size: 14,
          color: accent,
        ),
      ),
    );

    final name = Text(
      prayerName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.xs.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );

    final time = Text(
      timeLabel,
      maxLines: 1,
      style: theme.typography.sm.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.1,
      ),
    );

    final alert = isDesktopPlatform
        ? ScheduleAlertPicker(
            mode: mode,
            modes: _modes,
            interactiveModes: settings == null ? const {} : _interactiveModes,
            eventLabel: l10n.scheduleAlertEventSunnah(prayerName),
            alertKind: PrayerAlertKind.sunnah,
            onChanged: settings == null
                ? null
                : (next) => ref
                      .read(adhanSettingsProvider.notifier)
                      .setAlertMode(PrayerAlertKind.sunnah, prayer, next),
          )
        : null;

    final content = switch (layout) {
      _SunnahCellLayout.row => Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: name),
          const SizedBox(width: AppSpacing.md),
          time,
          ?alert,
        ],
      ),
      _SunnahCellLayout.compact => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                name,
                const SizedBox(height: AppSpacing.xs),
                time,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ?alert,
        ],
      ),
    };

    return Semantics(
      label: PrayerSemantics.sunnahTimeRow(
        prayerName: prayerName,
        time: timeLabel,
      ),
      excludeSemantics: true,
      child: content,
    );
  }
}

Color _sunnahAccent(FColors colors, Prayer prayer) {
  return switch (prayer) {
    Prayer.sunrise => Color.lerp(
      colors.primary,
      colors.mutedForeground,
      0.2,
    )!,
    Prayer.fajrAfter => Color.lerp(
      colors.primary,
      colors.mutedForeground,
      0.45,
    )!,
    Prayer.ishaBefore => Color.lerp(
      colors.primary,
      colors.mutedForeground,
      0.65,
    )!,
    _ => colors.primary,
  };
}
