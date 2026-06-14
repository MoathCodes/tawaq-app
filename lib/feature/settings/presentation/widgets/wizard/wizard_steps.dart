import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
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
class MethodStep extends StatelessWidget {
  /// Creates a [MethodStep] instance.
  const MethodStep({
    required this.method,
    required this.fajr,
    required this.isha,
    required this.ishaInt,
    required this.maghrib,
    super.key,
  });

  /// The selected calculation method.
  final ValueNotifier<CalculationMethod?> method;

  /// Controller for fajr angle.
  final TextEditingController fajr;

  /// Controller for isha angle.
  final TextEditingController isha;

  /// Controller for isha interval.
  final TextEditingController ishaInt;

  /// Controller for maghrib angle.
  final TextEditingController maghrib;

  @override
  Widget build(BuildContext context) {
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
            value: method.value,
            onChange: (value) => method.value = value,
          ),
          label: Text(l10n.calculationMethod),
          items: {
            for (final m in CalculationMethod.values) m.getLocaleName(l10n): m,
          },
        ),
        if (method.value == CalculationMethod.other) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.customParametersLabel),
          const SizedBox(height: AppSpacing.sm),
          ResponsiveFieldRow(
            children: [
              NumberField(
                ctrl: fajr,
                label: l10n.fajrAngleLabel,
              ),
              NumberField(
                ctrl: isha,
                label: l10n.ishaAngleLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveFieldRow(
            children: [
              NumberField(
                ctrl: ishaInt,
                dec: false,
                label: l10n.ishaIntervalLabel,
              ),
              NumberField(
                ctrl: maghrib,
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
class TimeFormatStep extends StatelessWidget {
  /// Creates a [TimeFormatStep] instance.
  const TimeFormatStep({required this.is24Hours, super.key});

  /// Whether 24-hour format is selected.
  final ValueNotifier<bool> is24Hours;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FSwitch(
      value: is24Hours.value,
      onChange: (v) => is24Hours.value = v,
      label: Text(l10n.use24HourFormat),
    );
  }
}

/// Location configuration step for the start wizard.
class LocationStep extends StatelessWidget {
  /// Creates a [LocationStep] instance.
  const LocationStep({
    required this.name,
    required this.lat,
    required this.lng,
    super.key,
  });

  /// Controller for location name.
  final TextEditingController name;

  /// Controller for latitude.
  final TextEditingController lat;

  /// Controller for longitude.
  final TextEditingController lng;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FTextFormField(
          control: FTextFieldControl.managed(controller: name),
          label: Text(l10n.searchPlaceLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveFieldRow(
          children: [
            NumberField(
              ctrl: lat,
              signed: true,
              label: l10n.latitude,
            ),
            NumberField(
              ctrl: lng,
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
class IqamahStep extends StatelessWidget {
  /// Creates an [IqamahStep] instance.
  const IqamahStep({
    required this.iqamah,
    required this.adjust,
    required this.iqamahPrayers,
    required this.adjustmentPrayers,
    super.key,
  });

  /// Controllers for iqamah times.
  final Map<Prayer, TextEditingController> iqamah;

  /// Controllers for adjustments.
  final Map<Prayer, TextEditingController> adjust;

  /// List of prayers with iqamah times.
  final List<Prayer> iqamahPrayers;

  /// List of prayers with adjustments.
  final List<Prayer> adjustmentPrayers;

  @override
  Widget build(BuildContext context) {
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
            for (final p in iqamahPrayers)
              FTextFormField(
                control: FTextFieldControl.managed(controller: iqamah[p]),
                label: Text(p.getLocaleName(l10n)),
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
            for (final p in adjustmentPrayers)
              FTextFormField(
                control: FTextFieldControl.managed(controller: adjust[p]),
                label: Text(p.getLocaleName(l10n)),
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
    required this.ctrl,
    this.dec = true,
    this.signed = false,
    this.label,
    super.key,
  });

  /// The text controller.
  final TextEditingController ctrl;

  /// Whether to allow decimal input.
  final bool dec;

  /// Whether to allow signed input.
  final bool signed;

  /// Optional field label for accessibility.
  final String? label;

  @override
  Widget build(BuildContext context) => FTextFormField(
    control: FTextFieldControl.managed(controller: ctrl),
    label: label == null ? null : Text(label!),
    keyboardType: TextInputType.numberWithOptions(decimal: dec, signed: signed),
  );
}
