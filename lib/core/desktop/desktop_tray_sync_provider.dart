import 'dart:async';

import 'package:flutter/material.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/desktop_tray_service.dart';
import 'package:tawaq/core/desktop/tray_menu.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'desktop_tray_sync_provider.g.dart';

/// Tray tooltip text; updates when next-prayer identity changes,
/// not on every clock tick.
@Riverpod(keepAlive: true)
String trayTooltipText(Ref ref) {
  final lang = ref.watch(localeProvider);
  final l10n = lookupAppLocalizations(Locale(lang));

  final current = ref.watch(scheduleCurrentPrayerProvider);
  if (current == null) return l10n.appName;

  final nextPrayer = scheduleNextPrayer(current);
  if (nextPrayer == null) return l10n.appName;

  return l10n.trayNextPrayer(nextPrayer.getLocaleName(l10n));
}

/// Keeps tray menu labels and tooltip in sync with app state.
@Riverpod(keepAlive: true)
void desktopTraySync(Ref ref) {
  if (!isDesktopPlatform) return;

  final service = ref.read(desktopTrayServiceProvider);

  Future<void> syncMenu() async {
    if (!service.isAvailable) return;
    final lang = ref.read(localeProvider);
    final l10n = lookupAppLocalizations(Locale(lang));
    final muteChecked = ref.read(adhanSettingsProvider).value?.muteAll ?? false;
    await service.applyMenu(
      buildTrayMenu(l10n: l10n, muteChecked: muteChecked),
    );
  }

  Future<void> syncTooltip() async {
    if (!service.isAvailable) return;
    await service.applyTooltip(ref.read(trayTooltipTextProvider));
  }

  ref
    ..listen(localeProvider, (_, _) => unawaited(syncMenu()))
    ..listen(adhanSettingsProvider, (_, _) => unawaited(syncMenu()))
    ..listen(trayTooltipTextProvider, (_, _) => unawaited(syncTooltip()));

  unawaited(() async {
    await service.ensureInitialized();
    await syncMenu();
    await syncTooltip();
  }());
}
