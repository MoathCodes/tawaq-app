import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PrayerAnalyticsCard extends StatefulWidget {
  final PrayerAnalytics prayerAnalytics;
  const PrayerAnalyticsCard({
    super.key,
    required this.prayerAnalytics,
  });

  @override
  State<PrayerAnalyticsCard> createState() => _PrayerAnalyticsCardState();
}

class _PrayerAnalyticsCardState extends State<PrayerAnalyticsCard> {
  PrayerAnalyticsPeriod _period = PrayerAnalyticsPeriod.weekly;

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
                  index: _period.index,
                  onChanged: (value) {
                    setState(() {
                      _period = PrayerAnalyticsPeriod.values[value];
                    });
                    // New Line
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
                  Text("${widget.prayerAnalytics.completionPercentage * 100}%",
                          textAlign: TextAlign.center)
                      .x4Large
                      .bold,
                  Text(
                          switch (_period) {
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
                    progress: widget.prayerAnalytics.completionPercentage,
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 6,
              runSpacing: 6,
              children: [
                MiniCard(
                    label: context.l10n.currentStreak,
                    child: Text(context.l10n
                        .streakInDays(widget.prayerAnalytics.currentStreak))),
                MiniCard(
                    label: context.l10n.bestStreak,
                    child: Text(context.l10n
                        .streakInDays(widget.prayerAnalytics.bestStreak))),
                MiniCard(
                    label: context.l10n.jamaahRate,
                    child: Text(
                        "${widget.prayerAnalytics.jamaahPercentage * 100}%")),
                MiniCard(
                    label: context.l10n.onTimeRate,
                    child: Text(
                        "${widget.prayerAnalytics.onTimePercentage * 100}%")),
                MiniCard(
                    label: context.l10n.lateRate,
                    child: Text(
                        "${widget.prayerAnalytics.latePercentage * 100}%")),
                MiniCard(
                    label: context.l10n.missedRate,
                    child: Text(
                        "${widget.prayerAnalytics.missedPercentage * 100}%")),
                // MiniCard(label: "Best", child: Text("5 prayers")),
                // MiniCard(label: "Perfect", child: Text("5 prayers")),
              ],
            ),
            // const Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     PrimaryBadge(
            //       style: ButtonStyle.primary(
            //         size: ButtonSize.small,
            //         density: ButtonDensity.normal,
            //       ),
            //       leading: Icon(BootstrapIcons.stack),
            //       child: Text("+5% improvement"),
            //     ),
            //     PrimaryBadge(
            //       style: ButtonStyle.secondary(
            //         size: ButtonSize.small,
            //         density: ButtonDensity.normal,
            //       ),
            //       leading: Icon(BootstrapIcons.stack),
            //       child: Text("+10% Jamaah Rate"),
            //     ),
            //     PrimaryBadge(
            //       style: ButtonStyle.secondary(
            //         size: ButtonSize.small,
            //         density: ButtonDensity.normal,
            //       ),
            //       leading: Icon(BootstrapIcons.stack),
            //       child: Text("+10% Jamaah Rate"),
            //     ),
            //   ],
            // ),
          ],
        ));
  }

  @override
  void initState() {
    super.initState();
    _period = widget.prayerAnalytics.period;
  }
}
