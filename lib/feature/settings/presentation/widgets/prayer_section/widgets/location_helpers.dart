import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/theme/theme.dart';

/// Default map center (Makkah).
const kDefaultCenter = LatLng(21.4362544, 39.6817387);

/// Shared empty state widget for search selects.
Widget buildEmptyContent(BuildContext context) => Padding(
  padding: const EdgeInsets.all(AppSpacing.sm),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [const Icon(FIcons.searchX), Text(context.l10n.noResults).sm],
  ),
);

/// Shows a location error toast.
void showLocationError(BuildContext context, String action, Object error) {
  if (!context.mounted) return;
  showFToast(
    context: context,
    title: Text(context.l10n.errorOccurredWhile(action)),
    description: Text(error.toString()),
  );
}
