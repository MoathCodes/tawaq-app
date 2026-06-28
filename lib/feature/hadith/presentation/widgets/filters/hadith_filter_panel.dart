import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/theme/theme.dart';

/// Filter panel for the side tab or compact-layout popover.
class HadithFilterPanel extends ConsumerWidget {
  /// Creates the filter panel.
  ///
  /// Pass [onClose] when shown in a popover; omit for the side-panel tab.
  const HadithFilterPanel({this.onClose, super.key});

  /// Called when the user dismisses a popover instance.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hadithSessionControllerProvider);
    final panelEnabled = !session.searchBusy;
    final l10n = context.l10n;
    final theme = context.theme;

    Widget panel = NonSelectable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onClose != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.hadithFilterTab,
                    style: theme.typography.body.xl,
                  ),
                  FButton.icon(
                    variant: FButtonVariant.ghost,
                    semanticsLabel: hadithCloseFiltersSemanticsLabel(l10n),
                    onPress: onClose,
                    child: const HadithDecorExcludeSemantics(
                      child: Icon(FLucideIcons.x, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          const Expanded(child: HadithFilterForm()),
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
            child: FDivider(),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: FButton(
              variant: FButtonVariant.outline,
              onPress: panelEnabled
                  ? () {
                      unawaited(
                        ref
                            .read(hadithSessionControllerProvider.notifier)
                            .clearFilters(),
                      );
                    }
                  : null,
              child: Text(l10n.hadithResetFilters),
            ),
          ),
        ],
      ),
    );

    if (onClose != null) {
      final fallbackHeight = dialogConstraints(
        context,
        preferredHeight: 620,
        minWidth: 320,
      ).maxHeight.clamp(360.0, 620.0);

      panel = SizedBox(height: fallbackHeight, child: panel);
    }

    return panel;
  }
}
