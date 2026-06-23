import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/semantics_scale_step_picker.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/quran_text_scale_control.dart';

/// App UI text scale picker that reads and writes [themeProvider].
class AppTextScaleStepPicker extends ConsumerWidget {
  /// Creates an [AppTextScaleStepPicker].
  const AppTextScaleStepPicker({this.showLabel = true, super.key});

  /// When true, shows a visible section title above the picker.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appTextScale = ref.watch(
      themeProvider.select((t) => t.value?.appTextScale ?? AppTextScale.normal),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));

    final picker = SemanticsScaleStepPicker(
      groupLabel: l10n.appTextSize,
      enabled: themeReady,
      previewSizes: AppTextScale.values.map((s) => 14 * s.scalar).toList(),
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
    );

    if (!showLabel) return picker;

    return SettingsGroup(
      title: l10n.appTextSize,
      subtitle: l10n.appTextSizeSubtitle,
      child: picker,
    );
  }
}

/// Quran mushaf text scale picker that reads and writes screen settings.
class QuranTextScaleStepPicker extends ConsumerWidget {
  /// Creates a [QuranTextScaleStepPicker].
  const QuranTextScaleStepPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const QuranTextScaleControl();
  }
}
