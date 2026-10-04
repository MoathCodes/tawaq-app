import Cocoa
import FlutterMacOS
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  private func activationWindow() -> (DesktopActivation, NSWindow) {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    let activation = DesktopActivation()
    activation.window = window
    addTeardownBlock { window.orderOut(nil) }
    return (activation, window)
  }

  func testLaunchToTrayWithoutReopenHidesWindow() {
    let (activation, window) = activationWindow()
    window.orderFront(nil)
    activation.completeBootstrap(launchHidden: true)
    XCTAssertFalse(window.isVisible)
  }

  func testReopenDuringStartupOverridesLaunchToTray() {
    let (activation, window) = activationWindow()
    activation.activate()
    activation.completeBootstrap(launchHidden: true)
    XCTAssertTrue(window.isVisible)
  }

  func testReopenBeforeWindowCreationSurvivesBootstrap() {
    let (activation, window) = activationWindow()
    activation.window = nil
    activation.activate()
    activation.window = window
    activation.completeBootstrap(launchHidden: true)
    XCTAssertTrue(window.isVisible)
  }

  func testRepeatedActivationRestoresHiddenWindowAndKeepsItVisible() {
    let (activation, window) = activationWindow()
    activation.completeBootstrap(launchHidden: true)
    activation.activate()
    activation.activate()
    XCTAssertTrue(window.isVisible)
    // A repeated bootstrap call cannot hide a reactivated window.
    activation.completeBootstrap(launchHidden: true)
    XCTAssertTrue(window.isVisible)
  }

  func testMinimizedWindowIsRestored() {
    let (activation, window) = activationWindow()
    window.orderFront(nil)
    window.miniaturize(nil)
    activation.activate()
    XCTAssertFalse(window.isMiniaturized)
    XCTAssertTrue(window.isVisible)
  }
}
