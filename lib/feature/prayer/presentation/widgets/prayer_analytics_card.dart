import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PrayerAnalyticsCard extends ConsumerStatefulWidget {
  const PrayerAnalyticsCard({
    super.key,
  });

  @override
  ConsumerState<PrayerAnalyticsCard> createState() =>
      _PrayerAnalyticsCardState();
}

class _MainWidget extends StatelessWidget {
  final PrayerAnalytics data;
  final void Function(PrayerAnalyticsPeriod) onPeriodChanged;
  const _MainWidget({
    required this.data,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: colorScheme.secondary,
      borderColor: colorScheme.secondaryForeground.withAlpha(45),
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.playerAnalytics).small,
              Tabs(
                index: data.period.index,
                onChanged: (value) {
                  onPeriodChanged(PrayerAnalyticsPeriod.values[value]);
                },
                children: [
                  TabItem(
                      // value: PrayerAnalyticsPeriod.daily,
                      child: Text(PrayerAnalyticsPeriod.weekly
                          .getLocaleName(context.l10n))),
                  TabItem(
                      // value: PrayerAnalyticsPeriod.weekly,
                      child: Text(PrayerAnalyticsPeriod.monthly
                          .getLocaleName(context.l10n))),
                  TabItem(
                      // value: PrayerAnalyticsPeriod.monthly,
                      child: Text(PrayerAnalyticsPeriod.yearly
                          .getLocaleName(context.l10n))),
                ],
              )
            ],
          ),
          OutlinedContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            // backgroundColor: colorScheme.secondary,
            borderColor: colorScheme.secondaryForeground.withAlpha(45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text("${data.completionPercentage * 100}%",
                        textAlign: TextAlign.center)
                    .x4Large
                    .bold,
                Text(
                        switch (data.period) {
                          PrayerAnalyticsPeriod.weekly =>
                            context.l10n.onTimePrayersLast7Days,
                          PrayerAnalyticsPeriod.monthly =>
                            context.l10n.onTimePrayersLast30Days,
                          PrayerAnalyticsPeriod.yearly =>
                            context.l10n.onTimePrayersLast365Days,
                        },
                        textAlign: TextAlign.center)
                    .muted,
                Progress(
                  progress: data.completionPercentage,
                ),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: [
              MiniCard(
                  label: context.l10n.currentStreak,
                  child: Text(context.l10n.streakInDays(data.currentStreak))),
              MiniCard(
                  label: context.l10n.bestStreak,
                  child: Text(context.l10n.streakInDays(data.bestStreak))),
              MiniCard(
                  label: context.l10n.jamaahRate,
                  child: Text("${data.jamaahPercentage * 100}%")),
              MiniCard(
                  label: context.l10n.onTimeRate,
                  child: Text("${data.onTimePercentage * 100}%")),
              MiniCard(
                  label: context.l10n.lateRate,
                  child: Text("${data.latePercentage * 100}%")),
              MiniCard(
                  label: context.l10n.missedRate,
                  child: Text("${data.missedPercentage * 100}%")),
              // MiniCard(label: "Best", child: Text("5 prayers")),
              // MiniCard(label: "Perfect", child: Text("5 prayers")),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerAnalyticsCardState extends ConsumerState<PrayerAnalyticsCard> {
  @override
  Widget build(BuildContext context) {
    final prayerAnalytics = ref.watch(prayerAnalyticsNotifierProvider);

    return prayerAnalytics.when(
      data: (data) => _MainWidget(
          data: data,
          onPeriodChanged: (period) {
            ref
                .read(prayerAnalyticsNotifierProvider.notifier)
                .changePeriod(period);
          }),
      loading: () => _MainWidget(
              data: PrayerAnalytics.empty(), onPeriodChanged: (period) {})
          .asSkeleton(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
