import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/trend_chart.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _analysisHost({
  required AsyncValue<PrayerAnalysisSectionData> analysis,
  required PrayerAnalyticsPeriod period,
  Key? key,
  Locale locale = const Locale('en'),
  AppPalette palette = AppPalette.neutral,
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
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
    key: key,
    overrides: [
      analysisOverride,
      prayerAnalyticsSettingsProvider.overrideWith(
        () => _StaticAnalyticsSettingsNotifier(period),
      ),
    ],
    child: FTheme(
      data: buildAppTheme(
        palette: palette,
        themeMode: themeMode,
        touch: false,
        textScale: textScale,
      ),
      child: MaterialApp(
        locale: locale,
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

PrayerAnalysisSectionData _recordedMissedData() {
  final analytics = PrayerAnalyticsCalculator.calculateAnalytics(
    period: PrayerAnalyticsPeriod.monthly,
    statusCounts: {
      for (final status in CompletionStatus.values) status: 0,
      CompletionStatus.missed: 1,
    },
    expectedPrayers: 1,
    currentStreak: 0,
    bestStreak: 0,
  );
  return PrayerAnalysisSectionData(
    period: PrayerAnalyticsPeriod.monthly,
    isReady: true,
    hasRecordedData: true,
    todayStatusCounts: const {},
    todayPrayerStatuses: const {},
    todayPerformanceScore: 0,
    periodAnalytics: analytics,
    trendBuckets: [
      PrayerTrendBucket(
        start: DateTime(2026, 9, 13),
        end: DateTime(2026, 9, 13, 23, 59, 59),
        statusCounts: const {CompletionStatus.missed: 1},
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('IBMPlexSansArabic')
      ..addFont(
        rootBundle.load(
          'assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Regular.ttf',
        ),
      );
    await loader.load();
    final iconLoader = FontLoader('ForuiLucideIcons')
      ..addFont(
        rootBundle.load('packages/forui_assets/assets/lucide.ttf'),
      );
    await iconLoader.load();
    final packageIconLoader =
        FontLoader('packages/forui_assets/ForuiLucideIcons')..addFont(
          rootBundle.load('packages/forui_assets/assets/lucide.ttf'),
        );
    await packageIconLoader.load();
  });

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
      isReady: true,
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
        key: const ValueKey('prayer-empty-review'),
        analysis: AsyncData(
          PrayerAnalysisSectionData.empty(
            PrayerAnalyticsPeriod.monthly,
            isReady: true,
          ),
        ),
        period: PrayerAnalyticsPeriod.monthly,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('No prayer records for this period'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.byType(TrendChart), findsNothing);
  });

  testWidgets('explicit missed records keep zero-success analytics visible', (
    tester,
  ) async {
    final data = _recordedMissedData();

    await tester.pumpWidget(
      _analysisHost(
        analysis: AsyncData(data),
        period: PrayerAnalyticsPeriod.monthly,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrendChart), findsOneWidget);
    expect(find.text('Missed Rate'), findsOneWidget);
    expect(find.text('0%'), findsWidgets);
    expect(find.text('No prayer records for this period'), findsNothing);
  });

  testWidgets('empty and data states render review evidence', (tester) async {
    await tester.pumpWidget(
      _analysisHost(
        analysis: AsyncData(
          PrayerAnalysisSectionData.empty(
            PrayerAnalyticsPeriod.monthly,
            isReady: true,
          ),
        ),
        period: PrayerAnalyticsPeriod.monthly,
        palette: AppPalette.manuscript,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(TrendAnalysisCard),
      matchesGoldenFile('goldens/prayer_empty_en_manuscript_light.png'),
    );

    await tester.pumpWidget(
      _analysisHost(
        key: const ValueKey('prayer-data-review'),
        analysis: AsyncData(_recordedMissedData()),
        period: PrayerAnalyticsPeriod.monthly,
        locale: const Locale('ar'),
        palette: AppPalette.neutral,
        themeMode: ThemeMode.dark,
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(TrendAnalysisCard),
      matchesGoldenFile('goldens/prayer_data_ar_neutral_dark_large.png'),
    );
  });

  testWidgets('period scope follows the selected period', (tester) async {
    Future<void> pumpPeriod(PrayerAnalyticsPeriod period) async {
      await tester.pumpWidget(
        _analysisHost(
          key: ValueKey(period),
          analysis: AsyncData(
            PrayerAnalysisSectionData.empty(period, isReady: true),
          ),
          period: period,
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpPeriod(PrayerAnalyticsPeriod.weekly);
    expect(find.text('Last 7 days'), findsOneWidget);
    await pumpPeriod(PrayerAnalyticsPeriod.monthly);
    expect(find.text('Last 30 days'), findsOneWidget);
  });

  testWidgets('unready data is not presented as no records', (tester) async {
    await tester.pumpWidget(
      _analysisHost(
        analysis: AsyncData(
          PrayerAnalysisSectionData.empty(PrayerAnalyticsPeriod.monthly),
        ),
        period: PrayerAnalyticsPeriod.monthly,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No prayer records for this period'), findsNothing);
    expect(find.text('Last 30 days'), findsNothing);
    expect(find.byType(TrendChart), findsNothing);
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
    expect(find.text('Last 7 days'), findsNothing);
    expect(find.byType(TrendChart), findsNothing);
  });

  testWidgets('error state does not fall through to no records', (
    tester,
  ) async {
    await tester.pumpWidget(
      _analysisHost(
        analysis: AsyncError(StateError('test error'), StackTrace.current),
        period: PrayerAnalyticsPeriod.weekly,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No prayer records for this period'), findsNothing);
    expect(find.text('Last 7 days'), findsNothing);
    expect(find.byType(TrendChart), findsNothing);
  });
}
