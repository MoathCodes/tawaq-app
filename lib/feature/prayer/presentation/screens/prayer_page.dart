import 'package:dyn_mouse_scroll/smooth_scroll_multiplatform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/current_prayer_card.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_analytics_card.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_table.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_tracker_cards.dart';

class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({super.key});

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage> {
  static const _widgets = [
    CurrentPrayerCard(key: ValueKey('current_prayer_card')),
    PrayerAnalyticsCard(key: ValueKey('prayer_analytics_card')),
    PrayerTable(key: ValueKey('prayer_table')),
    PrayerTrackerWidget(
      key: ValueKey('prayer_analytics_card'),
    ),
  ];
  final double _mainAxisExtent = 350.0.h;

  final double _trackerCardsMainAxisExtent = 541.5.h;

  // final bool _expandTrackerCards = false;

  // final bool _tableLayout = false;
  @override
  Widget build(BuildContext context) {
    return DynMouseScroll(
      builder: (context, controller, physics) => SingleChildScrollView(
        controller: controller,
        physics: physics,
        child: LayoutBuilder(builder: (context, constraints) {
          // Determine if we should stack or place side by side
          bool shouldStack = constraints.maxWidth.w < 900.w;

          if (shouldStack) {
            // Stack vertically on small screens
            return Column(
              spacing: 12,
              children: _widgets
                  .map(
                    (widget) => ConstrainedBox(
                      constraints: BoxConstraints(
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
        }),
      ),
    );
  }
}
