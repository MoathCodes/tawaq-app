import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Fills the viewport for scroll and swipe gestures while keeping [header] and
/// [body] content visually centered at [maxContentWidth].
///
/// Use for pages where interaction should work in the side margins but content
/// stays in a narrow column (settings, forms, etc.).
class CenteredViewportShell extends StatelessWidget {
  /// Creates a [CenteredViewportShell].
  const CenteredViewportShell({
    required this.maxContentWidth,
    required this.header,
    required this.body,
    super.key,
  });

  /// Maximum width of the centered content column.
  final double maxContentWidth;

  /// Header widget (e.g. tab bar) shown centered above [body].
  final Widget header;

  /// Body widget that expands to fill the remaining viewport height.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(maxContentWidth, constraints.maxWidth);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: header,
                ),
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

/// Scrollable tab pane that keeps [child] centered at [maxContentWidth] while
/// the scroll viewport spans the full available width.
Widget centeredViewportScrollTab({
  required double maxContentWidth,
  required Widget child,
  AlignmentGeometry alignment = Alignment.topCenter,
  ScrollController? controller,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth = math.min(maxContentWidth, constraints.maxWidth);

      return SingleChildScrollView(
        controller: controller,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
