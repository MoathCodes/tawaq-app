import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';

/// A thin desktop thumb that fades after scrolling.
ScrollbarThemeData tawaqScrollbarTheme(ColorScheme colorScheme) {
  final thumbBase = colorScheme.onSurface;

  return ScrollbarThemeData(
    thumbVisibility: const WidgetStatePropertyAll(false),
    trackVisibility: const WidgetStatePropertyAll(false),
    thickness: const WidgetStatePropertyAll(3),
    radius: const Radius.circular(4),
    crossAxisMargin: 2,
    mainAxisMargin: 6,
    minThumbLength: 20,
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.dragged)) {
        return thumbBase.withValues(alpha: 0.45);
      }
      if (states.contains(WidgetState.hovered)) {
        return thumbBase.withValues(alpha: 0.32);
      }
      return thumbBase.withValues(alpha: 0.2);
    }),
  );
}

/// Transient desktop scrollbars. Persistent overflow hints are screen-owned.
/// RawScrollbar handles initial and subsequent layout metrics and paints no
/// thumb when content fits. Keeping it mounted preserves the scroll subtree.
class TawaqAppScrollBehavior extends MaterialScrollBehavior {
  const new();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Scrollable owns an inner selection registrar. Keep paragraph boundaries
    // inside it, before its aggregate reaches the outer reading region.
    final selectionChild = SelectionContainer.maybeOf(context) != null
        ? DesktopSelectionDocument(child: child)
        : child;
    if (details.controller == null) return selectionChild;
    final theme = Theme.of(context).scrollbarTheme;
    return RawScrollbar(
      controller: details.controller,
      thumbVisibility: false,
      interactive: true,
      timeToFade: const Duration(milliseconds: 100),
      fadeDuration: const Duration(milliseconds: 150),
      trackVisibility: false,
      thickness: theme.thickness?.resolve({}),
      radius: theme.radius,
      thumbColor: theme.thumbColor?.resolve({}),
      crossAxisMargin: theme.crossAxisMargin ?? 2,
      mainAxisMargin: theme.mainAxisMargin ?? 6,
      minThumbLength: theme.minThumbLength ?? 20,
      child: selectionChild,
    );
  }
}
