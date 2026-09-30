import Cocoa

/// Encapsulates the NSStatusItem and captures mouse events.
public class DesktopTrayIcon: NSView {
    public var onTrayIconMouseDown: (() -> Void)?
    public var onTrayIconMouseUp: (() -> Void)?
    public var onTrayIconRightMouseDown: (() -> Void)?
    public var onTrayIconRightMouseUp: (() -> Void)?

    public var statusItem: NSStatusItem?

    public init() {
        super.init(frame: NSRect.zero)
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength)
        statusItem?.button?.addSubview(self)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setImage(_ image: NSImage) {
        statusItem?.button?.image = image
        if let button = statusItem?.button {
            self.frame = button.frame
        }
    }

    public func removeImage() {
        statusItem?.button?.image = nil
        if let button = statusItem?.button {
            self.frame = button.frame
        }
    }

    // MARK: - Mouse events

    public override func mouseDown(with event: NSEvent) {
        statusItem?.button?.highlight(true)
        onTrayIconMouseDown?()
    }

    public override func mouseUp(with event: NSEvent) {
        statusItem?.button?.highlight(false)
        onTrayIconMouseUp?()
    }

    public override func rightMouseDown(with event: NSEvent) {
        onTrayIconRightMouseDown?()
    }

    public override func rightMouseUp(with event: NSEvent) {
        onTrayIconRightMouseUp?()
    }
}

