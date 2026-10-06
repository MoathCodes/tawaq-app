import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';

/// Uses the app locale for the search field's clear action.
Widget localizedSearchClearButton(
  BuildContext context,
  FTextFieldStyle style,
  VoidCallback clear,
) => Padding(
  padding: style.clearButtonPadding,
  child: FButton.icon(
    style: style.clearButtonStyle,
    onPress: clear,
    child: context.theme.icons.x(
      context,
      semanticsLabel: context.l10n.clearSearchAction,
    ),
  ),
);
