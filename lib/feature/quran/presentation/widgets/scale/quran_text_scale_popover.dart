import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/scale/quran_zoom_control.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Compact Quran mushaf zoom control for the Quran screen header.
class QuranTextScalePopover extends ConsumerWidget {
  /// Creates a [QuranTextScalePopover].
  const QuranTextScalePopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final mushafZoom = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
      ),
    );

    return FPopover(
      popoverBuilder: (context, _) {
        final popoverConstraints = dialogConstraints(
          context,
          preferredWidth: 420,
          minWidth: 360,
        );

        return ConstrainedBox(
          constraints: popoverConstraints,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuranZoomControl(showHeader: true),
                const SizedBox(height: AppSpacing.lg),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: theme.radii.md,
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.sm,
                      children: [
                        Text(
                          l10n.quranTextSizePreviewLabel,
                          style: theme.typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        QuranSemantics.decorative(
                          Text(
                            l10n.quranTextSizePreview,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: FontFamily.uthmanicHafs,
                              fontSize: mushafZoomPreviewFontSize(mushafZoom),
                              color: colors.foreground,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      semanticsLabel: l10n.quranTextSize,
      builder: (_, controller, _) => QuranSemantics.labeledControl(
        name: l10n.quranTextSize,
        button: true,
        excludeChild: true,
        child: FButton.icon(
          onPress: controller.toggle,
          child: QuranSemantics.decorative(
            const Icon(FLucideIcons.type),
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
