import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/scale/quran_scale_step_picker.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
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

    return FPopover(
      popoverBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Text(
                l10n.quranTextSize,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              QuranScaleStepPicker(
                groupLabel: l10n.quranTextSize,
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
                style: theme.typography.xs.copyWith(
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
      ),
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
