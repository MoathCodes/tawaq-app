import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
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
            period: PrayerAnalyticsPeriod.weekly,
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PrayerAnalyticsWidget extends StatelessWidget {
  const _PrayerAnalyticsWidget({
    required this.data,
    required this.onPeriodChanged,
  });
  // Combined constants from both widgets

  static const _contentPadding = EdgeInsets.symmetric(
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.playerAnalytics),
          const SizedBox(height: AppSpacing.sm),
          FTabs(
            control: .managed(initial: data.period.index),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [_buildProgressSection(colors, l10n), _buildStatsSection(l10n)],
    );
  }

  Widget _buildProgressSection(FColors colors, AppLocalizations l10n) {
    return Container(
      padding: _contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _formatPercentage(data.completionPercentage),
            textAlign: TextAlign.center,
          ).xl2,
          Text(_getPeriodText(l10n), textAlign: TextAlign.center),
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

  Widget _buildStatsSection(AppLocalizations l10n) {
    final stats = [
      (l10n.currentStreak, l10n.streakInDays(data.currentStreak)),
      (l10n.bestStreak, l10n.streakInDays(data.bestStreak)),
      (l10n.jamaahRate, _formatPercentage(data.jamaahPercentage)),
      (l10n.onTimeRate, _formatPercentage(data.onTimePercentage)),
      (l10n.lateRate, _formatPercentage(data.latePercentage)),
      (l10n.missedRate, _formatPercentage(data.missedPercentage)),
    ];

    return Wrap(
      spacing: _wrapSpacing,
      runSpacing: _wrapSpacing,
      alignment: WrapAlignment.spaceEvenly,
      children: stats
          .map((stat) => MiniCard(label: stat.$1, child: Text(stat.$2)))
          .toList(),
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
      PrayerAnalyticsPeriod.weekly => l10n.onTimePrayersLast7Days,
      PrayerAnalyticsPeriod.monthly => l10n.onTimePrayersLast30Days,
      PrayerAnalyticsPeriod.yearly => l10n.onTimePrayersLast365Days,
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
