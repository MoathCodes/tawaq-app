import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Fills the viewport for scroll and swipe gestures while keeping [header] and
/// [body] content visually centered at [maxContentWidth].
///
/// Use for pages where interaction should work in the side margins but content
/// stays in a narrow column (settings, forms, etc.).
class CenteredViewportShell extends StatelessWidget {
  /// Creates a [CenteredViewportShell] with a centered [header] and [body].
  const CenteredViewportShell({
    required this.maxContentWidth,
    required this.header,
    required this.body,
    this.centerBody = false,
    super.key,
  })  : _scrollTab = false,
        alignment = Alignment.topCenter,
        controller = null;

  /// Scrollable body centered at [maxContentWidth] with no header.
  ///
  /// The scroll viewport spans the full available width while [child] stays in
  /// a centered column — the common settings / form tab pattern.
  const CenteredViewportShell.scrollTab({
    required this.maxContentWidth,
    required Widget child,
    this.alignment = Alignment.topCenter,
    this.controller,
    super.key,
  })  : header = const SizedBox.shrink(),
        body = child,
        centerBody = false,
        _scrollTab = true;

  /// Maximum width of the centered content column.
  final double maxContentWidth;

  /// Header widget (e.g. tab bar) shown centered above [body].
  final Widget header;

  /// Body widget that expands to fill the remaining viewport height.
  final Widget body;

  /// When true, constrains [body] to [maxContentWidth] and centers it
  /// horizontally (matching [header] layout). When false, [body] spans the full
  /// viewport width — use [CenteredViewportShell.scrollTab] for scroll + center.
  final bool centerBody;

  /// Scroll alignment for [CenteredViewportShell.scrollTab].
  final AlignmentGeometry alignment;

  /// Optional scroll controller for [CenteredViewportShell.scrollTab].
  final ScrollController? controller;

  final bool _scrollTab;

  @override
  Widget build(BuildContext context) {
    if (_scrollTab) {
      return _CenteredViewportScrollTab(
        maxContentWidth: maxContentWidth,
        alignment: alignment,
        controller: controller,
        child: body,
      );
    }

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
              Expanded(
                child: centerBody
                    ? Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: body,
                        ),
                      )
                    : body,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CenteredViewportScrollTab extends StatelessWidget {
  const _CenteredViewportScrollTab({
    required this.maxContentWidth,
    required this.child,
    required this.alignment,
    this.controller,
  });

  final double maxContentWidth;
  final Widget child;
  final AlignmentGeometry alignment;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
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
}



