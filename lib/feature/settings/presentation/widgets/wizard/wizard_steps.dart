import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/settings/presentation/provider/wizard_setup_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Welcome step for the start wizard.
class WelcomeStep extends StatelessWidget {
  /// Creates a [WelcomeStep] instance.
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsSemantics.sectionHeader(
          label: l10n.setupPrayerSettingsTitle,
          child: Text(
            l10n.setupPrayerSettingsTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.setupPrayerSettingsSubtitle),
      ],
    );
  }
}

/// Calculation method selection step for the start wizard.
class MethodStep extends ConsumerWidget {
  /// Creates a [MethodStep] instance.
  const MethodStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.read(wizardSetupProvider.notifier);
    final method = ref.watch(wizardSetupProvider.select((s) => s.method));
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsSemantics.sectionHeader(
          label: l10n.chooseCalculationMethod,
          child: Text(l10n.chooseCalculationMethod),
        ),
        const SizedBox(height: AppSpacing.sm),
        FSelect<CalculationMethod>(
          control: .lifted(
            value: method,
            onChange: wizard.setMethod,
          ),
          label: Text(l10n.calculationMethod),
          items: {
            for (final m in CalculationMethod.values) m.getLocaleName(l10n): m,
          },
        ),
        if (method == CalculationMethod.other) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.customParametersLabel),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveFieldRow(
            children: [
              NumberField(
                controller: wizard.fajrAngle,
                label: l10n.fajrAngleLabel,
              ),
              NumberField(
                controller: wizard.ishaAngle,
                label: l10n.ishaAngleLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFieldRow(
            children: [
              NumberField(
                controller: wizard.ishaInterval,
                dec: false,
                label: l10n.ishaIntervalLabel,
              ),
              NumberField(
                controller: wizard.maghribAngle,
                label: l10n.maghribAngleLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.placeholdersHint,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

/// Time format selection step for the start wizard.
class TimeFormatStep extends ConsumerWidget {
  /// Creates a [TimeFormatStep] instance.
  const TimeFormatStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final is24Hours = ref.watch(
      wizardSetupProvider.select((s) => s.is24Hours),
    );
    final l10n = context.l10n;

    return FSwitch(
      value: is24Hours,
      onChange: (value) {
        ref.read(wizardSetupProvider.notifier).setIs24Hours(value: value);
      },
      label: Text(l10n.use24HourFormat),
    );
  }
}

/// Location configuration step for the start wizard.
class LocationStep extends ConsumerWidget {
  /// Creates a [LocationStep] instance.
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.read(wizardSetupProvider.notifier);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FTextFormField(
          control: FTextFieldControl.managed(controller: wizard.locationName),
          label: Text(l10n.searchPlaceLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveFieldRow(
          children: [
            NumberField(
              controller: wizard.latitude,
              signed: true,
              label: l10n.latitude,
            ),
            NumberField(
              controller: wizard.longitude,
              signed: true,
              label: l10n.longitude,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ResponsiveFieldRow(
          spacing: AppSpacing.sm,
          maxColumns: 2,
          expandChildren: false,
          children: [
            FButton(
              onPress: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deviceLocationNotImplemented)),
              ),
              child: Text(l10n.useDeviceLocation),
            ),
            FButton(
              onPress: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.detectTimezoneNotImplemented)),
              ),
              child: Text(l10n.detectTimezone),
            ),
          ],
        ),
      ],
    );
  }
}

/// Iqamah and adjustments configuration step for the start wizard.
class IqamahStep extends ConsumerWidget {
  /// Creates an [IqamahStep] instance.
  const IqamahStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.read(wizardSetupProvider.notifier);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsSemantics.sectionHeader(
          label: l10n.iqamahAfterAdhan,
          child: Text(l10n.iqamahAfterAdhan),
        ),
        const SizedBox(height: AppSpacing.sm),
        ResponsiveFieldRow(
          maxColumns: 3,
          children: [
            for (final prayer in kWizardIqamahPrayers)
              FTextFormField(
                control: FTextFieldControl.managed(
                  controller: wizard.iqamah[prayer],
                ),
                label: Text(prayer.getLocaleName(l10n)),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSemantics.sectionHeader(
          label: l10n.adhanAdjustments,
          child: Text(l10n.adhanAdjustments),
        ),
        const SizedBox(height: AppSpacing.sm),
        ResponsiveFieldRow(
          maxColumns: 3,
          children: [
            for (final prayer in kWizardAdjustmentPrayers)
              FTextFormField(
                control: FTextFieldControl.managed(
                  controller: wizard.adjustments[prayer],
                ),
                label: Text(prayer.getLocaleName(l10n)),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
      ],
    );
  }
}

/// A number input field for the wizard.
class NumberField extends StatelessWidget {
  /// Creates a [NumberField] instance.
  const NumberField({
    required this.controller,
    this.dec = true,
    this.signed = false,
    this.label,
    super.key,
  });

  /// The text controller.
  final TextEditingController controller;

  /// Whether to allow decimal input.
  final bool dec;

  /// Whether to allow signed input.
  final bool signed;

  /// Optional field label for accessibility.
  final String? label;

  @override
  Widget build(BuildContext context) => FTextFormField(
    control: FTextFieldControl.managed(controller: controller),
    label: label == null ? null : Text(label!),
    keyboardType: TextInputType.numberWithOptions(decimal: dec, signed: signed),
  );
}
