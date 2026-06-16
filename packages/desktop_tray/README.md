# desktop_tray

A lightweight Flutter plugin for managing **system tray** icons and context menus on desktop platforms (Windows, macOS, Linux).

Built with zero third-party Dart dependencies — only native platform APIs:

| Platform    | Backend                                             |
|-------------|-----------------------------------------------------|
| **Linux**   | libayatana-appindicator (or legacy libappindicator)  |
| **macOS**   | NSStatusBar + NSMenu                                |
| **Windows** | Win32 Shell_NotifyIcon + GDI+ (PNG/JPG/BMP/ICO)     |

> 🇨🇳 [中文文档](README_ZH.md)

## Features

- 🖨️ Set a tray icon from Flutter asset paths (`.png` / `.jpg` / `.bmp` / `.ico`)
- 💬 Set a hover tooltip (supported on Windows and macOS)
- 📋 Build context menus with normal items, separators, checkboxes, and nested submenus
- 🖱️ Receive left-click, right-click, and menu-item-click callbacks via a listener mixin
- 🧩 Unique auto-incremented item IDs — no external ID generators needed
- 🔍 `checkAvailable()` probes the Linux StatusNotifierWatcher before use

## Getting Started

### Installation

Add the package as a path dependency in your app's `pubspec.yaml`:

```yaml
dependencies:
  desktop_tray:
    path: packages/desktop_tray
```

### Linux System Dependencies

The Linux implementation requires `libayatana-appindicator3` (preferred) or `libappindicator3`:

```bash
# Ubuntu / Debian
sudo apt install libayatana-appindicator3-dev

# Fedora
sudo dnf install libayatana-appindicator-gtk3-devel

# Arch
sudo pacman -S libayatana-appindicator
```

## Usage

### Basic Setup

```dart
import 'package:desktop_tray/desktop_tray.dart';

// 1. Set the tray icon
await desktopTray.setIcon('assets/logo/logo.png');

// 2. Set a tooltip
await desktopTray.setToolTip('My App');

// 3. Build a context menu
final menu = TrayMenu(items: [
  TrayMenuItem(key: 'show', label: 'Show Window'),
  TrayMenuItem.separator(),
  TrayMenuItem(key: 'exit', label: 'Exit'),
]);
await desktopTray.setContextMenu(menu);
```

### Listening to Events

Implement `DesktopTrayListener` and register it:

```dart
class MyTrayHandler with DesktopTrayListener {
  MyTrayHandler() {
    desktopTray.addListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    // Left-click on tray icon
  }

  @override
  void onTrayMenuItemClick(TrayMenuItem item) {
    switch (item.key) {
      case 'show':
        // show window
        break;
      case 'exit':
        // exit app
        break;
    }
  }
}
```

### Menu Item Types

```dart
// Normal item
TrayMenuItem(key: 'action', label: 'Do Something')

// Separator
TrayMenuItem.separator()

// Checkbox
TrayMenuItem.checkbox(key: 'mute', label: 'Mute', checked: true)

// Submenu
TrayMenuItem.submenu(
  key: 'more',
  label: 'More Options',
  children: [
    TrayMenuItem(key: 'option_a', label: 'Option A'),
    TrayMenuItem(key: 'option_b', label: 'Option B'),
  ],
)
```

### Cleanup

```dart
desktopTray.removeListener(this);
await desktopTray.destroy();
```

## API Reference

### `DesktopTray` (singleton via `desktopTray`)

| Method                                | Description                                             |
|---------------------------------------|---------------------------------------------------------|
| `checkAvailable()`                    | Probe the tray backend (Linux-only; `true` elsewhere)   |
| `setIcon(String assetPath)`           | Set tray icon from a Flutter asset path                 |
| `setToolTip(String toolTip)`          | Set hover tooltip text (no-op on Linux)                 |
| `setContextMenu(TrayMenu menu)`       | Replace the right-click context menu                    |
| `popUpContextMenu()`                  | Programmatically open the context menu (no-op on Linux) |
| `destroy()`                           | Remove the tray icon and release native resources       |
| `addListener(DesktopTrayListener)`    | Register an event listener                              |
| `removeListener(DesktopTrayListener)` | Unregister an event listener                            |

### `DesktopTrayListener` (mixin)

| Callback                            | Trigger                                  |
|-------------------------------------|------------------------------------------|
| `onTrayIconMouseDown()`             | Left mouse button pressed on tray icon   |
| `onTrayIconMouseUp()`               | Left mouse button released on tray icon  |
| `onTrayIconRightMouseDown()`        | Right mouse button pressed on tray icon  |
| `onTrayIconRightMouseUp()`          | Right mouse button released on tray icon |
| `onTrayMenuItemClick(TrayMenuItem)` | A context menu item was clicked          |

## Platform Notes

- **Linux**: AppIndicator always shows the context menu on left-click. `popUpContextMenu()` is a no-op. Tooltip is not supported by the AppIndicator API. The deprecation warning from newer versions of libayatana-appindicator is silently suppressed.
- **macOS**: Icon data is sent as base64 to the native layer for `NSImage` construction.
- **Windows**: `.ico`, `.png`, `.jpg`, `.bmp`, and `.gif` are all supported. `.ico` is loaded via `LoadImage`; other formats are decoded by GDI+ and scaled to the system small-icon size. If the file cannot be decoded the plugin throws a `PlatformException` with code `ICON_LOAD_FAILED` instead of registering an empty tray slot.

## Running the Example

A complete demo covering every public API lives in [`example/`](example). See [example/README.md](example/README.md) for icon-asset setup and run instructions.

## License

See [LICENSE](LICENSE).
