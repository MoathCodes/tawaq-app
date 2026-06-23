import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_widgets.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Card showing today's prayer progress, streaks, and status breakdown.
class DailyAchievementCard extends ConsumerWidget {
  /// Creates a [DailyAchievementCard].
  const DailyAchievementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final analytics = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.periodAnalytics,
      ),
    );
    final todayStatusCounts = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayStatusCounts,
      ),
    );
    final todayPerformanceScore = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayPerformanceScore ?? 0.0,
      ),
    );

    if (analytics == null || todayStatusCounts == null) {
      return const SizedBox.shrink();
    }

    final loggedCount = todayStatusCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final percent = (todayPerformanceScore * 100).round();

    return StaticCard(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.todayAchievement,
                    style: theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Semantics(
                label: PrayerSemantics.todayPerformance(
                  l10n: l10n,
                  percent: percent,
                ),
                readOnly: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.12),
                    borderRadius: theme.radii.full,
                    border: Border.all(
                      color: theme.colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$loggedCount/${PrayerAnalyticsCalculator.prayersPerDay} · $percent%',
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: PrayerSemantics.streakSummary(
              l10n: l10n,
              currentStreak: analytics.currentStreak,
              bestStreak: analytics.bestStreak,
            ),
            readOnly: true,
            child: StreakBanner(
              currentStreak: analytics.currentStreak,
              bestStreak: analytics.bestStreak,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TodayPrayerTracker(),
          const SizedBox(height: AppSpacing.lg),
          const TodayStatusGrid(),
        ],
      ),
    );
  }
}
