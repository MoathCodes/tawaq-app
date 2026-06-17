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
  TrayMenuItem toTrayMenuItem(AppLocalizations l10n);

  /// Handles a click on this row.
  Future<void> handle(Ref ref);
}

/// Shows and focuses the main window.
final class TrayMenuShow extends TrayMenuEntry {
  /// Creates [TrayMenuShow].
  const TrayMenuShow();

  @override
  String get key => 'show';

  /// Builds the native tray menu item for [l10n] and [windowVisible].
  TrayMenuItem toTrayMenuItemWithVisibility(
    AppLocalizations l10n, {
    required bool windowVisible,
  }) => TrayMenuItem(
    key: key,
    label: windowVisible ? l10n.trayHideApp : l10n.trayShowApp,
  );

  @override
  TrayMenuItem toTrayMenuItem(AppLocalizations l10n) =>
      toTrayMenuItemWithVisibility(l10n, windowVisible: false);

  @override
  Future<void> handle(Ref ref) async {
    final controller = ref.read(desktopWindowControllerProvider);
    final visible = ref.read(desktopMainWindowVisibleProvider);
    if (visible) {
      await controller.hideMainWindow();
    } else {
      await controller.showMainWindow();
    }
  }
}

/// Toggles mute-all adhan playback.
final class TrayMenuMute extends TrayMenuEntry {
  /// Creates [TrayMenuMute].
  const TrayMenuMute();

  @override
  String get key => 'mute';

  /// Builds the native tray checkbox item for [l10n].
  TrayMenuItem toTrayMenuItemWithMute(
    AppLocalizations l10n, {
    required bool muteChecked,
  }) => TrayMenuItem.checkbox(
    key: key,
    label: l10n.trayMuteAdhan,
    checked: muteChecked,
  );

  @override
  TrayMenuItem toTrayMenuItem(AppLocalizations l10n) =>
      toTrayMenuItemWithMute(l10n, muteChecked: false);

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
  TrayMenuItem toTrayMenuItem(AppLocalizations l10n) =>
      TrayMenuItem.separator();

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
  TrayMenuItem toTrayMenuItem(AppLocalizations l10n) =>
      TrayMenuItem(key: key, label: l10n.trayQuit);

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
///
/// When [headerLabel] is non-empty, a disabled header row (e.g. the next
/// prayer) is shown at the top, followed by a separator. This is the only way
/// to surface prayer state on Linux, where the tray has no tooltip API.
TrayMenu buildTrayMenu({
  required AppLocalizations l10n,
  required bool muteChecked,
  required bool windowVisible,
  String? headerLabel,
}) => TrayMenu(
  items: [
    if (headerLabel != null && headerLabel.isNotEmpty) ...[
      TrayMenuItem(label: headerLabel, disabled: true),
      TrayMenuItem.separator(),
    ],
    for (final entry in trayMenuRegistry)
      switch (entry) {
        TrayMenuShow() => entry.toTrayMenuItemWithVisibility(
          l10n,
          windowVisible: windowVisible,
        ),
        TrayMenuMute() => entry.toTrayMenuItemWithMute(
          l10n,
          muteChecked: muteChecked,
        ),
        _ => entry.toTrayMenuItem(l10n),
      },
  ],
);
