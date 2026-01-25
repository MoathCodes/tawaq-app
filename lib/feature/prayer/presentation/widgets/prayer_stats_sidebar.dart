import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// Stats sidebar showing prayer analytics and insights.
class PrayerStatsSidebar extends ConsumerWidget {
  /// Creates a [PrayerStatsSidebar] instance.
  const PrayerStatsSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(prayerAnalyticsProvider);

    return analyticsState.when(
      data: (PrayerAnalytics analytics) =>
          _SidebarContent(analytics: analytics),
      loading: () => FSkeletonizer(
        child: _SidebarContent(analytics: PrayerAnalytics.empty()),
      ),
      error: (Object e, _) => StaticCard(
        child: FAlert(
          title: Text(context.l10n.errorOccurredWhile('Loading Analytics')),
          subtitle: Text(e.toString()),
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({required this.analytics});

  final PrayerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Jama'ah Rate Card
        _StatCard(
          label: context.l10n.jamaahRate,
          value: '${(analytics.jamaahPercentage * 100).toInt()}%',
          icon: FIcons.users,
          iconColor: Colors.green,
        ),
        const SizedBox(height: AppSpacing.md),
        // Current Streak Card
        _StatCard(
          label: context.l10n.currentStreak,
          value: context.l10n.streakInDays(analytics.currentStreak),
          icon: FIcons.clock,
          iconColor: Colors.blue,
        ),
        const SizedBox(height: AppSpacing.md),
        // Qada (Owed) Card
        _QadaCard(
          missedCount: (analytics.missedPercentage * 100).toInt(),
        ),
        const SizedBox(height: AppSpacing.md),
        // AI Insight Card (Placeholder)
        // const _InsightCard(),
        // const SizedBox(height: AppSpacing.md),
        // // Weekly Quality Graph (Placeholder)
        // const _WeeklyQualityCard(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: theme.colors.foreground.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: context.theme.radii.md,
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
        ],
      ),
    );
  }
}

class _QadaCard extends StatelessWidget {
  const _QadaCard({required this.missedCount});

  final int missedCount;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: theme.colors.foreground.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.qadaOwed.toUpperCase(),
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$missedCount',
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: context.theme.radii.md,
            ),
            child: Icon(FIcons.circleAlert, color: Colors.orange, size: 24.sp),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade900,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: context.theme.radii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.sparkles, color: Colors.purple.shade300, size: 16.sp),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.aiInsight.toUpperCase(),
                style: theme.typography.xs.copyWith(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Placeholder insight text
          RichText(
            text: TextSpan(
              style: theme.typography.sm.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              children: [
                const TextSpan(text: '"You tend to delay '),
                TextSpan(
                  text: 'Asr',
                  style: TextStyle(color: Colors.blue.shade300),
                ),
                const TextSpan(text: '. Try a reminder 15m earlier."'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Placeholder action button
          SizedBox(
            width: double.infinity,
            child: FButton(
              onPress: () {
                // TODO(insights): Implement auto-schedule reminder
              },
              style: FButtonStyle.secondary(),
              child: const Text('Auto-Schedule Reminder'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyQualityCard extends StatelessWidget {
  const _WeeklyQualityCard();

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.weeklyQuality.toUpperCase(),
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '+12%',
                style: theme.typography.sm.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Placeholder bar graph
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .asMap()
                .entries
                .map(
                  (entry) => _DayBar(
                    label: entry.value,
                    // Placeholder heights
                    height: 20.0 + (entry.key * 8.0),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.height,
  });

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      children: [
        Container(
          width: 24.w,
          height: height.h,
          decoration: BoxDecoration(
            color: theme.colors.secondary,
            borderRadius: context.theme.radii.sm,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
