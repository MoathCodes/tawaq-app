import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/quran_text_scale_control.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/settings_scale_step_picker.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Typography and scaling controls for app UI and Quran mushaf text.
class TypographySettingsSection extends ConsumerWidget {
  /// Creates a [TypographySettingsSection].
  const TypographySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final quranTextScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
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
              child: const AppTextScaleStepPicker(showLabel: false),
            ),
            SettingsGroup(
              title: l10n.quranTextSize,
              child: const QuranTextScaleControl(),
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
              fontSize: quranTextScale.previewFontSize,
              color: theme.colors.foreground,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }
}
