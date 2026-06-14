import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/param_controllers.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// The body content of the custom parameters accordion.
class CustomParametersContent extends StatelessWidget {
  /// Creates a new [CustomParametersContent] instance.
  const CustomParametersContent({
    required this.controllers,
    required this.onSave,
    required this.onReset,
    this.enabled = true,
    super.key,
  });

  /// The parameter controllers.
  final ParamControllers controllers;

  /// Whether fields and actions are interactive.
  final bool enabled;

  /// Called when the user saves.
  final VoidCallback onSave;

  /// Called when the user resets.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = controllers;

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
                      label: l10n.fajrAngleLabel,
                      controller: c.fajrAngle,
                      decimal: true,
                      enabled: enabled,
                    ),
                    NumericField(
                      label: l10n.ishaAngleLabel,
                      controller: c.ishaAngle,
                      decimal: true,
                      enabled: enabled,
                    ),
                  ],
                ),
                ResponsiveFieldRow(
                  maxColumns: 2,
                  children: [
                    NumericField(
                      label: l10n.ishaIntervalLabel,
                      controller: c.ishaInterval,
                      hint: l10n.optionalHint,
                      enabled: enabled,
                    ),
                    NumericField(
                      label: l10n.maghribAngleLabel,
                      controller: c.maghribAngle,
                      decimal: true,
                      enabled: enabled,
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
                  control: .managed(controller: c.madhab),
                  items: {
                    l10n.madhab_shafi: Madhab.shafi,
                    l10n.madhab_hanafi: Madhab.hanafi,
                  },
                  label: Text(l10n.madhabLabel),
                ),
                FSelect<HighLatitudeRule>(
                  enabled: enabled,
                  control: .managed(controller: c.highLatRule),
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
                      label: l10n.fajr,
                      controller: c.adjustments[Prayer.fajr]!,
                      signed: true,
                      enabled: enabled,
                    ),
                    NumericField(
                      label: l10n.sunrise,
                      controller: c.adjustments[Prayer.sunrise]!,
                      signed: true,
                      enabled: enabled,
                    ),
                    NumericField(
                      label: l10n.dhuhr,
                      controller: c.adjustments[Prayer.dhuhr]!,
                      signed: true,
                      enabled: enabled,
                    ),
                  ],
                ),
                ResponsiveFieldRow(
                  maxColumns: 3,
                  children: [
                    NumericField(
                      label: l10n.asr,
                      controller: c.adjustments[Prayer.asr]!,
                      signed: true,
                      enabled: enabled,
                    ),
                    NumericField(
                      label: l10n.maghrib,
                      controller: c.adjustments[Prayer.maghrib]!,
                      signed: true,
                      enabled: enabled,
                    ),
                    NumericField(
                      label: l10n.isha,
                      controller: c.adjustments[Prayer.isha]!,
                      signed: true,
                      enabled: enabled,
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
                onPress: enabled ? onReset : null,
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
                onPress: enabled ? onSave : null,
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

/// Generic numeric text field.
class NumericField extends StatelessWidget {
  /// Creates a new [NumericField] instance.
  const NumericField({
    required this.label,
    required this.controller,
    this.decimal = false,
    this.signed = false,
    this.hint,
    this.enabled = true,
    super.key,
  });

  /// The label shown above the field.
  final String label;

  /// The text controller.
  final TextEditingController controller;

  /// Whether to allow decimal input.
  final bool decimal;

  /// Whether to allow signed (negative) input.
  final bool signed;

  /// Optional hint text.
  final String? hint;

  /// Whether the field is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
