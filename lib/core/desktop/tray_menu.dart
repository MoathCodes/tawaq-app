import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/desktop/desktop_window_controller.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// One row in the tray context menu.
sealed class TrayMenuEntry {
  /// Creates [TrayMenuEntry].
  const TrayMenuEntry();

  /// Non-null for clickable rows; used as native menu item key.
  String? get key;

  /// Builds the native tray menu item for [l10n].
  TrayMenuItem toTrayMenuItem(
    AppLocalizations l10n, {
    required bool muteChecked,
  });

  /// Handles a click on this row.
  Future<void> handle(Ref ref);
}

/// Shows and focuses the main window.
final class TrayMenuShow extends TrayMenuEntry {
  /// Creates [TrayMenuShow].
  const TrayMenuShow();

  @override
  String get key => 'show';

  @override
  TrayMenuItem toTrayMenuItem(
    AppLocalizations l10n, {
    required bool muteChecked,
  }) => TrayMenuItem(key: key, label: l10n.trayShowApp);

  @override
  Future<void> handle(Ref ref) =>
      ref.read(desktopWindowControllerProvider).showMainWindow();
}

/// Toggles mute-all adhan playback.
final class TrayMenuMute extends TrayMenuEntry {
  /// Creates [TrayMenuMute].
  const TrayMenuMute();

  @override
  String get key => 'mute';

  @override
  TrayMenuItem toTrayMenuItem(
    AppLocalizations l10n, {
    required bool muteChecked,
  }) => TrayMenuItem.checkbox(
    key: key,
    label: l10n.trayMuteAdhan,
    checked: muteChecked,
  );

  @override
  Future<void> handle(Ref ref) async {
    final notifier = ref.read(adhanSettingsProvider.notifier);
    final current = ref.read(adhanSettingsProvider).value?.muteAll ?? false;
    notifier.setMuteAll(value: !current);
  }
}

/// Visual separator between menu sections.
final class TrayMenuSeparator extends TrayMenuEntry {
  /// Creates [TrayMenuSeparator].
  const TrayMenuSeparator();

  @override
  String? get key => null;

  @override
  TrayMenuItem toTrayMenuItem(
    AppLocalizations l10n, {
    required bool muteChecked,
  }) => TrayMenuItem.separator();

  @override
  Future<void> handle(Ref ref) async {}
}

/// Quits the application.
final class TrayMenuQuit extends TrayMenuEntry {
  /// Creates [TrayMenuQuit].
  const TrayMenuQuit();

  @override
  String get key => 'quit';

  @override
  TrayMenuItem toTrayMenuItem(
    AppLocalizations l10n, {
    required bool muteChecked,
  }) => TrayMenuItem(key: key, label: l10n.trayQuit);

  @override
  Future<void> handle(Ref ref) async {
    // Handled in [DesktopTrayService.onTrayMenuItemClick] to avoid reading
    // [desktopTrayServiceProvider] from that provider's own Ref.
  }
}

/// Ordered tray context menu rows.
const trayMenuRegistry = <TrayMenuEntry>[
  TrayMenuShow(),
  TrayMenuMute(),
  TrayMenuSeparator(),
  TrayMenuQuit(),
];

/// Lookup from native menu item key to [TrayMenuEntry].
final Map<String, TrayMenuEntry> trayMenuEntryByKey = {
  for (final entry in trayMenuRegistry) ?entry.key: entry,
};

/// Builds the native tray context menu for [l10n].
TrayMenu buildTrayMenu({
  required AppLocalizations l10n,
  required bool muteChecked,
}) => TrayMenu(
  items: [
    for (final entry in trayMenuRegistry)
      entry.toTrayMenuItem(l10n, muteChecked: muteChecked),
  ],
);
