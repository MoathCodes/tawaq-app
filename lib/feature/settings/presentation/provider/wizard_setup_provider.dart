import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/domain/use_cases/calculation_method_form.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'wizard_setup_provider.g.dart';

/// Prayers with iqamah fields in the setup wizard.
const List<Prayer> kWizardIqamahPrayers = <Prayer>[
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Prayers with adhan adjustment fields in the setup wizard.
const List<Prayer> kWizardAdjustmentPrayers = <Prayer>[
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Current wizard step index and selected options.
class WizardSetupState {
  /// Creates [WizardSetupState].
  const WizardSetupState({
    required this.step,
    required this.method,
    required this.is24Hours,
  });

  /// Active step (0–4).
  final int step;

  /// Selected calculation method.
  final CalculationMethod? method;

  /// Whether 24-hour time format is selected.
  final bool is24Hours;

  /// Initial wizard state.
  static const initial = WizardSetupState(
    step: 0,
    method: null,
    is24Hours: false,
  );
}

/// Ephemeral setup-wizard state and field controllers.
@riverpod
class WizardSetup extends _$WizardSetup {
  /// Fajr angle field for custom calculation method.
  late final TextEditingController fajrAngle;

  /// Isha angle field for custom calculation method.
  late final TextEditingController ishaAngle;

  /// Isha interval field for custom calculation method.
  late final TextEditingController ishaInterval;

  /// Maghrib angle field for custom calculation method.
  late final TextEditingController maghribAngle;

  /// Location display name field.
  late final TextEditingController locationName;

  /// Latitude field.
  late final TextEditingController latitude;

  /// Longitude field.
  late final TextEditingController longitude;

  /// Iqamah offset fields keyed by prayer.
  late final Map<Prayer, TextEditingController> iqamah;

  /// Adhan adjustment fields keyed by prayer.
  late final Map<Prayer, TextEditingController> adjustments;

  @override
  WizardSetupState build() {
    ref.onDispose(_dispose);

    fajrAngle = TextEditingController(text: '18.0');
    ishaAngle = TextEditingController(text: '18.0');
    ishaInterval = TextEditingController();
    maghribAngle = TextEditingController();
    locationName = TextEditingController();
    latitude = TextEditingController();
    longitude = TextEditingController();
    iqamah = {
      for (final prayer in kWizardIqamahPrayers)
        prayer: TextEditingController(),
    };
    adjustments = {
      for (final prayer in kWizardAdjustmentPrayers)
        prayer: TextEditingController(text: '0'),
    };

    return WizardSetupState.initial;
  }

  /// Updates the selected calculation method.
  void setMethod(CalculationMethod? method) {
    state = WizardSetupState(
      step: state.step,
      method: method,
      is24Hours: state.is24Hours,
    );
  }

  /// Updates the 24-hour format toggle.
  void setIs24Hours({required bool value}) {
    state = WizardSetupState(
      step: state.step,
      method: state.method,
      is24Hours: value,
    );
  }

  /// Advances to the next step or persists settings on the last step.
  void next(BuildContext context) {
    final l10n = context.l10n;
    if (state.step == 1 && state.method == null) {
      showFToast(context: context, title: Text(l10n.pleaseSelectMethod));
      return;
    }

    if (state.step < 4) {
      state = WizardSetupState(
        step: state.step + 1,
        method: state.method,
        is24Hours: state.is24Hours,
      );
      return;
    }

    persist();
    Navigator.of(context).pop();
  }

  /// Goes back one step.
  void back() {
    if (state.step == 0) return;
    state = WizardSetupState(
      step: state.step - 1,
      method: state.method,
      is24Hours: state.is24Hours,
    );
  }

  /// Writes wizard values to persisted prayer settings.
  void persist() {
    final notifier = ref.read(prayerSettingsProvider.notifier);
    final current = ref.read(prayerSettingsProvider).value;
    if (current == null) return;

    final baseMethod = state.method ?? CalculationMethod.ummAlQura;
    final fieldValues = calculationMethodFieldValues(baseMethod);

    final method = buildCalculationMethod(
      base: baseMethod,
      values: CalculationMethodFieldValues(
        fajrAngle: baseMethod == CalculationMethod.other
            ? double.tryParse(fajrAngle.text)
            : fieldValues.fajrAngle,
        ishaAngle: baseMethod == CalculationMethod.other
            ? double.tryParse(ishaAngle.text)
            : fieldValues.ishaAngle,
        ishaInterval: baseMethod == CalculationMethod.other
            ? int.tryParse(ishaInterval.text)
            : fieldValues.ishaInterval,
        maghribAngle: baseMethod == CalculationMethod.other
            ? double.tryParse(maghribAngle.text)
            : fieldValues.maghribAngle,
        madhab: fieldValues.madhab,
        highLatitudeRule: fieldValues.highLatitudeRule,
        adjustments: {
          for (final prayer in kWizardAdjustmentPrayers)
            prayer: int.tryParse(adjustments[prayer]!.text),
        },
      ),
    );

    final iqamahSettings = {
      for (final prayer in kWizardIqamahPrayers)
        prayer: int.tryParse(iqamah[prayer]!.text.trim()) ?? 0,
    };

    final lat = double.tryParse(latitude.text.trim());
    final lng = double.tryParse(longitude.text.trim());
    final coordinates = lat != null && lng != null
        ? Coordinates(lat, lng)
        : current.coordinates;
    final name = locationName.text.trim();

    unawaited(
      notifier.update(
        (settings) => settings.copyWith(
          method: method,
          is24Hours: state.is24Hours,
          iqamahSettings: iqamahSettings,
          coordinates: coordinates,
          locationName: name.isEmpty ? settings.locationName : name,
        ),
      ),
    );
  }

  void _dispose() {
    fajrAngle.dispose();
    ishaAngle.dispose();
    ishaInterval.dispose();
    maghribAngle.dispose();
    locationName.dispose();
    latitude.dispose();
    longitude.dispose();
    for (final controller in [...iqamah.values, ...adjustments.values]) {
      controller.dispose();
    }
  }
}
