import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/semantics_scale_step_picker.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/scale/quran_zoom_control.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Typography and scaling controls for app UI and Quran mushaf text.
class TypographySettingsSection extends ConsumerWidget {
  /// Creates a [TypographySettingsSection].
  const TypographySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final appTextScale = ref.watch(
      themeProvider.select((t) => t.value?.appTextScale ?? AppTextScale.normal),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));
    final mushafZoom = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        ResponsiveFieldRow(
          maxColumns: 2,
          children: [
            SettingsGroup(
              title: l10n.appTextSize,
              child: SemanticsScaleStepPicker(
                groupLabel: l10n.appTextSize,
                enabled: themeReady,
                previewSizes: AppTextScale.values
                    .map((s) => 14 * s.scalar)
                    .toList(),
                labels: [
                  l10n.appTextSizeCompact,
                  l10n.appTextSizeNormal,
                  l10n.appTextSizeLarge,
                  l10n.appTextSizeShortExtraLarge,
                ],
                selectedIndex: appTextScale.index,
                onChanged: (i) => ref
                    .read(themeProvider.notifier)
                    .setAppTextScale(AppTextScale.values[i]),
              ),
            ),
            SettingsGroup(
              title: l10n.quranTextSize,
              child: const QuranZoomControl(),
            ),
          ],
        ),
        Text(
          l10n.quranTextSizeIndependentNote,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          l10n.quranTextSizePreviewLabel,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        SettingsSemantics.readOnlyValue(
          name: l10n.quranTextSizePreviewLabel,
          value: l10n.quranTextSizePreview,
          child: Text(
            l10n.quranTextSizePreview,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.uthmanicHafs,
              fontSize: mushafZoomPreviewFontSize(mushafZoom),
              color: theme.colors.foreground,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }
}
