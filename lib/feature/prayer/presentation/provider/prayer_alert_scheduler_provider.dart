import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_dispatcher.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_resolver.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';

part 'prayer_alert_scheduler_provider.g.dart';

/// Keeps prayer alert scheduling alive for the desktop app lifetime.
@Riverpod(keepAlive: true)
void prayerAlertScheduler(Ref ref) {
  if (!isDesktopPlatform) return;

  var previousNow = DateTime.fromMillisecondsSinceEpoch(0);
  var bootstrapped = false;
  String? lastFiredKey;

  const crossingGrace = Duration(seconds: 2);

  ref
    ..listen(prayerDayProvider, (previous, next) {
      final snapshot = next.value;
      if (snapshot == null) return;

      final prayerSettings = ref.read(prayerSettingsProvider).value;
      final adhanSettings = ref.read(adhanSettingsProvider).value;
      if (prayerSettings == null || adhanSettings == null) return;
      if (adhanSettings.muteAll) return;

      final now = snapshot.now;

      if (!bootstrapped) {
        bootstrapped = true;
        previousNow = now;
        return;
      }

      final targets = scheduledPrayerAlertTargets(
        snapshot: snapshot,
        prayerSettings: prayerSettings,
      );

      for (final target in targets) {
        final mode = adhanSettingsModeFor(
          adhanSettings,
          target.kind,
          target.prayer,
        );
        if (mode == ScheduleAlertMode.off) continue;

        if (now.difference(target.scheduledTime) > crossingGrace) continue;

        if (!didCrossPrayerTime(
          previous: previousNow,
          now: now,
          target: target.scheduledTime,
        )) {
          continue;
        }

        final fireKey = prayerAlertFireDedupeKey(
          now: now,
          kind: target.kind,
          prayer: target.prayer,
        );
        if (lastFiredKey == fireKey) continue;
        lastFiredKey = fireKey;

        final delivery = resolvePrayerAlertDelivery(
          mode: mode,
          kind: target.kind,
          settings: adhanSettings,
          prayer: target.prayer,
        );

        unawaited(
          dispatchPrayerAlert(ref, target: target, delivery: delivery),
        );
      }

      previousNow = now;
    })
    ..listen(prayerSettingsProvider, (_, _) => lastFiredKey = null)
    ..listen(adhanSettingsProvider, (_, _) => lastFiredKey = null);
}
