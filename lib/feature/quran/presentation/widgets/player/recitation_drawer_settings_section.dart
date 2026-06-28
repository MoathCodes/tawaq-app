import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/volume_slider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Volume slider and playback toggles in the recitation drawer.
class RecitationDrawerSettingsSection extends ConsumerWidget {
  /// Creates the settings section.
  const RecitationDrawerSettingsSection({
    required this.isNarrow,
    required this.persistedVolume,
    super.key,
  });

  final bool isNarrow;
  final double persistedVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final controller = ref.read(recitationControllerProvider.notifier);
    final settings = ref.watch(recitationSettingsProvider).value;

    final volumeSlider = PersistedVolumeSlider(
      persistedVolume: persistedVolume,
      onPreview: (v) => unawaited(controller.setVolumePreview(v)),
      onCommit: (v) => unawaited(controller.commitVolume(v)),
    );

    final autoScrollToggle = FTooltip(
      tipBuilder: (_, _) => Text(l10n.quranRecitationAutoScrollDesc),
      child: RecitationDrawerToggleChip(
        label: l10n.quranRecitationAutoScroll,
        value: settings?.autoScroll ?? true,
        onChange: (v) => ref
            .read(recitationSettingsProvider.notifier)
            .setAutoScroll(value: v),
      ),
    );

    final highlightToggle = FTooltip(
      tipBuilder: (_, _) => Text(l10n.quranRecitationHighlightDesc),
      child: RecitationDrawerToggleChip(
        label: l10n.quranRecitationHighlight,
        value: settings?.highlightAyah ?? true,
        onChange: (v) => ref
            .read(recitationSettingsProvider.notifier)
            .setHighlightAyah(value: v),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                FLucideIcons.volume2,
                size: 17,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: volumeSlider),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [autoScrollToggle, highlightToggle],
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          FLucideIcons.volume2,
          size: 17,
          color: colors.mutedForeground,
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 110, child: volumeSlider),
        const Spacer(),
        autoScrollToggle,
        const SizedBox(width: AppSpacing.md),
        highlightToggle,
      ],
    );
  }
}

class RecitationDrawerToggleChip extends StatelessWidget {
  const RecitationDrawerToggleChip({
    required this.label,
    required this.value,
    required this.onChange,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FSwitch(value: value, onChange: onChange),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: typography.body.xs.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.secondaryForeground,
          ),
        ),
      ],
    );
  }
}
