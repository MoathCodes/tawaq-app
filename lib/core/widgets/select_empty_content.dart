import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/text_extensions.dart';
import 'package:tawaq/theme/theme.dart';

/// Empty state for search [FSelect] popovers (icon + muted “no results”).
class SelectEmptyContent extends StatelessWidget {
  /// Creates a [SelectEmptyContent].
  const new({super.key});

  @override
  Widget build(BuildContext context) => buildSelectEmptyContent(context);
}

/// Builds the shared empty state for search selects.
Widget buildSelectEmptyContent(BuildContext context) => Padding(
  padding: const EdgeInsets.all(AppSpacing.sm),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [
      const Icon(FLucideIcons.searchX),
      Flexible(
        child: Text(
          context.l10n.noResults,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ).sm,
      ),
    ],
  ),
);
