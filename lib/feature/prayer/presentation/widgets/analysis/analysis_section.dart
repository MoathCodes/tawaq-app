import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/daily_achievement_card.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/trend_analysis_card.dart';
import 'package:tawaq/theme/theme.dart';

/// Analysis section containing daily achievement and trends cards.
class AnalysisSection extends ConsumerWidget {
  /// Creates an [AnalysisSection].
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(prayerAnalysisSectionProvider);

    return analysisState.when(
      data: (data) => _AnalysisContent(data: data),
      loading: () {
        final previous = analysisState.asData?.value;
        if (previous != null) {
          return _AnalysisContent(data: previous);
        }
        return Semantics(
          label: context.l10n.loadingAnalytics,
          child: FSkeletonizer(
            child: _AnalysisContent(
              data: PrayerAnalysisSectionData.empty(
                PrayerAnalyticsPeriod.weekly,
              ),
              showSkeleton: true,
            ),
          ),
        );
      },
      error: (e, _) => StaticCard(
        child: FAlert(
          title: Text(
            context.l10n.errorOccurredWhile(context.l10n.loadingAnalytics),
          ),
          subtitle: Text(e.toString()),
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({
    required this.data,
    this.showSkeleton = false,
  });

  final PrayerAnalysisSectionData data;
  final bool showSkeleton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= context.theme.breakpoints.md;

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(child: DailyAchievementCard(data: data)),
              Expanded(
                child: TrendAnalysisCard(
                  data: data,
                  enabled: !showSkeleton,
                ),
              ),
            ],
          );
        }

        return Column(
          spacing: AppSpacing.md,
          children: [
            DailyAchievementCard(data: data),
            TrendAnalysisCard(
              data: data,
              enabled: !showSkeleton,
            ),
          ],
        );
      },
    );
  }
}
