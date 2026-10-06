import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Whether decorative motion should be skipped in this subtree.
bool reduceMotion(BuildContext context) =>
    (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
    (context.findAncestorWidgetOfExactType<FAccessibilityScope>() != null &&
        context.accessibility.motion != FAccessibilityMotion.all);
