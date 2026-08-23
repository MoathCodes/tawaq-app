import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:timezone/timezone.dart';

/// A schedulable prayer alert event.
class PrayerAlertTarget {
  /// Creates [PrayerAlertTarget].
  const new({
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
  /// prayer (isha), sunnah alerts, or iqamah scheduled at/after the next
  /// obligatory onset — leaving only the flat catch-up window.
  final DateTime? windowEnd;
}

/// Resolved delivery channels for a fired alert.
class PrayerAlertDelivery {
  /// Creates [PrayerAlertDelivery].
  const new({
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
///
/// Adhan times come from the already-adjusted day bundle/timeline; do not
/// re-apply adhan adjustments here.
List<PrayerAlertTarget> scheduledPrayerAlertTargets({
  required PrayerDaySnapshot snapshot,
  required PrayerSettings prayerSettings,
}) {
  final targets = <PrayerAlertTarget>[];
  final location = snapshot.location;

  DateTime adhanTime(Prayer prayer) =>
      snapshot.today.getTimesForPrayer(prayer, location);

  for (var i = 0; i < obligatoryAlertPrayers.length; i++) {
    final prayer = obligatoryAlertPrayers[i];
    final scheduled = adhanTime(prayer);
    // Cap the catch-up at the next obligatory prayer's onset; isha (the last)
    // has no same-day boundary, so it relies on the flat window only.
    final nextAdhan = i + 1 < obligatoryAlertPrayers.length
        ? adhanTime(obligatoryAlertPrayers[i + 1])
        : null;

    targets.add(
      PrayerAlertTarget(
        kind: PrayerAlertKind.adhan,
        prayer: prayer,
        scheduledTime: scheduled,
        windowEnd: nextAdhan,
      ),
    );

    final iqamahMinutes = prayerSettings.iqamahSettings[prayer] ?? 0;
    if (iqamahMinutes > 0) {
      final iqamahTime = scheduled.add(Duration(minutes: iqamahMinutes));
      // If iqamah falls at/after the next obligatory onset, drop the next-adhan
      // cutoff so the flat catch-up window can still deliver it.
      final iqamahWindowEnd =
          nextAdhan != null && iqamahTime.isBefore(nextAdhan)
          ? nextAdhan
          : null;
      targets.add(
        PrayerAlertTarget(
          kind: PrayerAlertKind.iqamah,
          prayer: prayer,
          scheduledTime: iqamahTime,
          windowEnd: iqamahWindowEnd,
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

/// Dedupe key for a fired alert on [now]'s calendar day in [location].
String prayerAlertFireDedupeKey({
  required DateTime now,
  required PrayerAlertKind kind,
  required Prayer prayer,
  required Location location,
}) {
  return '${completionDayKey(now, location)}-${kind.name}-${prayer.name}';
}
