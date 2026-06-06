import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Card showing Sunnah times (Sunrise, Midnight, Last Third)
class SunnahTimesCard extends ConsumerWidget {
  /// Creates a [SunnahTimesCard].
  const SunnahTimesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.sunnahTimes.toUpperCase(),
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SunnahTimesList(),
      ],
    );
  }
}

class _SunnahTimesList extends ConsumerWidget {
  const _SunnahTimesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;
    final prayerTimes = ref.watch(currentPrayerTimesProvider());
    final day = ref.watch(prayerDayProvider).value;
    final now = day?.now ?? ref.watch(currentLocationTimeProvider);
    final formatter = ref.watch(timeFormatterProvider);

    const sunnahPrayers = [
      Prayer.sunrise,
      Prayer.fajrAfter, // Midnight
      Prayer.ishaBefore, // Last Third
    ];

    return Column(
      children: sunnahPrayers.map((prayer) {
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

        final prayerName = prayer.getLocaleName(l10n);
        final timeLabel = formatter.format(displayTime);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Semantics(
            label: PrayerSemantics.sunnahTimeRow(
              prayerName: prayerName,
              time: timeLabel,
            ),
            excludeSemantics: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      prayer.icon,
                      size: scaledSp(20, appScale),
                      color: colors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    prayerName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
