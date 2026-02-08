import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/param_controllers.dart';
import 'package:hasanat/theme/theme.dart';

/// The body content of the custom parameters accordion.
class CustomParametersContent extends StatelessWidget {
  /// Creates a new [CustomParametersContent] instance.
  const CustomParametersContent({
    required this.controllers,
    required this.onSave,
    required this.onReset,
    super.key,
  });

  /// The parameter controllers.
  final ParamControllers controllers;

  /// Called when the user saves.
  final VoidCallback onSave;

  /// Called when the user resets.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = controllers;

    return Column(
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
                ),
                NumericField(
                  label: l10n.ishaAngleLabel,
                  controller: c.ishaAngle,
                  decimal: true,
                ),
              ]),
              FieldRow([
                NumericField(
                  label: l10n.ishaIntervalLabel,
                  controller: c.ishaInterval,
                  hint: l10n.optionalHint,
                ),
                NumericField(
                  label: l10n.maghribAngleLabel,
                  controller: c.maghribAngle,
                  decimal: true,
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
              control: .managed(controller: c.madhab),
              items: {
                l10n.madhab_shafi: Madhab.shafi,
                l10n.madhab_hanafi: Madhab.hanafi,
              },
              label: Text(l10n.madhabLabel),
            ),
            FSelect<HighLatitudeRule>(
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
                ),
                NumericField(
                  label: l10n.sunrise,
                  controller: c.adjustments[Prayer.sunrise]!,
                  signed: true,
                ),
                NumericField(
                  label: l10n.dhuhr,
                  controller: c.adjustments[Prayer.dhuhr]!,
                  signed: true,
                ),
              ]),
              FieldRow([
                NumericField(
                  label: l10n.asr,
                  controller: c.adjustments[Prayer.asr]!,
                  signed: true,
                ),
                NumericField(
                  label: l10n.maghrib,
                  controller: c.adjustments[Prayer.maghrib]!,
                  signed: true,
                ),
                NumericField(
                  label: l10n.isha,
                  controller: c.adjustments[Prayer.isha]!,
                  signed: true,
                ),
              ]),
            ],
          ),
        ),
        // Action buttons
        FieldRow([
          FButton(
            style: FButtonStyle.secondary(),
            onPress: onReset,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FIcons.rotateCcw, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.resetToDefaults),
              ],
            ),
          ),
          FButton(
            onPress: onSave,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FIcons.save, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.saveParameters),
              ],
            ),
          ),
        ]),
      ],
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

  @override
  Widget build(BuildContext context) {
    return FTextField(
      control: .managed(controller: controller),
      label: Text(label),
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimal,
        signed: signed,
      ),
      hint: hint ?? (decimal ? '0.0' : '0'),
    );
  }
}
