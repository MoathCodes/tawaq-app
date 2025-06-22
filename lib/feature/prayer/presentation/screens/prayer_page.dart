import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hasanat/core/utils/smooth_scroll.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/current_prayer_card.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_analytics_card.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_table.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_tracker_cards.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({super.key});

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage> {
  static const double _mainAxisExtent = 350.0;
  static const double _trackerCardsMainAxisExtent = 541.5;

  static const _widgets = [
    CurrentPrayerCard(key: ValueKey('current_prayer_card')),
    PrayerAnalyticsCard(
      key: ValueKey('prayer_analytics_card'),
      prayerAnalytics: PrayerAnalytics(
        period: PrayerAnalyticsPeriod.weekly,
        completionPercentage: 0.85,
        currentStreak: 10,
        bestStreak: 15,
        jamaahPercentage: 0.85,
        onTimePercentage: 0.85,
        missedPercentage: 0.15,
        latePercentage: 0.0,
      ),
    ),
    PrayerTable(key: ValueKey('prayer_table')),
    PrayerTrackerCards(
      key: ValueKey('prayer_tracker_cards'),
      // expanded: false,
    ),
  ];

  // final bool _expandTrackerCards = false;

  // final bool _tableLayout = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SingleChildScrollView(
          clipBehavior: Clip.antiAlias,
          physics: const SmoothDesktopScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine if we should stack or place side by side
              bool shouldStack = constraints.maxWidth < 900;

              if (shouldStack) {
                // Stack vertically on small screens
                return Column(
                  spacing: 12,
                  children: _widgets
                      .map(
                        (widget) => ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _mainAxisExtent,
                          ),
                          child: widget,
                        ),
                      )
                      .toList(),
                );
              } else {
                // Use StaggeredGrid on larger screens
                return StaggeredGrid.count(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    StaggeredGridTile.extent(
                      crossAxisCellCount: 3,
                      mainAxisExtent: _mainAxisExtent,
                      child: _widgets[0], // CurrentPrayerCard
                    ),
                    StaggeredGridTile.extent(
                      crossAxisCellCount: 4,
                      mainAxisExtent: _mainAxisExtent,
                      child: _widgets[1], // PrayerAnalyticsCard
                    ),
                    StaggeredGridTile.extent(
                      crossAxisCellCount: 3,
                      mainAxisExtent: _trackerCardsMainAxisExtent,
                      child: _widgets[2], // PrayerTable
                    ),
                    StaggeredGridTile.fit(
                      crossAxisCellCount: 4,
                      // mainAxisExtent: _trackerCardsMainAxisExtent,
                      child: _widgets[3], // PrayerTrackerCards
                    ),
                  ],
                );
              }
            },
          )),
    );
  }
}
