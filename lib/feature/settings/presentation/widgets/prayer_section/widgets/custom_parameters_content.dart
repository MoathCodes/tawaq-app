import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/param_controllers.dart';
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
      spacing: 16,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Basic parameters
        FCard(
          title: Text(l10n.basicParametersTitle),
          child: Column(
            spacing: 16,
            children: [
              FieldRow([
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
              ]),
              FieldRow([
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
              ]),
            ],
          ),
        ),
        // Advanced settings
        FCard(
          title: Text(l10n.advancedSettingsTitle),
          child: FieldRow([
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
          ]),
        ),
        // Adjustments
        FCard(
          title: Text(l10n.prayerTimeAdjustmentsTitle),
          child: Column(
            spacing: 12,
            children: [
              FieldRow([
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
              ]),
              FieldRow([
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
              ]),
            ],
          ),
        ),
        // Action buttons
        FieldRow([
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
        ]),
      ],
      ),
    );
  }
}

/// A row of expanded widgets with consistent spacing.
class FieldRow extends StatelessWidget {
  /// Creates a new [FieldRow] instance.
  const FieldRow(this.children, {super.key});

  /// The children to lay out in a row.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [for (final child in children) Expanded(child: child)],
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
