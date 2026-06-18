import 'dart:async';

import 'package:flutter/material.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_resolver.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'prayer_alert_scheduler_provider.g.dart';

/// Keeps prayer alert scheduling alive for the desktop app lifetime.
///
/// Watches the 1 Hz [prayerDayProvider] clock and fires an alert when the tick
/// crosses a scheduled time. The day's alert targets are memoized so the
/// per-second tick only re-checks cached times instead of recomputing them.
@Riverpod(keepAlive: true)
void prayerAlertScheduler(Ref ref) {
  if (!isDesktopPlatform) return;

  final log = ref.read(loggerProvider);

  var previousNow = DateTime.fromMillisecondsSinceEpoch(0);
  var bootstrapped = false;

  // Per-day dedupe: a fired alert is remembered until the calendar day rolls
  // over, so re-evaluation (or a settings change) never re-fires it.
  var firedDayKey = 0;
  final firedKeys = <String>{};

  // Memoized targets for the current (day, prayer settings) pair.
  int? cachedDayKey;
  PrayerSettings? cachedSettings;
  var cachedTargets = <PrayerAlertTarget>[];

  
  ref.listen(prayerDayProvider, (previous, next) {
    final snapshot = next.value;
    if (snapshot == null) return;

    final now = snapshot.now;
    final dayKey = snapshot.calendarDayKey;

    if (firedDayKey != dayKey) {
      firedDayKey = dayKey;
      firedKeys.clear();
    }

    // Advance the tick reference on every tick, before any early return below.
    // A frozen `previousNow` (e.g. while muted, or during a transient null
    // settings tick) would corrupt the catch-up window — it could drop a
    // genuinely-due alert or, on unmute, fire a crossing that happened while
    // muted. `lastNow` keeps the real previous tick for the crossing check.
    final lastNow = previousNow;
    previousNow = now;

    if (!bootstrapped) {
      bootstrapped = true;
      return;
    }

    final prayerSettings = ref.read(prayerSettingsProvider).value;
    final adhanSettings = ref.read(adhanSettingsProvider).value;
    if (prayerSettings == null || adhanSettings == null) return;
    if (adhanSettings.muteAll) return;

    // (0,0) is the "no location set" sentinel: its prayer times are computed
    // for null island and would fire hours off. Never alert from it.
    final coords = prayerSettings.coordinates;
    if (coords.latitude == 0 && coords.longitude == 0) {
      log.w(
        'prayerAlertScheduler: skipping — coordinates are (0,0); '
        'location not set, prayer times would be wrong',
      );
      return;
    }

    if (cachedDayKey != dayKey || cachedSettings != prayerSettings) {
      cachedDayKey = dayKey;
      cachedSettings = prayerSettings;
      cachedTargets = scheduledPrayerAlertTargets(
        snapshot: snapshot,
        prayerSettings: prayerSettings,
      );
      final summary = cachedTargets
          .map(
            (t) =>
                '${t.kind.name}/${t.prayer.name}@${t.scheduledTime}'
                '${t.windowEnd != null ? '(cutoff ${t.windowEnd})' : ''}',
          )
          .join(', ');
      log.i(
        'prayerAlertScheduler: targets day=$dayKey now=$now '
        'coords=(${coords.latitude},${coords.longitude}) :: $summary',
      );
    }

    final catchUpWindow = Duration(minutes: adhanSettings.catchUpWindowMinutes);

    for (final target in cachedTargets) {
      final mode = adhanSettingsModeFor(
        adhanSettings,
        target.kind,
        target.prayer,
      );
      if (mode == ScheduleAlertMode.off) continue;

      if (!didCrossPrayerTime(
        previous: lastNow,
        now: now,
        target: target.scheduledTime,
        window: catchUpWindow,
        cutoff: target.windowEnd,
      )) {
        continue;
      }

      final fireKey = prayerAlertFireDedupeKey(
        now: now,
        kind: target.kind,
        prayer: target.prayer,
      );
      if (!firedKeys.add(fireKey)) continue;

      final delivery = resolvePrayerAlertDelivery(
        mode: mode,
        kind: target.kind,
        settings: adhanSettings,
        prayer: target.prayer,
      );
      if (!delivery.hasAnyEffect) continue;

      log.i(
        'prayerAlertScheduler: FIRE ${target.kind.name}/${target.prayer.name} '
        'scheduled=${target.scheduledTime} now=$now lastNow=$lastNow '
        'lateBy=${now.difference(target.scheduledTime).inSeconds}s '
        'window=${catchUpWindow.inMinutes}min cutoff=${target.windowEnd}',
      );

      final event = _buildPrayerAlertEvent(
        target: target,
        delivery: delivery,
        settings: adhanSettings,
        l10n: lookupAppLocalizations(Locale(ref.read(localeProvider))),
      );

      // The dispatcher serializes deliveries, so firing several crossings in
      // the same tick is safe — they queue rather than interleave.
      unawaited(
        ref.read(prayerAlertDispatcherProvider.notifier).dispatch(event),
      );
    }
  });
}

/// Resolves the localized strings for [target] once, at fire time.
PrayerAlertEvent _buildPrayerAlertEvent({
  required PrayerAlertTarget target,
  required PrayerAlertDelivery delivery,
  required AdhanSettings settings,
  required AppLocalizations l10n,
}) {
  final prayerName = target.prayer.getLocaleName(l10n);

  final soundTitle = switch (target.kind) {
    PrayerAlertKind.adhan => l10n.adhanPlayingTitle(prayerName),
    PrayerAlertKind.iqamah => l10n.iqamahPlayingTitle(prayerName),
    PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
  };
  final osTitle = switch (target.kind) {
    PrayerAlertKind.adhan => l10n.adhanAlertTitle(prayerName),
    PrayerAlertKind.iqamah => l10n.iqamahAlertTitle(prayerName),
    PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
  };
  final osBody = switch (target.kind) {
    PrayerAlertKind.adhan => l10n.adhanOsNotificationBody,
    PrayerAlertKind.iqamah => l10n.iqamahOsNotificationBody,
    PrayerAlertKind.sunnah => l10n.sunnahOsNotificationBody,
  };

  return PrayerAlertEvent(
    kind: target.kind,
    prayer: target.prayer,
    scheduledTime: target.scheduledTime,
    playSound: delivery.playSound,
    showInApp: delivery.showInApp,
    showOsNotification: delivery.showOsNotification,
    volume: settings.volume,
    soundAssetPath: delivery.soundAssetPath,
    soundTitle: soundTitle,
    soundSubtitle: prayerName,
    osTitle: osTitle,
    osBody: osBody,
  );
}
