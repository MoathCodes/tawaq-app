import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PrayerAnalyticsCard extends StatefulWidget {
  const PrayerAnalyticsCard({
    super.key,
  });

  @override
  State<PrayerAnalyticsCard> createState() => _PrayerAnalyticsCardState();
}

enum PrayerAnalyticsPeriod {
  // daily,
  weekly,
  monthly,
  yearly,
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
                const Text("Player Analytics").small,
                Tabs(
                  index: _period.index,
                  onChanged: (value) {
                    setState(() {
                      _period = PrayerAnalyticsPeriod.values[value];
                    });
                    // New Line
                  },
                  children: const [
                    TabItem(
                        // value: PrayerAnalyticsPeriod.daily,
                        child: Text("Weekly")),
                    TabItem(
                        // value: PrayerAnalyticsPeriod.weekly,
                        child: Text("Monthly")),
                    TabItem(
                        // value: PrayerAnalyticsPeriod.monthly,
                        child: Text("Yearly")),
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
                  const Text("85%", textAlign: TextAlign.center).x4Large.bold,
                  const Text("On time prayers (last 30 days)",
                          textAlign: TextAlign.center)
                      .muted,
                  const Progress(
                    progress: 0.85,
                  ),
                ],
              ),
            ),
            const Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 6,
              runSpacing: 6,
              children: [
                MiniCard(label: "Jamaah Streak", child: Text("75%")),
                MiniCard(label: "Prayer Streak", child: Text("30 days")),
                MiniCard(label: "Jamaah", child: Text("5 prayers")),
                MiniCard(label: "On Time", child: Text("5 prayers")),
                MiniCard(label: "Late", child: Text("5 prayers")),
                MiniCard(label: "Missed", child: Text("5 prayers")),
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
}
