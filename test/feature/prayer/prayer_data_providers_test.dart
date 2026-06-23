import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_effective_settings_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerTimeInputs inputsFromSettings(PrayerSettings settings) =>
    PrayerTimeInputs(
      method: settings.method,
      coordinates: settings.coordinates,
      location: settings.location,
    );

void main() {
  setUpAll(tz.initializeTimeZones);

  group('prayerDayIsLoading', () {
  late ProviderContainer container;
  late PrayerSettings jeddahSettings;

  setUp(() {
    jeddahSettings = PrayerSettings.defaultSettings().copyWith(
      coordinates: const Coordinates(21.575224, 39.210725),
      location: getLocation('Asia/Riyadh'),
    );

    final box = Box<int, PrayerCompletion>(
      'prayer_day_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    final repo = PrayerRepo(
      prayerDatabase: PrayerDatabase(box),
      log: Logger(),
    );

    container = ProviderContainer(
      overrides: [
        hiveCoreInitProvider.overrideWith((ref) async {}),
        prayerCompletionsRepairProvider.overrideWith((ref) async {}),
        prayerRepoProvider.overrideWithValue(repo),
        prayerTimeInputsProvider.overrideWithValue(
          inputsFromSettings(jeddahSettings),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('resolves after the live stream emits its first snapshot', () async {
    expect(container.read(prayerTimeInputsProvider), isNotNull);
    expect(container.read(prayerDayIsLoadingProvider), isTrue);

    final states = <AsyncValue<PrayerDaySnapshot>>[];
    container.listen(
      prayerDayProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(states.any((state) => state.hasValue), isTrue, reason: '$states');
    expect(container.read(prayerDayIsLoadingProvider), isFalse);
    expect(container.read(prayerCalendarDayKeyProvider), isNot(0));
  });
  });
}
