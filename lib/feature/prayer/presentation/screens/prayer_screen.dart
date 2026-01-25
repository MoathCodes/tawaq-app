import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hasanat/core/widgets/animation_entry.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_hero_header.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_schedule_list.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/prayer_stats_sidebar.dart';
import 'package:hasanat/theme/theme.dart';

/// Screen that displays prayer times with hero header, schedule, and stats.
class PrayerScreen extends ConsumerWidget {
  /// Creates a [PrayerScreen] instance.
  const PrayerScreen({super.key});

  static const double _breakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (context.breakpoint.isSmallerThan(.md)) {
                return const _VerticalLayout();
              } else {
                return const _HorizontalLayout();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Wide layout: Hero on top, schedule list (60%) + sidebar (40%) below.
class _HorizontalLayout extends StatelessWidget {
  const _HorizontalLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero header - full width
        AnimationEntry(
          delay: 100.ms,
          child: const PrayerHeroHeader(key: ValueKey('prayer_hero_header')),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Two-column layout: schedule + sidebar
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Schedule list - 60%
              Expanded(
                flex: 6,
                child: AnimationEntry(
                  delay: 250.ms,
                  child: const PrayerScheduleList(
                    key: ValueKey('prayer_schedule_list'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Stats sidebar - 40%
              Expanded(
                flex: 4,
                child: AnimationEntry(
                  delay: 400.ms,
                  child: const PrayerStatsSidebar(
                    key: ValueKey('prayer_stats_sidebar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Narrow stacked layout for smaller screens.
class _VerticalLayout extends StatelessWidget {
  const _VerticalLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero header
        AnimationEntry(
          delay: 100.ms,
          child: const PrayerHeroHeader(key: ValueKey('prayer_hero_header')),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Schedule list
        AnimationEntry(
          delay: 250.ms,
          child: const PrayerScheduleList(
            key: ValueKey('prayer_schedule_list'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Stats sidebar
        AnimationEntry(
          delay: 400.ms,
          child: const PrayerStatsSidebar(
            key: ValueKey('prayer_stats_sidebar'),
          ),
        ),
      ],
    );
  }
}
