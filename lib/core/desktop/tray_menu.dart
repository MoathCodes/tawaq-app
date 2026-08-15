import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/desktop/desktop_window_controller.dart';
import 'package:tawaq/core/desktop/window_state_provider.dart';
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
    final visible = ref.read(nativeWindowStateProvider).value?.visible ?? true;
    if (visible) {
      await controller.hideMainWindow();
    } else {
      await controller.showMainWindow();
    }
  }
}

/// Stops the in-flight prayer alert (sound, overlay, OS notification).
final class TrayMenuStop extends TrayMenuEntry {
  /// Creates [TrayMenuStop].
  const TrayMenuStop();

  @override
  String get key => 'stop';

  @override
  TrayMenuItem toTrayMenuItem(AppLocalizations l10n) =>
      TrayMenuItem(key: key, label: l10n.trayStopAdhan);

  @override
  Future<void> handle(Ref ref) async {
    await ref.read(prayerAlertDispatcherProvider.notifier).dismiss();
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

/// Ordered tray context menu rows (Stop is inserted dynamically when active).
const trayMenuRegistry = <TrayMenuEntry>[
  TrayMenuShow(),
  TrayMenuSeparator(),
  TrayMenuQuit(),
];

/// Lookup from native menu item key to [TrayMenuEntry].
final Map<String, TrayMenuEntry> trayMenuEntryByKey = {
  for (final entry in trayMenuRegistry) ?entry.key: entry,
  'stop': const TrayMenuStop(),
};

/// Builds the native tray context menu for [l10n].
///
/// When [headerLabel] is non-empty, a disabled header row (e.g. the next
/// prayer) is shown at the top, followed by a separator. This is the only way
/// to surface prayer state on Linux, where the tray has no tooltip API.
///
/// When [alertActive] is true, a Stop row is inserted above Show.
TrayMenu buildTrayMenu({
  required AppLocalizations l10n,
  required bool windowVisible,
  required bool alertActive,
  String? headerLabel,
}) => TrayMenu(
  items: [
    if (headerLabel != null && headerLabel.isNotEmpty) ...[
      TrayMenuItem(label: headerLabel, disabled: true),
      TrayMenuItem.separator(),
    ],
    if (alertActive) const TrayMenuStop().toTrayMenuItem(l10n),
    for (final entry in trayMenuRegistry)
      switch (entry) {
        TrayMenuShow() => entry.toTrayMenuItemWithVisibility(
          l10n,
          windowVisible: windowVisible,
        ),
        _ => entry.toTrayMenuItem(l10n),
      },
  ],
);
