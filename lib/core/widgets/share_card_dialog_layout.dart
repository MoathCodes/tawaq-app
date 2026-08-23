import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared preview/settings arrangement used by image share-card dialogs.
///
/// The feature supplies the preview and settings widgets. This widget only
/// standardizes the interaction model and responsive layout.
class ShareCardDialogLayout extends StatelessWidget {
  const new({
    required this.preview,
    required this.settings,
    super.key,
  });

  final Widget preview;
  final Widget settings;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= theme.breakpoints.sm;
        if (!sideBySide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                preview,
                const SizedBox(height: AppSpacing.lg),
                settings,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: preview),
            const SizedBox(width: AppSpacing.xl),
            SizedBox(width: 280, child: settings),
          ],
        );
      },
    );
  }
}
