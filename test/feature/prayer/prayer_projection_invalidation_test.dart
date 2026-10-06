import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() async { tzdata.initializeTimeZones(); await initializeDateFormatting(); });

  test('fixed-clock offset edit immediately invalidates schedule projections', () async {
    final clock = StreamController<DateTime>();
    final container = ProviderContainer(overrides: [
      settingsStorageProvider.overrideWith((ref) async => Storage<String, String>.inMemory()),
      appClockProvider.overrideWith((ref) => clock.stream),
    ]);
    addTearDown(() async { container.dispose(); await clock.close(); });
    await container.read(prayerSettingsProvider.future);
    final settings = container.read(prayerSettingsProvider.notifier);
    await settings.applyLocationBundle(coordinates: Coordinates(24.471153, 39.6111216),
      location: tz.getLocation('Asia/Riyadh'));
    final sub = container.listen(prayerDayProvider, (_, _) {});
    addTearDown(sub.close);
    clock.add(DateTime.utc(2026, 10, 3, 9, 12));
    await container.read(prayerDayProvider.future);
    container.listen(scheduleCurrentPrayerProvider, (_, _) {});
    container.listen(prayerScheduleProvider(20261003), (_, _) {});
    container.listen(sunnahTimeLabelsProvider, (_, _) {});
    final before = container.read(prayerDayProvider).requireValue;
    final minute = container.read(currentMinuteBucketProvider);
    expect(container.read(scheduleCurrentPrayerProvider), Prayer.dhuhr);
    final rows = container.read(prayerScheduleProvider(20261003));
    settings.setPrayerSettings(container.read(prayerSettingsProvider).requireValue.copyWith(
      adhanAdjustments: {Prayer.dhuhr: 30, Prayer.sunrise: 10},
    ));
    await pumpEventQueue();
    expect(container.read(currentMinuteBucketProvider), minute);
    expect(container.read(prayerDayProvider).requireValue.now, before.now);
    expect(container.read(scheduleCurrentPrayerProvider), Prayer.sunrise);
    final adjusted = container.read(prayerScheduleProvider(20261003));
    expect(adjusted[1].prayerTime.difference(rows[1].prayerTime), const Duration(minutes: 30));
    expect(container.read(sunnahTimeLabelsProvider)!.sunrise,
      isNot(container.read(prayerScheduleProvider(20261003))[0].formattedAdhanTime));
  });
}
