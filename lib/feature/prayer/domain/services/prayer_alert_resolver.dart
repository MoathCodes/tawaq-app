import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';

/// A schedulable prayer alert event.
class PrayerAlertTarget {
  /// Creates [PrayerAlertTarget].
  const PrayerAlertTarget({
    required this.kind,
    required this.prayer,
    required this.scheduledTime,
    this.windowEnd,
  });

  /// Alert category.
  final PrayerAlertKind kind;

  /// Prayer this alert belongs to.
  final Prayer prayer;

  /// Local scheduled time for the event.
  final DateTime scheduledTime;

  /// Onset of the next obligatory prayer, past which a late catch-up of this
  /// alert is stale and must be dropped (so maghrib is never announced once
  /// isha has begun). Null when there is no near boundary — the day's last
  /// prayer (isha) and sunnah alerts — leaving only the flat catch-up window.
  final DateTime? windowEnd;
}

/// Resolved delivery channels for a fired alert.
class PrayerAlertDelivery {
  /// Creates [PrayerAlertDelivery].
  const PrayerAlertDelivery({
    required this.playSound,
    required this.showInApp,
    required this.showOsNotification,
    this.soundAssetPath,
  });

  /// Whether bundled audio should play.
  final bool playSound;

  /// Whether the in-app overlay / compact morph should show.
  final bool showInApp;

  /// Whether an OS notification should show.
  final bool showOsNotification;

  /// Asset path when [playSound] is true.
  final String? soundAssetPath;

  /// Whether any channel is active.
  bool get hasAnyEffect => playSound || showInApp || showOsNotification;
}

/// Builds all watchable alert targets for [snapshot] and [prayerSettings].
List<PrayerAlertTarget> scheduledPrayerAlertTargets({
  required PrayerDaySnapshot snapshot,
  required PrayerSettings prayerSettings,
}) {
  final targets = <PrayerAlertTarget>[];
  final location = snapshot.location;
  final adhanTimes = adjustedAdhanTimesForDay(
    times: snapshot.today,
    location: location,
    adjustments: prayerSettings.adhanAdjustments,
  );

  for (var i = 0; i < obligatoryAlertPrayers.length; i++) {
    final prayer = obligatoryAlertPrayers[i];
    // Cap the catch-up at the next obligatory prayer's onset; isha (the last)
    // has no same-day boundary, so it relies on the flat window only.
    final windowEnd = i + 1 < obligatoryAlertPrayers.length
        ? adhanTimes[obligatoryAlertPrayers[i + 1]]
        : null;

    targets.add(
      PrayerAlertTarget(
        kind: PrayerAlertKind.adhan,
        prayer: prayer,
        scheduledTime: adhanTimes[prayer]!,
        windowEnd: windowEnd,
      ),
    );

    final iqamahMinutes = prayerSettings.iqamahSettings[prayer] ?? 0;
    if (iqamahMinutes > 0) {
      targets.add(
        PrayerAlertTarget(
          kind: PrayerAlertKind.iqamah,
          prayer: prayer,
          scheduledTime: adhanTimes[prayer]!.add(
            Duration(minutes: iqamahMinutes),
          ),
          windowEnd: windowEnd,
        ),
      );
    }
  }

  for (final prayer in sunnahAlertPrayers) {
    targets.add(
      PrayerAlertTarget(
        kind: PrayerAlertKind.sunnah,
        prayer: prayer,
        scheduledTime: resolveSunnahTime(
          prayer: prayer,
          snapshot: snapshot,
        ),
      ),
    );
  }

  return targets;
}

/// Resolves which delivery channels to use for [mode] and [kind].
PrayerAlertDelivery resolvePrayerAlertDelivery({
  required ScheduleAlertMode mode,
  required PrayerAlertKind kind,
  required AdhanSettings settings,
  required Prayer prayer,
}) {
  if (mode == ScheduleAlertMode.off || settings.muteAll) {
    return const PrayerAlertDelivery(
      playSound: false,
      showInApp: false,
      showOsNotification: false,
    );
  }

  final playSound =
      mode == ScheduleAlertMode.sound && kind != PrayerAlertKind.sunnah;
  final soundAssetPath = playSound
      ? switch (kind) {
          PrayerAlertKind.adhan => settings.sound.assetPathFor(prayer),
          PrayerAlertKind.iqamah => settings.iqamahSound.assetPathFor(prayer),
          PrayerAlertKind.sunnah => null,
        }
      : null;

  return PrayerAlertDelivery(
    playSound: playSound,
    showInApp: settings.showAdhanAlert,
    showOsNotification: settings.showOsNotification,
    soundAssetPath: soundAssetPath,
  );
}

/// Dedupe key for a fired alert.
String prayerAlertFireDedupeKey({
  required DateTime now,
  required PrayerAlertKind kind,
  required Prayer prayer,
}) {
  return '${calendarDayKeyFromDate(now)}-${kind.name}-${prayer.name}';
}
