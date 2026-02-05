import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:intl/intl.dart';

/// Card showing Sunnah times (Sunrise, Midnight, Last Third)
class SunnahTimesCard extends ConsumerWidget {
  /// Creates a [SunnahTimesCard].
  const SunnahTimesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final prayerTimesState = ref.watch(currentPrayerTimesProvider());
    final formatter = ref.watch(timeFormatterProvider);

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.sunnahTimes.toUpperCase(),
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SunnahTimesList(
            prayerTimes: prayerTimesState,
            formatter: formatter,
          ),
        ],
      ),
    );
  }
}

class _SunnahTimesList extends StatelessWidget {
  const _SunnahTimesList({
    required this.prayerTimes,
    required this.formatter,
  });

  final PrayerTimes prayerTimes;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    const sunnahPrayers = [
      Prayer.sunrise,
      Prayer.fajrAfter, // Midnight
      Prayer.ishaBefore, // Last Third
    ];

    return Column(
      children: sunnahPrayers.map((prayer) {
        final time = prayerTimes.timeForPrayer(prayer);
        // Correct ishaBefore if it refers to previous day logic
        var displayTime = time;
        if (prayer == Prayer.ishaBefore &&
            time.isBefore(DateTime.now().subtract(const Duration(hours: 12)))) {
          // If calculated for yesterday (std behavior), show for tonight (add 1 day)
          // Logic similar to SchedulePrayerRow fix, though naive without verifying 'now'
          displayTime = time.add(const Duration(days: 1));
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: FTheme.of(context).colors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  prayer.icon,
                  size: 20.sp,
                  color: FTheme.of(context).colors.foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  prayer.getLocaleName(context.l10n),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                formatter.format(displayTime),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
