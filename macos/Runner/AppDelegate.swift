import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    // flutter_alone activates via NSWorkspace.open → this reopen path.
    // Restore tray-hidden and Dock-minimized windows, then request activation
    // so a visible window on another Space is brought forward when allowed.
    for window in sender.windows {
      if window.isMiniaturized {
        window.deminiaturize(self)
      }
      window.makeKeyAndOrderFront(self)
    }
    if #available(macOS 14.0, *) {
      sender.activate()
    } else {
      sender.activate(ignoringOtherApps: false)
    }
    return false
  }
}
