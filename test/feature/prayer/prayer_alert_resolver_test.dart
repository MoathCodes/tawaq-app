import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_resolver.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerDaySnapshot _buildSnapshot({
  required TZDateTime now,
  Location? location,
}) {
  location ??= getLocation('Asia/Riyadh');
  final todayDate = TZDateTime(location, now.year, now.month, now.day);
  final yesterdayDate = todayDate.subtract(const Duration(days: 1));

  final today = PrayerTimes(
    date: todayDate,
    coordinates: Coordinates(24.7136, 46.6753),
    calculationMethod: const UmmAlQura(),
  );
  final yesterday = PrayerTimes(
    date: yesterdayDate,
    coordinates: Coordinates(24.7136, 46.6753),
    calculationMethod: const UmmAlQura(),
  );
  final todaySunnah = SunnahTimes(today);
  final yesterdaySunnah = SunnahTimes(yesterday);

  final timeline = PrayerDayTimeline(
    fajrToday: TZDateTime.from(today.fajr, location),
    sunriseToday: TZDateTime.from(today.sunrise, location),
    dhuhrToday: TZDateTime.from(today.dhuhr, location),
    asrToday: TZDateTime.from(today.asr, location),
    maghribToday: TZDateTime.from(today.maghrib, location),
    ishaToday: TZDateTime.from(today.isha, location),
    ishaYesterday: TZDateTime.from(yesterday.isha, location),
    middleOfNightToday: TZDateTime.from(
      todaySunnah.middleOfTheNight,
      location,
    ),
    middleOfNightYesterday: TZDateTime.from(
      yesterdaySunnah.middleOfTheNight,
      location,
    ),
    lastThirdToday: TZDateTime.from(
      todaySunnah.lastThirdOfTheNight,
      location,
    ),
    lastThirdYesterday: TZDateTime.from(
      yesterdaySunnah.lastThirdOfTheNight,
      location,
    ),
  );

  return PrayerDaySnapshot(
    now: now,
    location: location,
    bundle: PrayerDayBundle(
      today: today,
      yesterday: yesterday,
      todaySunnah: todaySunnah,
      yesterdaySunnah: yesterdaySunnah,
      timeline: timeline,
    ),
  );
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('scheduleAlertModeFromJson', () {
    test('migrates legacy int 0 to off', () {
      expect(
        scheduleAlertModeFromJson(0),
        ScheduleAlertMode.off,
      );
    });

    test('migrates legacy int 1 to sound', () {
      expect(
        scheduleAlertModeFromJson(1),
        ScheduleAlertMode.sound,
      );
    });

    test('parses string modes', () {
      expect(
        scheduleAlertModeFromJson('notify_only'),
        ScheduleAlertMode.notifyOnly,
      );
    });
  });

  group('AdhanSettings migration', () {
    test('legacy enabled int map becomes adhanModes', () {
      final settings = AdhanSettings.fromJson({
        'enabled': {'fajr': 1, 'dhuhr': 0},
      });

      expect(settings.adhanModes[Prayer.fajr], ScheduleAlertMode.sound);
      expect(settings.adhanModes[Prayer.dhuhr], ScheduleAlertMode.off);
    });

    test('string mode map round-trips', () {
      const original = AdhanSettings(
        adhanModes: {Prayer.fajr: ScheduleAlertMode.notifyOnly},
        iqamahModes: {Prayer.dhuhr: ScheduleAlertMode.sound},
        sunnahModes: {Prayer.sunrise: ScheduleAlertMode.notifyOnly},
      );

      final restored = AdhanSettings.fromJson(original.toJson());

      expect(restored.adhanModes[Prayer.fajr], ScheduleAlertMode.notifyOnly);
      expect(restored.iqamahModes[Prayer.dhuhr], ScheduleAlertMode.sound);
      expect(
        restored.sunnahModes[Prayer.sunrise],
        ScheduleAlertMode.notifyOnly,
      );
    });
  });

  group('defaultScheduleAlertModeFor', () {
    test('adhan and iqamah default to sound, sunnah to notifyOnly', () {
      expect(
        defaultScheduleAlertModeFor(PrayerAlertKind.adhan),
        ScheduleAlertMode.sound,
      );
      expect(
        defaultScheduleAlertModeFor(PrayerAlertKind.iqamah),
        ScheduleAlertMode.sound,
      );
      expect(
        defaultScheduleAlertModeFor(PrayerAlertKind.sunnah),
        ScheduleAlertMode.notifyOnly,
      );
    });

    test('AdhanSettings.defaults includes sunnah notifyOnly', () {
      final settings = AdhanSettings.defaults();

      expect(settings.adhanModes[Prayer.fajr], ScheduleAlertMode.sound);
      expect(
        settings.sunnahModes[Prayer.sunrise],
        ScheduleAlertMode.notifyOnly,
      );
      expect(
        adhanSettingsModeFor(
          settings,
          PrayerAlertKind.iqamah,
          Prayer.dhuhr,
        ),
        ScheduleAlertMode.sound,
      );
    });
  });

  group('adhanSettingsWithMode', () {
    test('sunnah sound sanitizes to notifyOnly', () {
      final settings = AdhanSettings.defaults();
      final updated = adhanSettingsWithMode(
        settings,
        PrayerAlertKind.sunnah,
        Prayer.sunrise,
        ScheduleAlertMode.sound,
      );

      expect(updated.sunnahModes[Prayer.sunrise], ScheduleAlertMode.notifyOnly);
    });

    test('adhan sound is stored unchanged', () {
      final settings = AdhanSettings.defaults();
      final updated = adhanSettingsWithMode(
        settings,
        PrayerAlertKind.adhan,
        Prayer.fajr,
        ScheduleAlertMode.sound,
      );

      expect(updated.adhanModes[Prayer.fajr], ScheduleAlertMode.sound);
    });
  });

  group('scheduledPrayerAlertTargets', () {
    test('iqamah time is adhan plus offset minutes', () {
      final location = getLocation('Asia/Riyadh');
      final now = TZDateTime(location, 2026, 6, 9, 12);
      final snapshot = _buildSnapshot(now: now, location: location);
      final prayerSettings = PrayerSettings.defaultSettings().copyWith(
        iqamahSettings: {Prayer.dhuhr: 20},
        adhanAdjustments: {},
      );

      final targets = scheduledPrayerAlertTargets(
        snapshot: snapshot,
        prayerSettings: prayerSettings,
      );

      final adhanTime = snapshot.today.getTimesForPrayer(
        Prayer.dhuhr,
        location,
      );

      final iqamahTarget = targets.singleWhere(
        (t) => t.kind == PrayerAlertKind.iqamah && t.prayer == Prayer.dhuhr,
      );

      expect(
        iqamahTarget.scheduledTime,
        adhanTime.add(const Duration(minutes: 20)),
      );
    });

    test('iqamah past next adhan drops windowEnd cutoff', () {
      final location = getLocation('Asia/Riyadh');
      final now = TZDateTime(location, 2026, 6, 9, 12);
      final snapshot = _buildSnapshot(now: now, location: location);
      final maghrib = snapshot.today.getTimesForPrayer(
        Prayer.maghrib,
        location,
      );
      final isha = snapshot.today.getTimesForPrayer(Prayer.isha, location);
      final gapMinutes = isha.difference(maghrib).inMinutes + 5;

      final targets = scheduledPrayerAlertTargets(
        snapshot: snapshot,
        prayerSettings: PrayerSettings.defaultSettings().copyWith(
          iqamahSettings: {Prayer.maghrib: gapMinutes},
        ),
      );

      final iqamahTarget = targets.singleWhere(
        (t) => t.kind == PrayerAlertKind.iqamah && t.prayer == Prayer.maghrib,
      );

      expect(iqamahTarget.windowEnd, isNull);
      expect(iqamahTarget.scheduledTime.isBefore(isha), isFalse);
    });

    test('skips iqamah when offset is zero or negative', () {
      final location = getLocation('Asia/Riyadh');
      final now = TZDateTime(location, 2026, 6, 9, 12);
      final snapshot = _buildSnapshot(now: now, location: location);
      final prayerSettings = PrayerSettings.defaultSettings().copyWith(
        iqamahSettings: {Prayer.dhuhr: 0, Prayer.asr: -5},
      );

      final targets = scheduledPrayerAlertTargets(
        snapshot: snapshot,
        prayerSettings: prayerSettings,
      );

      expect(
        targets.where((t) => t.kind == PrayerAlertKind.iqamah),
        isEmpty,
      );
    });
  });

  group('resolvePrayerAlertDelivery', () {
    const settings = AdhanSettings(
      adhanModes: {Prayer.fajr: ScheduleAlertMode.sound},
      showOsNotification: false,
    );

    test('off mode disables all channels', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.off,
        kind: PrayerAlertKind.adhan,
        settings: settings,
        prayer: Prayer.fajr,
      );

      expect(delivery.playSound, isFalse);
      expect(delivery.showInApp, isFalse);
      expect(delivery.showOsNotification, isFalse);
      expect(delivery.hasAnyEffect, isFalse);
    });

    test('sound mode plays audio for adhan', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.sound,
        kind: PrayerAlertKind.adhan,
        settings: settings,
        prayer: Prayer.fajr,
      );

      expect(delivery.playSound, isTrue);
      expect(delivery.showInApp, isTrue);
      expect(delivery.showOsNotification, isFalse);
      expect(delivery.soundAssetPath, isNotNull);
    });

    test('notifyOnly never plays sound', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.notifyOnly,
        kind: PrayerAlertKind.adhan,
        settings: settings,
        prayer: Prayer.fajr,
      );

      expect(delivery.playSound, isFalse);
      expect(delivery.showInApp, isTrue);
    });

    test('sunnah sound mode is notify-only at delivery layer', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.sound,
        kind: PrayerAlertKind.sunnah,
        settings: settings,
        prayer: Prayer.sunrise,
      );

      expect(delivery.playSound, isFalse);
    });

    test('showAdhanAlert false disables in-app channel', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.notifyOnly,
        kind: PrayerAlertKind.adhan,
        settings: settings.copyWith(showAdhanAlert: false),
        prayer: Prayer.fajr,
      );

      expect(delivery.showInApp, isFalse);
    });

    test('showOsNotification false disables OS channel', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.notifyOnly,
        kind: PrayerAlertKind.adhan,
        settings: settings.copyWith(showOsNotification: false),
        prayer: Prayer.fajr,
      );

      expect(delivery.showOsNotification, isFalse);
    });

    test('muteAll disables everything', () {
      final delivery = resolvePrayerAlertDelivery(
        mode: ScheduleAlertMode.sound,
        kind: PrayerAlertKind.adhan,
        settings: settings.copyWith(muteAll: true),
        prayer: Prayer.fajr,
      );

      expect(delivery.hasAnyEffect, isFalse);
    });
  });

  group('prayerAlertFireDedupeKey', () {
    test('includes kind and prayer', () {
      final location = getLocation('Asia/Riyadh');
      final key = prayerAlertFireDedupeKey(
        now: TZDateTime(location, 2026, 6, 9, 12),
        kind: PrayerAlertKind.iqamah,
        prayer: Prayer.dhuhr,
        location: location,
      );

      expect(key, '20260609-iqamah-dhuhr');
    });

    test('adhan dedupe key format', () {
      final location = getLocation('Asia/Riyadh');
      final key = prayerAlertFireDedupeKey(
        now: TZDateTime(location, 2026, 6, 9, 12),
        kind: PrayerAlertKind.adhan,
        prayer: Prayer.fajr,
        location: location,
      );

      expect(key, '20260609-adhan-fajr');
    });
  });
}
