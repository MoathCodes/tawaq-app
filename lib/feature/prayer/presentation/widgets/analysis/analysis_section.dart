import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/daily_achievement_card.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/trend_analysis_card.dart';
import 'package:tawaq/theme/theme.dart';

/// Analysis section containing daily achievement and trends cards.
class AnalysisSection extends ConsumerWidget {
  /// Creates an [AnalysisSection].
  const new({this.sideBySide = false, super.key});

  /// Whether daily and trend cards render side-by-side.
  final bool sideBySide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(prayerAnalysisSectionProvider);

    return analysisState.when(
      skipLoadingOnRefresh: false,
      data: (data) => data.isReady
          ? _AnalysisContent(sideBySide: sideBySide)
          : _AnalysisLoadingContent(sideBySide: sideBySide),
      loading: () {
        final previous = analysisState.asData?.value;
        if (previous?.isReady ?? false) {
          return _AnalysisContent(sideBySide: sideBySide);
        }
        return _AnalysisLoadingContent(sideBySide: sideBySide);
      },
      error: (_, _) => StaticCard(
        child: ErrorStatePanel(
          message: context.l10n.prayerAnalyticsLoadFailed,
          retryLabel: context.l10n.retryAction,
          onRetry: () =>
              ref.read(prayerAnalysisSectionProvider.notifier).retry(),
        ),
      ),
    );
  }
}

class _AnalysisLoadingContent extends StatelessWidget {
  const new({required this.sideBySide});

  final bool sideBySide;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loadingAnalytics,
    child: FSkeletonizer(child: _AnalysisContent(sideBySide: sideBySide)),
  );
}

class _AnalysisContent extends StatelessWidget {
  const new({required this.sideBySide});

  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
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
      children: [DailyAchievementCard(), TrendAnalysisCard()],
    );
  }
}
