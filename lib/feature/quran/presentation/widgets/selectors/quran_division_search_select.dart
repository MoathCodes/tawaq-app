import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Muted in-field label used by Quran header navigation selects.
Widget _quranInlineSelectPrefix(BuildContext context, String label) {
  final theme = context.theme;
  final colors = theme.colors;

  return Padding(
    padding: const EdgeInsetsDirectional.only(
      start: AppSpacing.sm,
      end: AppSpacing.xs,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          height: 16,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    ),
  );
}

/// [FSelect] prefix builder for header navigation fields.
FFieldIconBuilder<FTextFieldStyle> _quranInlineSelectPrefixBuilder(
  String label,
) {
  return (context, style, states) => _quranInlineSelectPrefix(context, label);
}

/// Shared searchable [FSelect] shell for Juz, Hizb, and Surah pickers.
class QuranDivisionSearchSelect<T> extends StatelessWidget {
  /// Creates a division search select.
  const new({
    required this.fieldName,
    required this.closedValue,
    required this.ready,
    required this.loading,
    required this.enabled,
    required this.value,
    required this.format,
    required this.filter,
    required this.contentBuilder,
    required this.onChanged,
    this.showLabel = true,
    this.inlineLabel = false,
    this.useQuranFont = false,
    this.size = FTextFieldSizeVariant.md,
    this.includeSemantics = true,
    super.key,
  });

  /// Accessibility field name.
  final String fieldName;

  /// Closed-field value label for semantics.
  final String? closedValue;

  /// Whether async data has loaded.
  final bool ready;

  /// Whether to show the skeleton loader.
  final bool loading;

  /// Whether the control accepts input.
  final bool enabled;

  /// Currently selected value.
  final T? value;

  /// Formats the closed field label.
  final String Function(T value) format;

  /// Filters items by search query.
  final Iterable<T> Function(String query) filter;

  /// Builds select items for the filtered values.
  final List<FSelectItem<T>> Function(
    BuildContext context,
    List<T> values,
  ) contentBuilder;

  /// Called when the user picks a value.
  final ValueChanged<T?> onChanged;

  /// Whether the field label is shown above the select.
  final bool showLabel;

  /// Shows a muted in-field label prefix (for the Quran header rail).
  final bool inlineLabel;

  /// Uses the Quran font in the select field.
  final bool useQuranFont;

  /// Text field size variant.
  final FTextFieldSizeVariant size;

  /// When false, skips the outer [QuranSemantics.labeledControl] wrapper.
  final bool includeSemantics;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final select = FSelect<T>.searchBuilder(
          enabled: ready && enabled,
          label: showLabel && !inlineLabel
              ? Text(fieldName)
              : const SizedBox.shrink(),
          prefixBuilder: inlineLabel
              ? _quranInlineSelectPrefixBuilder(fieldName)
              : null,
          size: size,
          contentConstraints: selectPopoverPortalConstraints(context),
          style: selectStyle(
            colors: theme.colors,
            style: theme.style,
            typography: theme.typography,
            useQuranFont: useQuranFont,
          ),
          control: FSelectControl.lifted(
            value: value,
            onChange: onChanged,
          ),
          format: format,
          filter: filter,
          contentBuilder: (context, _, vals) =>
              contentBuilder(context, vals.toList()),
    );

    final wrapped = includeSemantics
        ? QuranSemantics.labeledControl(
            name: fieldName,
            value: closedValue,
            enabled: ready && enabled,
            excludeChild: true,
            child: select,
          )
        : select;

    return FSkeletonizer(
      enabled: loading,
      child: wrapped,
    );
  }
}
