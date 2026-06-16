import AppKit

/// Builds an NSMenu from the serialised dictionary passed over the method
/// channel.
public class DesktopTrayMenu: NSMenu, NSMenuDelegate {
    public var onMenuItemClick: ((NSMenuItem) -> Void)?

    public init(_ args: [String: Any]) {
        super.init(title: "")

        guard let items = args["items"] as? [[String: Any]] else { return }

        for itemDict in items {
            let id: Int        = itemDict["id"] as? Int ?? 0
            let type: String   = itemDict["type"] as? String ?? "normal"
            let label: String  = itemDict["label"] as? String ?? ""
            let disabled: Bool = itemDict["disabled"] as? Bool ?? false
            let checked: Bool? = itemDict["checked"] as? Bool

            let menuItem: NSMenuItem

            if type == "separator" {
                menuItem = NSMenuItem.separator()
            } else {
                menuItem = NSMenuItem()
                menuItem.title = label
                menuItem.isEnabled = !disabled
                menuItem.action = !disabled ? #selector(itemClicked(_:)) : nil
                menuItem.target = self

                if type == "checkbox" {
                    if let c = checked {
                        menuItem.state = c ? .on : .off
                    } else {
                        menuItem.state = .mixed
                    }
                } else if type == "submenu",
                          let subDict = itemDict["submenu"] as? [String: Any] {
                    let sub = DesktopTrayMenu(subDict)
                    sub.onMenuItemClick = { [weak self] item in
                        self?.itemClicked(item)
                    }
                    self.setSubmenu(sub, for: menuItem)
                }
            }

            menuItem.tag = id
            self.addItem(menuItem)
        }

        self.delegate = self
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func itemClicked(_ sender: Any?) {
        guard let item = sender as? NSMenuItem else { return }
        onMenuItemClick?(item)
    }

    // NSMenuDelegate
    public func menuDidClose(_ menu: NSMenu) {}
}

