# Changelog

## 2026.4.19

### Fixed

- **Windows**: tray icon now shows up when set from non-`.ico` assets. The
  Win32 `LoadImage` API only decodes `.ico`; passing a `.png` used to return
  `NULL` and `Shell_NotifyIcon` still registered an empty clickable slot
  ("button works, icon invisible"). The plugin now falls back to GDI+ and
  supports `.png` / `.jpg` / `.bmp` / `.gif`. If decoding fails, the native
  side no longer registers an empty tray slot — it throws a
  `PlatformException` with code `ICON_LOAD_FAILED` instead.

### Added

- Comprehensive `example/` app demonstrating every public API, every
  `TrayMenuItem` type, live icon/tooltip/checkbox updates, `checkAvailable`,
  `popUpContextMenu`, `destroy` + rebuild, and a real-time event log.
- Documented `checkAvailable()` in the README API tables.

## 2026.4.8

-- fix `windows` warning

## 2026.4.4

### Added

- **System tray icon** management via `setIcon()` for Windows (`.ico`), macOS (`.png` via base64), and Linux (`.png` with AppIndicator icon theme path).
- **Tooltip** support via `setToolTip()` (no-op on Linux where AppIndicator has no tooltip API).
- **Context menu** builder with four item types:
  - `TrayMenuItem` — normal clickable item
  - `TrayMenuItem.separator()` — visual divider
  - `TrayMenuItem.checkbox()` — toggle item with checked state
  - `TrayMenuItem.submenu()` — nested sub-menu with child items
- **Auto-incremented IDs** for menu items — no external ID generator needed.
- **Event listener** mixin (`DesktopTrayListener`) for:
  - Left / right mouse button press and release on the tray icon
  - Menu item click with automatic ID → `TrayMenuItem` resolution
- **TrayMenu** utility class with `findByKey()` and `findById()` lookups.
- **Linux crash prevention**: deferred `GtkMenuItem` destruction via `g_idle_add()` to avoid libdbusmenu heap corruption.
- **Sandbox detection** for Flatpak, Snap, Docker, and Podman environments.

