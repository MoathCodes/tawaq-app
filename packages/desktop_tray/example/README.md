# desktop_tray example

A full-featured demo covering every public API of the `desktop_tray` plugin.

## 1. Add your icon assets

Create the folder `example/assets/icons/` and drop in the following files:

| File                         | Used on                                             |
|------------------------------|-----------------------------------------------------|
| `assets/icons/logo.png`      | macOS / Linux, and Windows (via GDI+)               |
| `assets/icons/logo.ico`      | Windows (sharpest rendering, optional)              |
| `assets/icons/alt.png`       | Used by the demo to show live icon switching        |

> Any square 32×32 or 64×64 PNG works fine. The example will still build
> without these files, but `setIcon` will fail at runtime.

## 2. Run it

```bash
cd example
flutter pub get
flutter run -d windows     # or: macos / linux
```

## 3. What the demo shows

- `DesktopTray.checkAvailable()` — detects `StatusNotifierWatcher` on Linux.
- `setIcon(...)` — chip row lets you switch between PNG / ICO assets live.
- `setToolTip(...)` — text field + apply button.
- `setContextMenu(...)` — the menu contains every item type:
  normal, separator, checkbox (x2, state reflected in the UI and rebuilt
  on each toggle), two-level submenus, and a disabled item.
- `popUpContextMenu()` — button triggers the menu programmatically.
- `destroy()` / recreate — tears the tray down and rebuilds it.
- Every `DesktopTrayListener` callback writes to the on-screen event log
  with a timestamp.
