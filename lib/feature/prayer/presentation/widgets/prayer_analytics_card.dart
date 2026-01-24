import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';

/// Widget that displays prayer analytics in a card.
class PrayerAnalyticsCard extends ConsumerWidget {
  /// Creates a [PrayerAnalyticsCard] instance.
  const PrayerAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAnalytics = ref.watch(prayerAnalyticsProvider);

    return prayerAnalytics.when(
      data: (data) => _PrayerAnalyticsWidget(
        data: data,
        onPeriodChanged: (period) =>
            ref.read(prayerAnalyticsProvider.notifier).changePeriod(period),
      ),
      loading: () => FSkeletonizer(
        child: _PrayerAnalyticsWidget(
          data: const PrayerAnalytics(
            period: .weekly,
            completionPercentage: 0.75,
            currentStreak: 5,
            bestStreak: 12,
            jamaahPercentage: 0.65,
            onTimePercentage: 0.55,
            missedPercentage: 0.10,
            latePercentage: 0.20,
          ),
          onPeriodChanged: (p0) {},
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PrayerAnalyticsWidget extends StatelessWidget {
  const _PrayerAnalyticsWidget({
    required this.data,
    required this.onPeriodChanged,
  });
  // Combined constants from both widgets

  static const EdgeInsets _contentPadding = .symmetric(
    horizontal: 12,
    vertical: 16,
  );
  static const _progressBarRadius = 8.0;
  static const _wrapSpacing = 8.0;
  final PrayerAnalytics data;

  final void Function(PrayerAnalyticsPeriod) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    final l10n = context.l10n;

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.playerAnalytics,
            style: FTheme.of(context).typography.lg.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FTabs(
            control: FTabControl.managed(initial: data.period.index),
            style: (style) => style.copyWith(
              decoration: style.decoration.copyWith(color: colors.barrier),
              unselectedLabelTextStyle: style.unselectedLabelTextStyle.copyWith(
                color: colors.secondaryForeground.withAlpha(150),
              ),
            ),
            onPress: (index) =>
                onPeriodChanged(PrayerAnalyticsPeriod.values[index]),
            children: _buildTabEntries(context, colors, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    FColors colors,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: AppSpacing.sm,
        children: [
          _buildProgressSection(colors, l10n),
          const FDivider(),
          _buildStatsSection(l10n, colors),
        ],
      ),
    );
  }

  Widget _buildProgressSection(FColors colors, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Text(
            _formatPercentage(data.completionPercentage),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _getProgressColor(data.completionPercentage, colors),
            ),
          ),
          Text(
            _getPeriodText(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FDeterminateProgress(
            value: data.completionPercentage,
            style: (style) => style.copyWith(
              trackDecoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(_progressBarRadius),
              ),
              fillDecoration: BoxDecoration(
                color: _getProgressColor(data.completionPercentage, colors),
                borderRadius: BorderRadius.circular(_progressBarRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n, FColors colors) {
    // Group related stats together
    final streakStats = [
      (l10n.currentStreak, l10n.streakInDays(data.currentStreak)),
      (l10n.bestStreak, l10n.streakInDays(data.bestStreak)),
    ];
    final rateStats = [
      (l10n.jamaahRate, _formatPercentage(data.jamaahPercentage)),
      (l10n.onTimeRate, _formatPercentage(data.onTimePercentage)),
      (l10n.lateRate, _formatPercentage(data.latePercentage)),
      (l10n.missedRate, _formatPercentage(data.missedPercentage)),
    ];

    return Column(
      spacing: AppSpacing.sm,
      children: [
        // Streak stats row
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: streakStats
              .map((stat) => MiniCard(label: stat.$1, child: Text(stat.$2)))
              .toList(),
        ),
        // Rate stats row
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceEvenly,
          children: rateStats
              .map((stat) => MiniCard(label: stat.$1, child: Text(stat.$2)))
              .toList(),
        ),
      ],
    );
  }

  List<FTabEntry> _buildTabEntries(
    BuildContext context,
    FColors colors,
    AppLocalizations l10n,
  ) {
    return PrayerAnalyticsPeriod.values.map((period) {
      return FTabEntry(
        label: Text(period.getLocaleName(l10n)),
        child: _buildAnalyticsContent(context, colors, l10n),
      );
    }).toList();
  }

  // Utility methods
  String _formatPercentage(double value) => '${(value * 100).round()}%';

  String _getPeriodText(AppLocalizations l10n) {
    return switch (data.period) {
      .daily => l10n.onTimePrayersToday,
      .weekly => l10n.onTimePrayersLast7Days,
      .monthly => l10n.onTimePrayersLast30Days,
      .yearly => l10n.onTimePrayersLast365Days,
    };
  }

  Color _getProgressColor(double percentage, FColors colors) {
    return switch (percentage) {
      > 0.6 => Colors.green.shade700,
      > 0.3 => colors.primary,
      _ => colors.error,
    };
  }
}
