import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/feature/settings/presentation/provider/first_prayer_recorded_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

class _ThrowingRepo extends Mock implements PrayerRepo {}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(getLocation('Asia/Riyadh'));
    registerFallbackValue(DateTime(2026, 6, 18));
    registerFallbackValue(PrayerAnalyticsPeriod.weekly);
  });

  late PrayerSettings jeddahSettings;
  late Location location;

  setUp(() {
    location = getLocation('Asia/Riyadh');
    jeddahSettings = PrayerSettings.defaultSettings().copyWith(
      coordinates: Coordinates(21.575224, 39.210725),
      location: location,
    );
  });

  group('completionStatus', () {
    test('loading is null, not CompletionStatus.none', () async {
      final dayKey = calendarDayKeyFromDate(DateTime(2026, 6, 18));
      final completer = Completer<List<PrayerCompletion>>();

      final container = ProviderContainer(
        overrides: [
          prayerTimeInputsProvider.overrideWithValue(
            PrayerTimeInputs(
              method: jeddahSettings.method,
              coordinates: jeddahSettings.coordinates,
              location: jeddahSettings.location,
            ),
          ),
          prayerCompletionsForDateProvider(dayKey).overrideWith(
            (ref) => completer.future,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(completionStatusProvider(Prayer.fajr, dayKey)),
        isNull,
      );

      completer.complete(const []);
      await container.read(prayerCompletionsForDateProvider(dayKey).future);

      expect(
        container.read(completionStatusProvider(Prayer.fajr, dayKey)),
        CompletionStatus.none,
      );
    });

    test('dayKey invalidation refreshes status', () async {
      final dayKey = calendarDayKeyFromDate(DateTime(2026, 6, 18));
      var rows = <PrayerCompletion>[];

      final container = ProviderContainer(
        overrides: [
          prayerTimeInputsProvider.overrideWithValue(
            PrayerTimeInputs(
              method: jeddahSettings.method,
              coordinates: jeddahSettings.coordinates,
              location: jeddahSettings.location,
            ),
          ),
          prayerCompletionsForDateProvider(dayKey).overrideWith(
            (ref) async => rows,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(
          prayerCompletionsForDateProvider(dayKey).future,
        ),
        isEmpty,
      );
      expect(
        container.read(completionStatusProvider(Prayer.fajr, dayKey)),
        CompletionStatus.none,
      );

      rows = [
        PrayerCompletion(
          id: null,
          prayer: Prayer.fajr,
          completionTime: DateTime(2026, 6, 18),
          status: CompletionStatus.jamaah,
        ),
      ];
      container.invalidate(prayerCompletionsForDateProvider(dayKey));

      expect(
        await container.read(
          prayerCompletionsForDateProvider(dayKey).future,
        ),
        hasLength(1),
      );
      expect(
        container.read(completionStatusProvider(Prayer.fajr, dayKey)),
        CompletionStatus.jamaah,
      );
    });
  });

  group('PrayerAnalysisSection', () {
    test('repo failure surfaces as AsyncError', () async {
      final throwing = _ThrowingRepo();
      when(
        () => throwing.computeStreaks(any()),
      ).thenThrow(StateError('boom'));
      when(
        () => throwing.countAllStatusesOnPeriod(any(), any(), any()),
      ).thenAnswer((_) async => {});
      when(
        () => throwing.getCompletionsBetween(any(), any(), any()),
      ).thenAnswer((_) async => []);

      final dayKey = calendarDayKeyFromDate(
        TZDateTime.now(location),
      );

      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWith(
            (ref) async => Storage<String, String>.inMemory(),
          ),
          prayerRepoProvider.overrideWithValue(throwing),
          effectivePrayerSettingsProvider.overrideWithValue(jeddahSettings),
          prayerTimeInputsProvider.overrideWithValue(
            PrayerTimeInputs(
              method: jeddahSettings.method,
              coordinates: jeddahSettings.coordinates,
              location: jeddahSettings.location,
            ),
          ),
          prayerCalendarDayKeyProvider.overrideWithValue(dayKey),
          prayerCompletionsForDateProvider(dayKey).overrideWith(
            (ref) async => const [],
          ),
          firstPrayerRecordedDateProvider.overrideWith(
            _FirstPrayerOverride.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(prayerAnalysisSectionProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(prayerAnalysisSectionProvider).hasError,
        isTrue,
      );
    });
  });
}

class _FirstPrayerOverride extends FirstPrayerRecordedDate {
  @override
  Future<String?> build() async => null;
}
