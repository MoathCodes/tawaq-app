import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_widgets.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Card showing today's prayer progress, streaks, and status breakdown.
class DailyAchievementCard extends StatelessWidget {
  /// Creates a [DailyAchievementCard].
  const DailyAchievementCard({required this.data, super.key});

  /// The analysis data to display.
  final PrayerAnalysisSectionData data;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final analytics = data.periodAnalytics;
    final loggedCount = data.todayStatusCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final percent = (data.todayPerformanceScore * 100).round();

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
                    style: theme.typography.lg.copyWith(
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
                        style: theme.typography.sm.copyWith(
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
          TodayPrayerTracker(statuses: data.todayPrayerStatuses),
          const SizedBox(height: AppSpacing.lg),
          TodayStatusGrid(counts: data.todayStatusCounts),
        ],
      ),
    );
  }
}
