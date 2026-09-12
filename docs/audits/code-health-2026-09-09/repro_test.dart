import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

class _Day extends PrayerDay {
  new(this.events);
  final Stream<PrayerDaySnapshot> events;
  @override
  Stream<PrayerDaySnapshot> build() => events;
}

class _Repository extends Mock implements HadithRepository {}

class _Settings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async =>
      const HadithPersistedSettings();
}

DetailedHadith _result(String text) => DetailedHadith(
  hadith: text,
  rawi: 'fixture',
  mohdith: 'fixture',
  book: 'fixture',
  numberOrPage: '1',
  grade: 'fixture',
);

// These assertions describe the intended behavior. Failures reproduce audit
// findings; this file is outside test/ so it does not alter the baseline suite.
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(const HadithSearchParams(value: 'fixture'));
  });

  test('same-minute prayer recalculation updates current prayer', () async {
    final location = getLocation('Asia/Riyadh');
    final inputs = PrayerTimeInputs(
      method: PrayerSettings.defaultSettings().method,
      coordinates: Coordinates(21.575224, 39.210725),
      location: location,
    );
    final anchor = TZDateTime(location, 2026, 9, 9, 12);
    final original = computePrayerDayBundle(inputs: inputs, anchorNow: anchor);
    final adjusted = computePrayerDayBundle(
      inputs: inputs.copyWith(adhanAdjustments: {Prayer.dhuhr: 30}),
      anchorNow: anchor,
    );
    final now = original.timeline.dhuhrToday.add(const Duration(minutes: 1));
    final events = StreamController<PrayerDaySnapshot>();
    final container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWith((ref) => Stream.value(now)),
        prayerDayProvider.overrideWith(() => _Day(events.stream)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await events.close();
    });
    container.listen(scheduleCurrentPrayerProvider, (_, _) {});
    events.add(
      PrayerDaySnapshot(now: now, location: location, bundle: original),
    );
    await pumpEventQueue();
    expect(container.read(scheduleCurrentPrayerProvider), Prayer.dhuhr);
    events.add(
      PrayerDaySnapshot(now: now, location: location, bundle: adjusted),
    );
    await pumpEventQueue();
    final expected = getCurrentPrayer(
      currentTime: now,
      location: location,
      timeline: adjusted.timeline,
    );
    expect(expected, isNot(Prayer.dhuhr));
    expect(container.read(scheduleCurrentPrayerProvider), expected);
  });

  testWidgets('merged action retains an accessibility tap action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MergedActionSemantics(
          label: 'audit action',
          child: TextButton(onPressed: () {}, child: const Text('action')),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.bySemanticsLabel('audit action'))
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('Quran labeled field retains editable semantics', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranSemantics.labeledControl(
            name: 'audit search',
            excludeChild: true,
            child: const TextField(),
          ),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.bySemanticsLabel('audit search'))
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.setText), isTrue);
  });

  for (final delta in [1, -1]) {
    test('unselected Hadith navigation starts at boundary ($delta)', () async {
      final repository = _Repository();
      when(() => repository.searchDetailed(any())).thenAnswer(
        (_) async => ApiResponse(
          metadata: const SearchMetadata(length: 3),
          data: [_result('first'), _result('middle'), _result('last')],
        ),
      );
      when(() => repository.addRecentSearch(any())).thenAnswer((_) async {});
      when(repository.getRecentSearches).thenAnswer((_) async => []);
      final container = ProviderContainer(
        overrides: [
          hadithRepositoryProvider.overrideWith((ref) async => repository),
          hadithScreenSettingsProvider.overrideWith(_Settings.new),
        ],
      );
      addTearDown(container.dispose);
      container.listen(hadithSessionControllerProvider, (_, _) {});
      await container.read(hadithScreenSettingsProvider.future);
      final controller = container.read(
        hadithSessionControllerProvider.notifier,
      );
      await controller.setQuery('fixture');
      await controller.selectAdjacentResult(delta);
      expect(
        container.read(selectedHadithProvider)?.hadith,
        delta > 0 ? 'first' : 'last',
      );
    });
  }

  test('immediate filter reset cancels pending debounced search', () async {
    final repository = _Repository();
    var calls = 0;
    when(() => repository.searchDetailed(any())).thenAnswer((_) async {
      calls++;
      return ApiResponse(
        metadata: const SearchMetadata(length: 1),
        data: [_result('result')],
      );
    });
    when(() => repository.addRecentSearch(any())).thenAnswer((_) async {});
    when(repository.getRecentSearches).thenAnswer((_) async => []);
    final container = ProviderContainer(
      overrides: [
        hadithRepositoryProvider.overrideWith((ref) async => repository),
        hadithScreenSettingsProvider.overrideWith(_Settings.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hadithSessionControllerProvider, (_, _) {});
    final controller = container.read(hadithSessionControllerProvider.notifier);
    await controller.setQuery('fixture');
    calls = 0;
    await controller.setFilters(const HadithFilters(specialist: true));
    await controller.clearFilters();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(calls, 1);
  });
}
