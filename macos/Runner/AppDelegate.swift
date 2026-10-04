import Cocoa
import Darwin
import FlutterMacOS

// Shared by tray activation, application reopen, and startup visibility.
// Cocoa dispatches all three on its main thread.
final class DesktopActivation {
  static let shared = DesktopActivation()
  weak var window: NSWindow?
  private var pending = false
  private var bootstrapComplete = false

  func activate() {
    if !bootstrapComplete { pending = true }
    guard let window = window else { return }
    NSApp.unhide(nil)
    if window.isMiniaturized { window.deminiaturize(nil) }
    window.makeKeyAndOrderFront(nil)
    if #available(macOS 14.0, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  func completeBootstrap(launchHidden: Bool) {
    guard !bootstrapComplete else { return }
    bootstrapComplete = true
    if launchHidden && !pending {
      window?.orderOut(nil)
    } else {
      activate()
    }
    pending = false
  }
}

// Checked from awakeFromNib before any Flutter engine or storage is created.
// Keep the descriptor open for the process lifetime. Never unlink a live lock:
// a replacement inode would let a competing process acquire a second lock.
final class DesktopInstance {
  static let shared = DesktopInstance()
  private var lockFd: Int32 = -1

  func acquireOrActivate() {
    #if DEBUG
    return
    #else
    if lockFd >= 0 { return }
    let path = FileManager.default.temporaryDirectory
      .appendingPathComponent("me.moathdev.tawaq.lock").path
    let fd = open(path, O_CREAT | O_RDWR | O_NOFOLLOW, mode_t(0o600))
    guard fd >= 0 else {
      NSLog("Tawaq: cannot open instance lock (errno %d)", errno)
      exit(EXIT_FAILURE)
    }
    if flock(fd, LOCK_EX | LOCK_NB) == 0 {
      let pid = Array("\(getpid())\n".utf8)
      guard ftruncate(fd, 0) == 0,
            pid.withUnsafeBytes({ write(fd, $0.baseAddress, $0.count) }) == pid.count else {
        close(fd)
        exit(EXIT_FAILURE)
      }
      lockFd = fd
      return
    }
    let lockError = errno
    guard lockError == EWOULDBLOCK || lockError == EAGAIN else {
      close(fd)
      NSLog("Tawaq: cannot acquire instance lock (errno %d)", lockError)
      exit(EXIT_FAILURE)
    }
    // A simultaneous launch may contend before the owner has published its PID.
    for _ in 0..<100 {
      var bytes = [UInt8](repeating: 0, count: 32)
      let length = pread(fd, &bytes, bytes.count, 0)
      if length > 0,
         let pid = Int32(String(decoding: bytes.prefix(length), as: UTF8.self)
           .trimmingCharacters(in: .whitespacesAndNewlines)),
         let app = NSRunningApplication(processIdentifier: pid),
         app.bundleIdentifier == Bundle.main.bundleIdentifier,
         let url = app.bundleURL {
        app.unhide()
        // Reopen reaches AppDelegate, including while launch-to-tray hydrates.
        let opened = NSWorkspace.shared.open(url)
        close(fd)
        exit(opened ? EXIT_SUCCESS : EXIT_FAILURE)
      }
      usleep(10_000)
    }
    close(fd)
    NSLog("Tawaq: primary instance is not available for activation")
    exit(EXIT_FAILURE)
    #endif
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    DesktopActivation.shared.activate()
    return false
  }
}
