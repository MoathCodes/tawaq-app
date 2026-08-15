import 'dart:async';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/desktop/desktop_tray_service.dart';
import 'package:tawaq/core/desktop/window_state_provider.dart';
import 'package:tawaq/core/desktop/tray_menu.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/presentation/provider/date_formatter.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'desktop_tray_sync_provider.g.dart';

/// Tray tooltip / menu header text.
///
/// Minute-resolution next-adhan glance, or an “adhan playing” label while an
/// alert is in flight. Falls back to the app name when prayer day is unknown.
@Riverpod(keepAlive: true)
String trayTooltipText(Ref ref) {
  final lang = ref.watch(localeProvider).value ?? 'en';
  final l10n = lookupAppLocalizations(Locale(lang));

  final activePrayer = ref.watch(prayerAlertSessionStateProvider)?.event.prayer;
  if (activePrayer != null) {
    return l10n.adhanPlayingTitle(activePrayer.getLocaleName(l10n));
  }

  // Watch only calendar/minute identity; read the full snapshot non-reactively.
  ref.watch(
    prayerDayProvider.select((value) {
      final day = value.value;
      if (day == null) return null;
      return (day.calendarDayKey, day.now.hour, day.now.minute);
    }),
  );
  final day = ref.read(prayerDayProvider).value;
  if (day == null) return l10n.appName;

  final glance = resolveNextAdhanGlance(day);
  if (glance == null) return l10n.appName;

  final formatter = ref.watch(timeFormatterProvider);
  final timeLabel = formatter.format(glance.adhanTime);
  final remaining = formatTrayRemaining(glance.adhanTime.difference(day.now));
  return l10n.trayNextPrayerStatus(
    glance.prayer.getLocaleName(l10n),
    timeLabel,
    remaining,
  );
}

/// Keeps tray menu labels and tooltip in sync with app state.
@Riverpod(keepAlive: true)
void desktopTraySync(Ref ref) {
  if (!isDesktopPlatform) return;

  final service = ref.read(desktopTrayServiceProvider);

  Future<void> syncMenu() async {
    if (!service.isAvailable) return;
    final lang = ref.read(localeProvider).value ?? 'en';
    final l10n = lookupAppLocalizations(Locale(lang));
    final windowVisible =
        ref.read(nativeWindowStateProvider).value?.visible ?? true;
    final alertActive = ref.read(prayerAlertSessionStateProvider) != null;
    // Surface next prayer as a header row (the only prayer hint on Linux, which
    // has no tray tooltip). Suppress when there is nothing but the app name.
    final tooltip = ref.read(trayTooltipTextProvider);
    final header = tooltip == l10n.appName ? null : tooltip;
    await service.applyMenu(
      buildTrayMenu(
        l10n: l10n,
        windowVisible: windowVisible,
        alertActive: alertActive,
        headerLabel: header,
      ),
    );
  }

  Future<void> syncTooltip() async {
    if (!service.isAvailable) return;
    await service.applyTooltip(ref.read(trayTooltipTextProvider));
  }

  ref
    ..listen(localeProvider, (_, _) => unawaited(syncMenu()))
    ..listen(nativeWindowStateProvider, (_, _) => unawaited(syncMenu()))
    ..listen(prayerAlertSessionStateProvider, (_, _) {
      unawaited(syncMenu());
      unawaited(syncTooltip());
    })
    // Status text changes (~1×/min, prayer identity, or alert) refresh both.
    ..listen(trayTooltipTextProvider, (_, _) {
      unawaited(syncMenu());
      unawaited(syncTooltip());
    });

  unawaited(() async {
    await service.ensureInitialized();
    await syncMenu();
    await syncTooltip();
  }());
}
