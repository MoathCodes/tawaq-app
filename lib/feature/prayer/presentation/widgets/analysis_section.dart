import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/analysis/daily_achievement_card.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/analysis/trend_analysis_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// Analysis section containing daily achievement and trends cards.
class AnalysisSection extends ConsumerWidget {
  /// Creates an [AnalysisSection].
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(
      stateSettingsProvider.select(
        (value) =>
            value.value?.prayerAnalyticsPeriod ?? PrayerAnalyticsPeriod.weekly,
      ),
    );
    final analysisState = ref.watch(prayerAnalysisSectionProvider);

    return analysisState.when(
      data: (data) => _AnalysisContent(
        data: data,
        onPeriodChanged: (period) => ref
            .read(stateSettingsProvider.notifier)
            .setPrayerAnalyticsPeriod(period),
        selectedPeriod: selectedPeriod,
      ),
      loading: () => FSkeletonizer(
        child: _AnalysisContent(
          data: PrayerAnalysisSectionData.empty(PrayerAnalyticsPeriod.weekly),
          onPeriodChanged: (_) {},
          selectedPeriod: selectedPeriod,
        ),
      ),
      error: (e, _) => StaticCard(
        child: FAlert(
          title: Text(context.l10n.errorOccurredWhile('Loading Analytics')),
          subtitle: Text(e.toString()),
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({
    required this.data,
    required this.onPeriodChanged,
    required this.selectedPeriod,
  });

  final PrayerAnalysisSectionData data;
  final void Function(PrayerAnalyticsPeriod) onPeriodChanged;
  final PrayerAnalyticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DailyAchievementCard(data: data),
        const SizedBox(height: AppSpacing.md),
        TrendAnalysisCard(
          data: data,
          onPeriodChanged: onPeriodChanged,
          selectedPeriod: selectedPeriod,
        ),
      ],
    );
  }
}
