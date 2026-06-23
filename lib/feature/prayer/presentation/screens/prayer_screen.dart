import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_effective_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_section.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_header.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_location_setup_alert.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_schedule_list.dart';
import 'package:tawaq/theme/theme.dart';

class _LocationSetupScreen extends StatelessWidget {
  const _LocationSetupScreen();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.all(AppSpacing.md);
        final minHeight = constraints.maxHeight - padding.vertical;

        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: const Center(
              child: PrayerLocationSetupAlert(),
            ),
          ),
        );
      },
    );
  }
}

/// Screen that displays prayer times with hero header, schedule, and stats.
class PrayerScreen extends ConsumerWidget {
  /// Creates a [PrayerScreen] instance.
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(prayerLocationSetupNeededProvider)) {
      return const _LocationSetupScreen();
    }

    final maxContentWidth = responsiveValue<double>(
      context,
      belowSm: double.infinity,
      lg: 1200,
      xl2: 1400,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useSplit = canUseHorizontalSplit(
                containerWidth: constraints.maxWidth,
                sideMin: kStudyPanelMinExtent,
                mainMin: kMainPaneMinExtent,
                spacer: AppSpacing.lg,
              );

              if (useSplit) {
                return const _HorizontalLayout();
              }
              return const _VerticalLayout();
            },
          ),
        ),
      ),
    );
  }
}

class _HorizontalLayout extends StatelessWidget {
  const _HorizontalLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            spacing: AppSpacing.lg,
            children: [
              AnimationEntry(
                delay: 100.ms,
                animateOnce: true,
                child: const PrayerHeroHeader(
                  key: ValueKey('prayer_hero_header'),
                ),
              ),
              AnimationEntry(
                delay: 250.ms,
                animateOnce: true,
                child: const PrayerScheduleList(
                  key: ValueKey('prayer_schedule_list'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 4,
          child: AnimationEntry(
            delay: 400.ms,
            animateOnce: true,
            child: const AnalysisSection(
              key: ValueKey('prayer_analysis_section'),
            ),
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
      spacing: AppSpacing.lg,
      children: [
        AnimationEntry(
          delay: 100.ms,
          animateOnce: true,
          child: const PrayerHeroHeader(key: ValueKey('prayer_hero_header')),
        ),
        AnimationEntry(
          delay: 250.ms,
          animateOnce: true,
          child: const PrayerScheduleList(
            key: ValueKey('prayer_schedule_list'),
          ),
        ),
        AnimationEntry(
          delay: 400.ms,
          animateOnce: true,
          child: const AnalysisSection(
            key: ValueKey('prayer_analysis_section'),
          ),
        ),
      ],
    );
  }
}
