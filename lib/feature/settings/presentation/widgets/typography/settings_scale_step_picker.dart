import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/scale_step_picker.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';

/// [ScaleStepPicker] with per-step button semantics for settings screens.
class SettingsScaleStepPicker extends StatelessWidget {
  /// Creates a [SettingsScaleStepPicker].
  const SettingsScaleStepPicker({
    required this.groupLabel,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Setting name announced with each option (e.g. "App text size").
  final String groupLabel;

  /// Labels for each step.
  final List<String> labels;

  /// Currently selected step index.
  final int selectedIndex;

  /// Called when the user selects a different step.
  final ValueChanged<int> onChanged;

  /// Whether steps can be selected.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ScaleStepPicker(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      enabled: enabled,
      wrapStep: (index, step) => SettingsSemantics.labeledControl(
        name: groupLabel,
        value: labels[index],
        button: true,
        selected: selectedIndex == index,
        enabled: enabled,
        excludeChild: true,
        onTap: enabled ? () => onChanged(index) : null,
        child: step,
      ),
    );
  }
}

/// App UI text scale picker that reads and writes [themeProvider].
class AppTextScaleStepPicker extends ConsumerWidget {
  /// Creates an [AppTextScaleStepPicker].
  const AppTextScaleStepPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appTextScale = ref.watch(
      themeProvider.select((t) => t.value?.appTextScale ?? AppTextScale.normal),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));

    return SettingsScaleStepPicker(
      groupLabel: l10n.appTextSize,
      enabled: themeReady,
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
  }
}

/// Quran mushaf text scale picker that reads and writes screen settings.
class QuranTextScaleStepPicker extends ConsumerWidget {
  /// Creates a [QuranTextScaleStepPicker].
  const QuranTextScaleStepPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quranTextScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
      ),
    );
    final stateReady = ref.watch(
      quranScreenSettingsProvider.select((s) => s.hasValue),
    );

    return SettingsScaleStepPicker(
      groupLabel: l10n.quranTextSize,
      enabled: stateReady,
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
    );
  }
}
