import Cocoa
import FlutterMacOS

// ---------------------------------------------------------------------------
// desktop_tray – macOS native implementation
// ---------------------------------------------------------------------------

private let kOnTrayIconMouseDown      = "onTrayIconMouseDown"
private let kOnTrayIconMouseUp        = "onTrayIconMouseUp"
private let kOnTrayIconRightMouseDown = "onTrayIconRightMouseDown"
private let kOnTrayIconRightMouseUp   = "onTrayIconRightMouseUp"
private let kOnTrayMenuItemClick      = "onTrayMenuItemClick"

public class DesktopTrayPlugin: NSObject, FlutterPlugin, NSMenuDelegate {
    var channel: FlutterMethodChannel!
    var trayIcon: DesktopTrayIcon?
    var trayMenu: DesktopTrayMenu?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "desktop_tray",
            binaryMessenger: registrar.messenger)
        let instance = DesktopTrayPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "destroy":
            destroy(result: result)
        case "setIcon":
            setIcon(call, result: result)
        case "setToolTip":
            setToolTip(call, result: result)
        case "setContextMenu":
            setContextMenu(call, result: result)
        case "popUpContextMenu":
            popUpContextMenu(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method handlers

    private func destroy(result: @escaping FlutterResult) {
        if let item = trayIcon?.statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        trayIcon?.removeImage()
        trayIcon = nil
        trayMenu = nil
        result(true)
    }

    private func setIcon(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let base64Icon = args["base64Icon"] as? String,
              let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
              let image = NSImage(data: imageData) else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing or invalid base64Icon", details: nil))
            return
        }

        image.size = NSSize(width: 18, height: 18)

        if trayIcon == nil {
            trayIcon = DesktopTrayIcon()
            trayIcon?.onTrayIconMouseDown = { [weak self] in
                self?.channel.invokeMethod(kOnTrayIconMouseDown, arguments: nil)
            }
            trayIcon?.onTrayIconMouseUp = { [weak self] in
                self?.channel.invokeMethod(kOnTrayIconMouseUp, arguments: nil)
            }
            trayIcon?.onTrayIconRightMouseDown = { [weak self] in
                self?.channel.invokeMethod(kOnTrayIconRightMouseDown, arguments: nil)
            }
            trayIcon?.onTrayIconRightMouseUp = { [weak self] in
                self?.channel.invokeMethod(kOnTrayIconRightMouseUp, arguments: nil)
            }
        }

        trayIcon?.setImage(image)
        result(true)
    }

    private func setToolTip(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let toolTip = args["toolTip"] as? String else {
            result(true)
            return
        }
        trayIcon?.statusItem?.button?.toolTip = toolTip
        result(true)
    }

    private func setContextMenu(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let menuDict = args["menu"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "Missing menu data", details: nil))
            return
        }

        trayMenu = DesktopTrayMenu(menuDict)
        trayMenu?.onMenuItemClick = { [weak self] (menuItem: NSMenuItem) in
            let args: NSDictionary = ["id": menuItem.tag]
            self?.channel.invokeMethod(kOnTrayMenuItemClick, arguments: args)
        }
        trayMenu?.delegate = self

        result(true)
    }

    private func popUpContextMenu(result: @escaping FlutterResult) {
        if let menu = trayMenu {
            trayIcon?.statusItem?.menu = menu
            trayIcon?.statusItem?.button?.performClick(nil)
        }
        result(true)
    }

    // MARK: - NSMenuDelegate

    public func menuDidClose(_ menu: NSMenu) {
        // Clear so left-click events work again (they are blocked while
        // statusItem.menu is non-nil).
        trayIcon?.statusItem?.menu = nil
    }
}

