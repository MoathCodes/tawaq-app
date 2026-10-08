import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

/// Lets source labels wrap within the available tag width, leaving room for
/// the removal button even at the sidebar's minimum width.
Widget hadithFilterTag<T>(
  BuildContext context,
  bool enabled,
  FMultiValueNotifier<T> controller,
  FMultiSelectFieldStyle style,
  T value,
  Widget label,
) => FMultiSelectTag(
  style: style.tagStyle,
  label: Flexible(child: label),
  onPress: enabled ? () => controller.update(value, add: false) : null,
);
