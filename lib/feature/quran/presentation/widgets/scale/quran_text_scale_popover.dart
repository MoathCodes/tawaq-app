import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/semantics_scale_step_picker.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Compact Quran text scale control for the Quran screen header.
class QuranTextScalePopover extends ConsumerWidget {
  /// Creates a [QuranTextScalePopover].
  const QuranTextScalePopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final quranTextScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
      ),
    );
    final quranStateReady = ref.watch(
      quranScreenSettingsProvider.select((s) => s.hasValue),
    );

    return FPopover(
      popoverBuilder: (context, _) {
        final popoverConstraints = dialogConstraints(
          context,
          preferredWidth: 360,
          minWidth: 300,
        );

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: popoverConstraints,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  l10n.quranTextSize,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SemanticsScaleStepPicker(
                  groupLabel: l10n.quranTextSize,
                  enabled: quranStateReady,
                  previewSizes:
                      QuranTextScale.values.map((s) => 14 * s.boost).toList(),
                  labels: [
                    l10n.quranTextSizeSmall,
                    l10n.quranTextSizeMedium,
                    l10n.quranTextSizeLarge,
                    l10n.quranTextSizeShortExtraLarge,
                  ],
                  selectedIndex: quranTextScale.index,
                  onChanged: (i) => ref
                      .read(quranScreenSettingsProvider.notifier)
                      .setTextScale(QuranTextScale.values[i]),
                ),
                Text(
                  l10n.quranTextSizePreviewLabel,
                  style: theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                QuranSemantics.decorative(
                  Text(
                    l10n.quranTextSizePreview,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontFamily.uthmanicHafs,
                      fontSize: quranTextScale.previewFontSize,
                      color: colors.foreground,
                      height: 1.6,
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
