import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/domain/use_cases/calculation_method_form.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'custom_parameters_draft_provider.g.dart';

/// Keys for numeric custom-parameter text fields.
enum CustomParamFieldKey {
  /// Fajr angle field.
  fajrAngle,

  /// Isha angle field.
  ishaAngle,

  /// Isha interval field.
  ishaInterval,

  /// Maghrib angle field.
  maghribAngle,

  /// Fajr adjustment field.
  adjustmentFajr,

  /// Sunrise adjustment field.
  adjustmentSunrise,

  /// Dhuhr adjustment field.
  adjustmentDhuhr,

  /// Asr adjustment field.
  adjustmentAsr,

  /// Maghrib adjustment field.
  adjustmentMaghrib,

  /// Isha adjustment field.
  adjustmentIsha,
}

/// Owns draft controllers for the custom calculation-parameters form.
@riverpod
class CustomParametersDraft extends _$CustomParametersDraft {
  late final TextEditingController _fajrAngle;
  late final TextEditingController _ishaAngle;
  late final TextEditingController _ishaInterval;
  late final TextEditingController _maghribAngle;
  late final FSelectController<Madhab> _madhab;
  late final FSelectController<HighLatitudeRule> _highLatRule;
  late final Map<Prayer, TextEditingController> _adjustments;

  @override
  bool build() {
    ref.onDispose(_dispose);

    final initial = ref.read(prayerSettingsProvider).value?.method;
    final values = calculationMethodFieldValues(initial);

    _fajrAngle = TextEditingController(text: values.fajrAngle.toString());
    _ishaAngle = TextEditingController(text: values.ishaAngle.toString());
    _ishaInterval = TextEditingController(
      text: values.ishaInterval?.toString() ?? '',
    );
    _maghribAngle = TextEditingController(
      text: values.maghribAngle?.toString() ?? '',
    );
    _madhab = FSelectController<Madhab>(value: values.madhab);
    _highLatRule = FSelectController<HighLatitudeRule>(
      value: values.highLatitudeRule,
    );
    _adjustments = {
      for (final prayer in Prayer.values)
        prayer: TextEditingController(
          text: (values.adjustments[prayer] ?? 0).toString(),
        ),
    };

    ref.listen<CalculationMethod?>(
      prayerSettingsProvider.select(
        (next) => next.value?.method,
      ),
      (_, method) {
        if (method case final m?) {
          syncFrom(m);
        }
      },
    );

    return true;
  }

  /// Madhab selector controller.
  FSelectController<Madhab> get madhab => _madhab;

  /// High-latitude rule selector controller.
  FSelectController<HighLatitudeRule> get highLatRule => _highLatRule;

  /// Text controller for [key].
  TextEditingController textController(CustomParamFieldKey key) {
    return switch (key) {
      CustomParamFieldKey.fajrAngle => _fajrAngle,
      CustomParamFieldKey.ishaAngle => _ishaAngle,
      CustomParamFieldKey.ishaInterval => _ishaInterval,
      CustomParamFieldKey.maghribAngle => _maghribAngle,
      CustomParamFieldKey.adjustmentFajr => _adjustments[Prayer.fajr]!,
      CustomParamFieldKey.adjustmentSunrise => _adjustments[Prayer.sunrise]!,
      CustomParamFieldKey.adjustmentDhuhr => _adjustments[Prayer.dhuhr]!,
      CustomParamFieldKey.adjustmentAsr => _adjustments[Prayer.asr]!,
      CustomParamFieldKey.adjustmentMaghrib => _adjustments[Prayer.maghrib]!,
      CustomParamFieldKey.adjustmentIsha => _adjustments[Prayer.isha]!,
    };
  }

  /// Syncs all controllers from [method].
  void syncFrom(CalculationMethod? method) {
    final values = calculationMethodFieldValues(method);
    _fajrAngle.text = values.fajrAngle.toString();
    _ishaAngle.text = values.ishaAngle.toString();
    _ishaInterval.text = values.ishaInterval?.toString() ?? '';
    _maghribAngle.text = values.maghribAngle?.toString() ?? '';
    _madhab.value = values.madhab;
    _highLatRule.value = values.highLatitudeRule;
    for (final prayer in Prayer.values) {
      _adjustments[prayer]?.text =
          (values.adjustments[prayer] ?? 0).toString();
    }
  }

  /// Builds a [CalculationMethod] from current controller values.
  CalculationMethod toMethod(CalculationMethod? base) {
    return buildCalculationMethod(
      base: base,
      values: CalculationMethodFieldValues(
        fajrAngle: double.tryParse(_fajrAngle.text),
        ishaAngle: double.tryParse(_ishaAngle.text),
        ishaInterval: int.tryParse(_ishaInterval.text),
        maghribAngle: double.tryParse(_maghribAngle.text),
        madhab: _madhab.value ?? calculationMethodDefaults.madhab,
        highLatitudeRule:
            _highLatRule.value ?? calculationMethodDefaults.highLatitudeRule,
        adjustments: {
          for (final entry in _adjustments.entries)
            entry.key: int.tryParse(entry.value.text),
        },
      ),
    );
  }

  void _dispose() {
    _fajrAngle.dispose();
    _ishaAngle.dispose();
    _ishaInterval.dispose();
    _maghribAngle.dispose();
    _madhab.dispose();
    _highLatRule.dispose();
    for (final controller in _adjustments.values) {
      controller.dispose();
    }
  }
}
