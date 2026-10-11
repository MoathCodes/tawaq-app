import 'package:material_ui/material_ui.dart';

/// A persistent desktop thumb with hover and drag feedback.
ScrollbarThemeData tawaqScrollbarTheme(ColorScheme colorScheme) {
  final thumbBase = colorScheme.onSurface;

  return ScrollbarThemeData(
    thumbVisibility: const WidgetStatePropertyAll(true),
    trackVisibility: const WidgetStatePropertyAll(false),
    thickness: const WidgetStatePropertyAll(6),
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

/// App-wide persistent, draggable scrollbar for overflowing desktop content.
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
    if (details.controller == null) return child;
    final theme = Theme.of(context).scrollbarTheme;
    return RawScrollbar(
      controller: details.controller,
      thumbVisibility: true,
      interactive: true,
      trackVisibility: false,
      thickness: theme.thickness?.resolve({}),
      radius: theme.radius,
      thumbColor: theme.thumbColor?.resolve({}),
      crossAxisMargin: theme.crossAxisMargin ?? 2,
      mainAxisMargin: theme.mainAxisMargin ?? 6,
      minThumbLength: theme.minThumbLength ?? 20,
      child: child,
    );
  }
}
