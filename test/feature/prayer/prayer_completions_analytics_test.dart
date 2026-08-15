import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

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
}
