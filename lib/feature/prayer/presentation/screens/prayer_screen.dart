import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
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

/// Whether the prayer page uses a horizontal hero/schedule vs analysis split.
bool prayerPageUsesSplit(double containerWidth) {
  return canUseHorizontalSplit(
    containerWidth: containerWidth,
    sideMin: kStudyPanelMinExtent,
    mainMin: kMainPaneMinExtent,
    spacer: AppSpacing.lg,
  );
}

/// Width available to the analysis column for the given page layout.
double prayerAnalysisColumnWidth({
  required double containerWidth,
  required bool pageSplit,
}) {
  if (!pageSplit) return containerWidth;
  return (containerWidth - AppSpacing.lg) * 4 / 10;
}

/// Whether daily and trend analysis cards render side-by-side.
bool prayerAnalysisCardsSideBySide(
  BuildContext context,
  double analysisWidth,
) {
  final lg = context.theme.breakpoints.lg;
  return analysisWidth >= 2 * kMainPaneMinExtent || analysisWidth >= lg;
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
              final pageSplit = prayerPageUsesSplit(constraints.maxWidth);
              final analysisWidth = prayerAnalysisColumnWidth(
                containerWidth: constraints.maxWidth,
                pageSplit: pageSplit,
              );
              final analysisSideBySide = prayerAnalysisCardsSideBySide(
                context,
                analysisWidth,
              );

              return _PrayerMainContent(
                pageSplit: pageSplit,
                analysisSideBySide: analysisSideBySide,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrayerMainContent extends StatelessWidget {
  const _PrayerMainContent({
    required this.pageSplit,
    required this.analysisSideBySide,
  });

  final bool pageSplit;
  final bool analysisSideBySide;

  static const _hero = AnimationEntry(
    delay: Duration(milliseconds: 100),
    animateOnce: true,
    child: PrayerHeroHeader(key: ValueKey('prayer_hero_header')),
  );

  static const _schedule = AnimationEntry(
    delay: Duration(milliseconds: 250),
    animateOnce: true,
    child: PrayerScheduleList(key: ValueKey('prayer_schedule_list')),
  );

  @override
  Widget build(BuildContext context) {
    final analysis = AnimationEntry(
      delay: const Duration(milliseconds: 400),
      animateOnce: true,
      child: AnalysisSection(
        key: const ValueKey('prayer_analysis_section'),
        sideBySide: analysisSideBySide,
      ),
    );

    if (pageSplit) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              spacing: AppSpacing.lg,
              children: [_hero, _schedule],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 4,
            child: analysis,
          ),
        ],
      );
    }

    return Column(
      spacing: AppSpacing.lg,
      children: [_hero, _schedule, analysis],
    );
  }
}
