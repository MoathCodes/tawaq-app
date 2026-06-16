/// Self-contained menu item model for the desktop system tray.
///
/// Each item is assigned a unique auto-incremented [id] so the native layer
/// can identify which item was clicked without depending on any external
/// package (e.g. `menu_base`, `shortid`).
class TrayMenuItem {
  TrayMenuItem({required this.label, this.key, this.disabled = false, this.checked, this.children})
      : type = TrayMenuItemType.normal,
        id = _nextId++;

  TrayMenuItem.separator()
      : type = TrayMenuItemType.separator,
        id = _nextId++,
        label = '',
        key = null,
        disabled = false,
        checked = null,
        children = null;

  TrayMenuItem.checkbox({
    required this.label,
    this.key,
    this.checked = false,
    this.disabled = false,
  })  : type = TrayMenuItemType.checkbox,
        id = _nextId++,
        children = null;

  TrayMenuItem.submenu({
    required this.label,
    required List<TrayMenuItem> this.children,
    this.key,
    this.disabled = false,
  })  : type = TrayMenuItemType.submenu,
        id = _nextId++,
        checked = null;

  /// Global auto-increment counter shared across all instances.
  static int _nextId = 0;

  /// Unique numeric id used by the native layer for callback matching.
  final int id;

  /// Item type: normal, separator, checkbox, or submenu.
  final TrayMenuItemType type;

  /// Display text shown in the menu.
  final String label;

  /// Application-level key for identifying the item in Dart callbacks.
  final String? key;

  /// Whether the item is greyed out / non-interactive.
  final bool disabled;

  /// Checked state for checkbox items (`null` for non-checkbox items).
  final bool? checked;

  /// Child items for submenu entries.
  final List<TrayMenuItem>? children;

  /// Serialise to a map understood by the native method-channel codec.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'disabled': disabled,
      if (checked != null) 'checked': checked,
      if (children != null) 'submenu': {'items': children!.map((e) => e.toJson()).toList()},
    };
  }
}

/// Type discriminator for [TrayMenuItem].
enum TrayMenuItemType { normal, separator, checkbox, submenu }

/// A complete tray context-menu consisting of a flat list of [TrayMenuItem]s.
class TrayMenu {
  const TrayMenu({required this.items});

  final List<TrayMenuItem> items;

  /// Find the first item whose [TrayMenuItem.key] equals [key], or `null`.
  TrayMenuItem? findByKey(String key) {
    for (final item in items) {
      if (item.key == key) return item;
      final nested = _findInChildren(item.children, key);
      if (nested != null) return nested;
    }
    return null;
  }

  /// Find the first item whose [TrayMenuItem.id] equals [id], or `null`.
  TrayMenuItem? findById(int id) {
    for (final item in items) {
      if (item.id == id) return item;
      final nested = _findByIdInChildren(item.children, id);
      if (nested != null) return nested;
    }
    return null;
  }

  static TrayMenuItem? _findInChildren(List<TrayMenuItem>? children, String key) {
    if (children == null) return null;
    for (final child in children) {
      if (child.key == key) return child;
      final nested = _findInChildren(child.children, key);
      if (nested != null) return nested;
    }
    return null;
  }

  static TrayMenuItem? _findByIdInChildren(List<TrayMenuItem>? children, int id) {
    if (children == null) return null;
    for (final child in children) {
      if (child.id == id) return child;
      final nested = _findByIdInChildren(child.children, id);
      if (nested != null) return nested;
    }
    return null;
  }

  /// Serialise for the platform channel.
  Map<String, dynamic> toJson() {
    return {'items': items.map((e) => e.toJson()).toList()};
  }
}
