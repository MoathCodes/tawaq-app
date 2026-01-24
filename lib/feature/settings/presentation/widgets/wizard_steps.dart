import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';

/// Welcome step for the start wizard.
class WelcomeStep extends StatelessWidget {
  /// Creates a [WelcomeStep] instance.
  const WelcomeStep({required this.l10n, super.key});

  /// Localization strings.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        l10n.setupPrayerSettingsTitle,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.setupPrayerSettingsSubtitle),
    ],
  );
}

/// Calculation method selection step for the start wizard.
class MethodStep extends StatelessWidget {
  /// Creates a [MethodStep] instance.
  const MethodStep({
    required this.l10n,
    required this.method,
    required this.fajr,
    required this.isha,
    required this.ishaInt,
    required this.maghrib,
    super.key,
  });

  /// Localization strings.
  final AppLocalizations l10n;

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(l10n.chooseCalculationMethod),
      const SizedBox(height: AppSpacing.sm),
      FSelect<CalculationMethod>(
        items: {
          for (final m in CalculationMethod.values) m.getLocaleName(l10n): m,
        },
      ),
      if (method.value == CalculationMethod.other) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.customParametersLabel),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: NumberField(ctrl: fajr)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: NumberField(ctrl: isha)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: NumberField(ctrl: ishaInt, dec: false)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: NumberField(ctrl: maghrib)),
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

/// Time format selection step for the start wizard.
class TimeFormatStep extends StatelessWidget {
  /// Creates a [TimeFormatStep] instance.
  const TimeFormatStep({
    required this.l10n,
    required this.is24Hours,
    super.key,
  });

  /// Localization strings.
  final AppLocalizations l10n;

  /// Whether 24-hour format is selected.
  final ValueNotifier<bool> is24Hours;

  @override
  Widget build(BuildContext context) => Material(
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.use24HourFormat),
      value: is24Hours.value,
      onChanged: (v) => is24Hours.value = v,
    ),
  );
}

/// Location configuration step for the start wizard.
class LocationStep extends StatelessWidget {
  /// Creates a [LocationStep] instance.
  const LocationStep({
    required this.l10n,
    required this.name,
    required this.lat,
    required this.lng,
    super.key,
  });

  /// Localization strings.
  final AppLocalizations l10n;

  /// Controller for location name.
  final TextEditingController name;

  /// Controller for latitude.
  final TextEditingController lat;

  /// Controller for longitude.
  final TextEditingController lng;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      FTextFormField(control: FTextFieldControl.managed(controller: name)),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(child: NumberField(ctrl: lat, signed: true)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: NumberField(ctrl: lng, signed: true)),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          FButton(
            onPress: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.deviceLocationNotImplemented)),
            ),
            child: Text(l10n.useDeviceLocation),
          ),
          const SizedBox(width: AppSpacing.sm),
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

/// Iqamah and adjustments configuration step for the start wizard.
class IqamahStep extends StatelessWidget {
  /// Creates an [IqamahStep] instance.
  const IqamahStep({
    required this.l10n,
    required this.iqamah,
    required this.adjust,
    required this.iqamahPrayers,
    required this.adjustmentPrayers,
    super.key,
  });

  /// Localization strings.
  final AppLocalizations l10n;

  /// Controllers for iqamah times.
  final Map<Prayer, TextEditingController> iqamah;

  /// Controllers for adjustments.
  final Map<Prayer, TextEditingController> adjust;

  /// List of prayers with iqamah times.
  final List<Prayer> iqamahPrayers;

  /// List of prayers with adjustments.
  final List<Prayer> adjustmentPrayers;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.iqamahAfterAdhan),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: iqamahPrayers
              .map(
                (p) => SizedBox(
                  width: 140,
                  child: FTextFormField(
                    control: FTextFieldControl.managed(controller: iqamah[p]),
                    keyboardType: TextInputType.number,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.adhanAdjustments),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: adjustmentPrayers
              .map(
                (p) => SizedBox(
                  width: 140,
                  child: FTextFormField(
                    control: FTextFieldControl.managed(controller: adjust[p]),
                    keyboardType: TextInputType.number,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

/// A number input field for the wizard.
class NumberField extends StatelessWidget {
  /// Creates a [NumberField] instance.
  const NumberField({
    required this.ctrl,
    this.dec = true,
    this.signed = false,
    super.key,
  });

  /// The text controller.
  final TextEditingController ctrl;

  /// Whether to allow decimal input.
  final bool dec;

  /// Whether to allow signed input.
  final bool signed;

  @override
  Widget build(BuildContext context) => FTextFormField(
    control: FTextFieldControl.managed(controller: ctrl),
    keyboardType: TextInputType.numberWithOptions(decimal: dec, signed: signed),
  );
}
