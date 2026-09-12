import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_analytics_prefs.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/trend_analysis_card.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _analysisHost({
  required AsyncValue<PrayerAnalysisSectionData> analysis,
  required PrayerAnalyticsPeriod period,
}) {
  final analysisOverride = analysis.when(
    data: (value) => prayerAnalysisSectionProvider.overrideWith(
      () => _StaticAnalysisNotifier(value),
    ),
    loading: () => prayerAnalysisSectionProvider.overrideWith(
      _LoadingAnalysisNotifier.new,
    ),
    error: (error, stackTrace) => prayerAnalysisSectionProvider.overrideWith(
      () => _ErrorAnalysisNotifier(error, stackTrace),
    ),
  );
  return ProviderScope(
    overrides: [
      analysisOverride,
      prayerAnalyticsSettingsProvider.overrideWith(
        () => _StaticAnalyticsSettingsNotifier(period),
      ),
    ],
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.neutral,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: TrendAnalysisCard()),
      ),
    ),
  );
}

class _StaticAnalysisNotifier extends PrayerAnalysisSectionNotifier {
  _StaticAnalysisNotifier(this.value);

  final PrayerAnalysisSectionData value;

  @override
  Future<PrayerAnalysisSectionData> build() async => value;
}

class _LoadingAnalysisNotifier extends PrayerAnalysisSectionNotifier {
  @override
  Future<PrayerAnalysisSectionData> build() =>
      Completer<PrayerAnalysisSectionData>().future;
}

class _ErrorAnalysisNotifier extends PrayerAnalysisSectionNotifier {
  _ErrorAnalysisNotifier(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  Future<PrayerAnalysisSectionData> build() => Future.error(error, stackTrace);
}

class _StaticAnalyticsSettingsNotifier extends PrayerAnalyticsSettingsNotifier {
  _StaticAnalyticsSettingsNotifier(this.period);

  final PrayerAnalyticsPeriod period;

  @override
  Future<PrayerAnalyticsPrefs> build() async =>
      PrayerAnalyticsPrefs(period: period);
}

void main() {
  test('empty periods are distinct from explicit zero-success records', () {
    final empty = PrayerAnalysisSectionData.empty(
      PrayerAnalyticsPeriod.weekly,
    );
    expect(empty.hasRecordedData, isFalse);

    final analytics = PrayerAnalyticsCalculator.calculateAnalytics(
      period: PrayerAnalyticsPeriod.monthly,
      statusCounts: {
        for (final status in CompletionStatus.values) status: 0,
        CompletionStatus.late: 1,
        CompletionStatus.missed: 1,
      },
      expectedPrayers: 10,
      currentStreak: 0,
      bestStreak: 0,
    );
    final recorded = PrayerAnalysisSectionData(
      period: PrayerAnalyticsPeriod.monthly,
      hasRecordedData: true,
      todayStatusCounts: const {},
      todayPrayerStatuses: const {},
      todayPerformanceScore: 0,
      periodAnalytics: analytics,
      trendBuckets: const [],
    );

    expect(recorded.period, PrayerAnalyticsPeriod.monthly);
    expect(recorded.hasRecordedData, isTrue);
    expect(recorded.periodAnalytics.completionPercentage, 0);
    expect(recorded.periodAnalytics.latePercentage, 0.1);
    expect(recorded.periodAnalytics.missedPercentage, 0.1);
  });

  testWidgets('empty state keeps the selected period scope and hides zeros', (
    tester,
  ) async {
    await tester.pumpWidget(
      _analysisHost(
        analysis: AsyncData(
          PrayerAnalysisSectionData.empty(PrayerAnalyticsPeriod.monthly),
        ),
        period: PrayerAnalyticsPeriod.monthly,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('On time prayers (last 30 days)'), findsOneWidget);
    expect(find.text('No prayer records for this period'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('loading state does not flash the no-records copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _analysisHost(
        analysis: const AsyncLoading(),
        period: PrayerAnalyticsPeriod.weekly,
      ),
    );
    await tester.pump();

    expect(find.text('No prayer records for this period'), findsNothing);
    expect(find.text('On time prayers (last 7 days)'), findsNothing);
  });
}
