import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/sunnah_times_card.dart';
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
        // Sunnah Times
        const SunnahTimesCard(),
        const SizedBox(height: AppSpacing.md),
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
        // Missed (Qada) Rate Card
        _StatCard(
          label: context.l10n.missedRate,
          value: '${(analytics.missedPercentage * 100).toInt()}%',
          icon: FIcons.circleAlert,
          iconColor: Colors.orange,
        ),
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
