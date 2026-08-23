/// Container-width-aware row/column layout for form fields.
library;

import 'package:flutter/widgets.dart';

import 'package:tawaq/core/layout/responsive.dart';

/// Lays out [children] in a row when the allocated width is at least the
/// small breakpoint (640px), otherwise stacks them in a column.
///
/// When [maxColumns] is set below the child count, fields wrap into
/// multiple rows once width allows more than one column.
class ResponsiveFieldRow extends StatelessWidget {
  /// Creates a responsive field row.
  const new({
    required this.children,
    this.spacing = 12,
    this.maxColumns,
    this.expandChildren = true,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  /// Field widgets to arrange.
  final List<Widget> children;

  /// Gap between fields in both orientations.
  final double spacing;

  /// Maximum columns when width allows (defaults to the child count).
  final int? maxColumns;

  /// Whether row children should expand equally.
  final bool expandChildren;

  /// Cross-axis alignment when laid out as a row.
  final CrossAxisAlignment rowCrossAxisAlignment;

  /// Cross-axis alignment when laid out as a column.
  final CrossAxisAlignment columnCrossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isContainerAtLeast(context, constraints, FBreakpoint.sm)) {
          return Column(
            spacing: spacing,
            crossAxisAlignment: columnCrossAxisAlignment,
            children: children,
          );
        }

        final columns = responsiveColumnCount(
          context,
          constraints.maxWidth,
          maxColumns: maxColumns ?? children.length,
        );

        if (columns == 1) {
          return Column(
            spacing: spacing,
            crossAxisAlignment: columnCrossAxisAlignment,
            children: children,
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final chunk = children.sublist(
            i,
            (i + columns).clamp(0, children.length),
          );
          rows.add(
            Row(
              crossAxisAlignment: rowCrossAxisAlignment,
              spacing: spacing,
              children: [
                for (final child in chunk)
                  expandChildren ? Expanded(child: child) : child,
              ],
            ),
          );
        }

        return Column(
          spacing: spacing,
          crossAxisAlignment: columnCrossAxisAlignment,
          children: rows,
        );
      },
    );
  }
}
