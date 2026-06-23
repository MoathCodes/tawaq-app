import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Visual size variant for [NumericStepButton].
enum NumericStepButtonSize {
  /// Default compact control for inline fields.
  compact,

  /// Larger control for hero steppers (e.g. repeat count).
  large,
}

/// Compact +/- control for numeric fields (ayah pickers, repeat count, etc.).
class NumericStepButton extends StatelessWidget {
  /// Creates a [NumericStepButton].
  const NumericStepButton({
    required this.icon,
    required this.enabled,
    required this.onPress,
    this.size = NumericStepButtonSize.compact,
    this.semanticsLabel,
    this.tooltip,
    super.key,
  });

  /// Icon shown inside the control (typically plus or minus).
  final IconData icon;

  /// Whether the button accepts presses.
  final bool enabled;

  /// Called when the user activates the control.
  final VoidCallback onPress;

  /// Visual size of the control.
  final NumericStepButtonSize size;

  /// Screen-reader label; when set, wraps the control in [Semantics].
  final String? semanticsLabel;

  /// Optional hover tooltip (desktop).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    final (width, height, iconSize, radius) = switch (size) {
      NumericStepButtonSize.compact => (26.0, 24.0, 13.0, 7.0),
      NumericStepButtonSize.large => (48.0, 48.0, 20.0, 10.0),
    };
    Widget child = FTappable(
      onPress: enabled ? onPress : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: size == NumericStepButtonSize.large
              ? colors.secondary
              : null,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: enabled
              ? colors.mutedForeground
              : colors.disable(colors.mutedForeground),
        ),
      ),
    );

    if (semanticsLabel != null) {
      child = Semantics(
        button: true,
        enabled: enabled,
        label: semanticsLabel,
        child: ExcludeSemantics(child: child),
      );
    }

    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }

    return child;
  }
}
