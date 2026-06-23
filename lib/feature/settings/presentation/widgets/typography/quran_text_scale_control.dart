import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/semantics_scale_step_picker.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

/// Shared Quran mushaf text scale picker wired to screen settings.
class QuranTextScaleControl extends ConsumerWidget {
  /// Creates a [QuranTextScaleControl].
  const QuranTextScaleControl({super.key});

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

    return SemanticsScaleStepPicker(
      groupLabel: l10n.quranTextSize,
      enabled: stateReady,
      previewSizes: QuranTextScale.values.map((s) => 14 * s.boost).toList(),
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
