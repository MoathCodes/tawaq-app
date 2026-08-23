import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:tawaq/core/utils/widget_to_image.dart';

/// Makes a rendered share card draggable to desktop applications.
class ShareCardDragSurface extends StatelessWidget {
  const new({
    required this.boundaryKey,
    required this.enabled,
    required this.child,
    super.key,
  });

  final GlobalKey boundaryKey;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy],
      dragItemProvider: (request) async {
        if (!enabled) return null;
        final bytes = await captureWidgetToPng(boundaryKey);
        if (bytes == null) return null;
        final item = DragItem(suggestedName: 'tawaq-share.png');
        item.add(Formats.png(bytes));
        return item;
      },
      dragBuilder: (context, child) => AnimatedScale(
        scale: 1.02,
        duration: const Duration(milliseconds: 160),
        child: child,
      ),
      child: DraggableWidget(isLocationDraggable: (_) => enabled, child: child),
    );
  }
}
