import 'package:dyn_mouse_scroll/smooth_scroll_multiplatform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hasanat/core/widgets/animation_entry.dart';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we should stack or place side by side
            bool shouldStack = constraints.maxWidth.w < 900.w;

            if (shouldStack) {
              return const _VerticalLayout();
            } else {
              return StaggeredGrid.count(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Important: animate the tile CHILDREN, not the tiles themselves,
                // otherwise StaggeredGrid can't read sizing and layout info.
                children: [
                  StaggeredGridTile.extent(
                    crossAxisCellCount: 3,
                    mainAxisExtent: _mainAxisExtent,
                    child: AnimationEntry(
                      delay: 100.ms,
                      child: const CurrentPrayerCard(
                        key: ValueKey('current_prayer_card'),
                      ),
                    ), // CurrentPrayerCard
                  ),
                  StaggeredGridTile.extent(
                    crossAxisCellCount: 4,
                    mainAxisExtent: _mainAxisExtent,
                    child: AnimationEntry(
                      delay: 250.ms,
                      child: const PrayerAnalyticsCard(
                        key: ValueKey('prayer_analytics_card'),
                      ),
                    ), // PrayerAnalyticsCard
                  ),
                  StaggeredGridTile.extent(
                    crossAxisCellCount: 3,
                    mainAxisExtent: _trackerCardsMainAxisExtent,
                    child: AnimationEntry(
                      delay: 400.ms,
                      child: const PrayerTable(key: ValueKey('prayer_table')),
                    ), // PrayerTable
                  ),
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 4,
                    // mainAxisExtent: _trackerCardsMainAxisExtent,
                    child: AnimationEntry(
                      delay: 550.ms,
                      child: const PrayerTrackerWidget(
                        key: ValueKey('prayer_tracker_widget'),
                      ),
                    ), // PrayerTrackerCards
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _VerticalLayout extends StatelessWidget {
  const _VerticalLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        // Staggered, per-item entry for better control and performance
        AnimationEntry(
          delay: 100.ms,
          child: const CurrentPrayerCard(key: ValueKey('current_prayer_card')),
        ),
        AnimationEntry(
          delay: 250.ms,
          child: const PrayerAnalyticsCard(
            key: ValueKey('prayer_analytics_card'),
          ),
        ),
        AnimationEntry(
          delay: 400.ms,
          child: const PrayerTable(key: ValueKey('prayer_table')),
        ),
        AnimationEntry(
          delay: 550.ms,
          child: const PrayerTrackerWidget(
            key: ValueKey('prayer_tracker_widget'),
          ),
        ),
      ],
    );
  }
}
