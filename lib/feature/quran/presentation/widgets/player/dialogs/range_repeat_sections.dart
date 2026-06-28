import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/numeric_step_button.dart';
import 'package:tawaq/feature/quran/domain/models/range_scope_preset.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';
import 'package:tawaq/theme/theme.dart';

class RangeRepeatSectionLabel extends StatelessWidget {
  const RangeRepeatSectionLabel({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: context.theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
      ],
    );
  }
}

class RangeRepeatPresetList extends StatelessWidget {
  const RangeRepeatPresetList({
    required this.presetIndex,
    required this.isResolving,
    required this.presetEnabled,
    required this.presetLabel,
    required this.onPresetSelected,
    super.key,
  });

  final int presetIndex;
  final bool isResolving;
  final bool Function(RangeScopePreset) presetEnabled;
  final String Function(RangeScopePreset) presetLabel;
  final ValueChanged<RangeScopePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, p) in RangeScopePreset.values.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < RangeScopePreset.values.length - 1
                  ? AppSpacing.xs
                  : 0,
            ),
            child: FButton(
              variant: presetIndex == index
                  ? FButtonVariant.primary
                  : FButtonVariant.outline,
              onPress: isResolving || !presetEnabled(p)
                  ? null
                  : () => onPresetSelected(p),
              child: Text(presetLabel(p)),
            ),
          ),
        if (isResolving) ...[
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
          ),
        ],
      ],
    );
  }
}

class TimedRiwayatPicker extends StatelessWidget {
  const TimedRiwayatPicker({
    required this.suggestions,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.onPick,
    super.key,
  });

  final List<ReciterPick> suggestions;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final void Function(Reciter reciter, Moshaf moshaf) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RangeRepeatSectionLabel(
          icon: FLucideIcons.audioLines,
          label: l10n.quranRecitationNoTiming,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.secondary,
            border: Border.all(color: colors.border),
            borderRadius: context.theme.radii.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, suggestion) in suggestions.indexed) ...[
                FTile(
                  title: Text(
                    '${suggestion.reciter.name} · ${suggestion.moshaf.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  suffix: selectedReciterId == suggestion.reciter.id &&
                          selectedMoshafId == suggestion.moshaf.id
                      ? Icon(
                          FLucideIcons.check,
                          size: 16,
                          color: colors.primary,
                        )
                      : null,
                  onPress: () => onPick(suggestion.reciter, suggestion.moshaf),
                ),
                if (index < suggestions.length - 1)
                  Container(height: 1, color: colors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class RangeRepeatCountRow extends StatelessWidget {
  const RangeRepeatCountRow({
    required this.label,
    required this.count,
    required this.onChanged,
    this.narrow = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final int count;
  final ValueChanged<int> onChanged;
  final bool narrow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    Widget chip(int value) {
      final active = count == value;
      return FButton(
        variant: active ? FButtonVariant.primary : FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        onPress: enabled ? () => onChanged(value) : null,
        child: Text(l10n.quranRangeRepeatChip(value)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangeRepeatSectionLabel(
                icon: FLucideIcons.repeat,
                label: label,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [chip(1), chip(3), chip(5)],
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: RangeRepeatSectionLabel(
                  icon: FLucideIcons.repeat,
                  label: label,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  chip(1),
                  const SizedBox(width: AppSpacing.xs),
                  chip(3),
                  const SizedBox(width: AppSpacing.xs),
                  chip(5),
                ],
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.secondary,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              NumericStepButton(
                icon: FLucideIcons.minus,
                size: NumericStepButtonSize.large,
                enabled: enabled && count > 1,
                onPress: () => onChanged(count - 1),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '×',
                          style: typography.body.lg.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$count',
                          style: typography.body.lg.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      repeatCountLabel(l10n, count),
                      style: typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              NumericStepButton(
                icon: FLucideIcons.plus,
                size: NumericStepButtonSize.large,
                enabled: enabled && count < 99,
                onPress: () => onChanged(count + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
