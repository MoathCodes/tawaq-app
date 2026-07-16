import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/semantics_scale_step_picker.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/theme/theme.dart';

/// Theme palette and app text scale onboarding step.
class OnboardingThemeStep extends ConsumerWidget {
  /// Creates [OnboardingThemeStep].
  const OnboardingThemeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appTextScale = ref.watch(
      themeProvider.select((t) => t.value?.appTextScale ?? AppTextScale.normal),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const ColorThemeSelectorContent(),
        const FDivider(),
        SettingsGroup(
          title: l10n.appTextSize,
          subtitle: l10n.appTextSizeSubtitle,
          child: SemanticsScaleStepPicker(
            groupLabel: l10n.appTextSize,
            enabled: themeReady,
            previewSizes:
                AppTextScale.values.map((s) => 14 * s.scalar).toList(),
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
      ],
    );
  }
}
