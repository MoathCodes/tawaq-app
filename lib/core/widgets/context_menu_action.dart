import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Builds a single [FItem] for use inside an [FContextMenu].
///
/// Runs [onPressed] and dismisses the menu via [controller] so callers don't
/// have to remember to hide the popover after every action. Keeps right-click
/// menus visually consistent across features (leading [icon] + [label]).
FItem contextMenuAction({
  required FPopoverController controller,
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return FItem(
    prefix: Icon(icon),
    title: Text(label),
    onPress: () {
      unawaited(controller.hide());
      onPressed();
    },
  );
}
