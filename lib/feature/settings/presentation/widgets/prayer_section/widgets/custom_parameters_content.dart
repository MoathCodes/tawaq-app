import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/custom_parameters_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// The body content of the custom parameters accordion.
class CustomParametersContent extends ConsumerWidget {
  /// Creates a new [CustomParametersContent] instance.
  const CustomParametersContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.read(customParametersDraftProvider.notifier);
    final enabled = ref.watch(
      prayerSettingsProvider.select((value) => value.hasValue),
    );

    void save() {
      try {
        final method = ref.read(prayerSettingsProvider).value?.method;
        final newMethod = draft.toMethod(method);
        if (newMethod != method) {
          unawaited(
            ref
                .read(prayerSettingsProvider.notifier)
                .update(
                  (s) => s.copyWith(method: newMethod),
                ),
          );
        }
        showFToast(
          context: context,
          title: Text(l10n.parametersSavedTitle),
          description: Text(l10n.parametersSavedDescription),
        );
      } catch (e) {
        showFToast(
          context: context,
          title: Text(l10n.invalidParametersTitle),
          description: Text(
            l10n.invalidParametersWithError(
              l10n.invalidParametersDescription,
              e.toString(),
            ),
          ),
        );
      }
    }

    void reset() {
      final current = ref.read(prayerSettingsProvider).value?.method;
      draft.syncFrom(current);
      save();
      showFToast(
        context: context,
        title: Text(l10n.resetCompleteTitle),
        description: Text(l10n.resetCompleteDescription),
      );
    }

    return NonSelectable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          SettingsGroup(
            title: l10n.basicParametersTitle,
            child: Column(
              spacing: AppSpacing.md,
              children: [
                ResponsiveFieldRow(
                  maxColumns: 2,
                  children: [
                    NumericField(
                      fieldKey: CustomParamFieldKey.fajrAngle,
                      label: l10n.fajrAngleLabel,
                      decimal: true,
                    ),
                    NumericField(
                      fieldKey: CustomParamFieldKey.ishaAngle,
                      label: l10n.ishaAngleLabel,
                      decimal: true,
                    ),
                  ],
                ),
                ResponsiveFieldRow(
                  maxColumns: 2,
                  children: [
                    NumericField(
                      fieldKey: CustomParamFieldKey.ishaInterval,
                      label: l10n.ishaIntervalLabel,
                      hint: l10n.optionalHint,
                    ),
                    NumericField(
                      fieldKey: CustomParamFieldKey.maghribAngle,
                      label: l10n.maghribAngleLabel,
                      decimal: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const FDivider(),
          SettingsGroup(
            title: l10n.advancedSettingsTitle,
            child: ResponsiveFieldRow(
              maxColumns: 2,
              children: [
                FSelect<Madhab>(
                  enabled: enabled,
                  contentConstraints: selectPopoverPortalConstraints(context),
                  control: .managed(controller: draft.madhab),
                  items: {
                    l10n.madhab_shafi: Madhab.shafi,
                    l10n.madhab_hanafi: Madhab.hanafi,
                  },
                  label: Text(l10n.madhabLabel),
                ),
                FSelect<HighLatitudeRule>(
                  enabled: enabled,
                  contentConstraints: selectPopoverPortalConstraints(context),
                  control: .managed(controller: draft.highLatRule),
                  items: {
                    l10n.highLatitudeRule_middleOfTheNight:
                        HighLatitudeRule.middleOfTheNight,
                    l10n.highLatitudeRule_seventhOfTheNight:
                        HighLatitudeRule.seventhOfTheNight,
                    l10n.highLatitudeRule_twilightAngle:
                        HighLatitudeRule.twilightAngle,
                  },
                  label: Text(l10n.highLatitudeRuleLabel),
                ),
              ],
            ),
          ),
          const FDivider(),
          SettingsGroup(
            title: l10n.prayerTimeAdjustmentsTitle,
            child: Column(
              spacing: AppSpacing.md,
              children: [
                ResponsiveFieldRow(
                  maxColumns: 3,
                  children: [
                    NumericField(
                      fieldKey: CustomParamFieldKey.adjustmentFajr,
                      label: l10n.fajr,
                      signed: true,
                    ),
                    NumericField(
                      fieldKey: CustomParamFieldKey.adjustmentSunrise,
                      label: l10n.sunrise,
                      signed: true,
                    ),
                    NumericField(
                      fieldKey: CustomParamFieldKey.adjustmentDhuhr,
                      label: l10n.dhuhr,
                      signed: true,
                    ),
                  ],
                ),
                ResponsiveFieldRow(
                  maxColumns: 3,
                  children: [
                    NumericField(
                      fieldKey: CustomParamFieldKey.adjustmentAsr,
                      label: l10n.asr,
                      signed: true,
                    ),
                    NumericField(
                      fieldKey: CustomParamFieldKey.adjustmentMaghrib,
                      label: l10n.maghrib,
                      signed: true,
                    ),
                    NumericField(
                      fieldKey: CustomParamFieldKey.adjustmentIsha,
                      label: l10n.isha,
                      signed: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ResponsiveFieldRow(
            maxColumns: 2,
            children: [
              FButton(
                variant: .secondary,
                onPress: enabled ? reset : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    const Icon(FLucideIcons.rotateCcw, size: 16),
                    Text(l10n.resetToDefaults),
                  ],
                ),
              ),
              FButton(
                onPress: enabled ? save : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    const Icon(FLucideIcons.save, size: 16),
                    Text(l10n.saveParameters),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Generic numeric text field bound to [customParametersDraftProvider].
class NumericField extends ConsumerWidget {
  /// Creates a new [NumericField] instance.
  const NumericField({
    required this.fieldKey,
    required this.label,
    this.decimal = false,
    this.signed = false,
    this.hint,
    super.key,
  });

  /// Draft field key.
  final CustomParamFieldKey fieldKey;

  /// The label shown above the field.
  final String label;

  /// Whether to allow decimal input.
  final bool decimal;

  /// Whether to allow signed (negative) input.
  final bool signed;

  /// Optional hint text.
  final String? hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(
      prayerSettingsProvider.select((value) => value.hasValue),
    );
    final controller = ref
        .read(customParametersDraftProvider.notifier)
        .textController(fieldKey);

    return FTextField(
      enabled: enabled,
      control: .managed(controller: controller),
      label: Text(label),
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimal,
        signed: signed,
      ),
      hint:
          hint ?? (decimal ? l10n.decimalPlaceholder : l10n.integerPlaceholder),
    );
  }
}
