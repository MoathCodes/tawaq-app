import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
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
      data: (_) => const _AnalysisContent(),
      loading: () {
        final previous = analysisState.asData?.value;
        if (previous != null) {
          return const _AnalysisContent();
        }
        return Semantics(
          label: context.l10n.loadingAnalytics,
          child: const FSkeletonizer(
            child: _AnalysisContent(),
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
  const _AnalysisContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= context.theme.breakpoints.md;

        if (sideBySide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(child: DailyAchievementCard()),
              Expanded(child: TrendAnalysisCard()),
            ],
          );
        }

        return const Column(
          spacing: AppSpacing.md,
          children: [
            DailyAchievementCard(),
            TrendAnalysisCard(),
          ],
        );
      },
    );
  }
}
