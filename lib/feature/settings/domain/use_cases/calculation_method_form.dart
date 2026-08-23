import 'package:adhan_dart/adhan_dart.dart';

/// Default calculation method used for fallback values.
const OtherCalculationMethod calculationMethodDefaults = CalculationMethod.other;

/// Field values for building a custom [CalculationMethod].
class CalculationMethodFieldValues {
  /// Creates field values parsed from a form.
  const new({
    required this.fajrAngle,
    required this.ishaAngle,
    required this.ishaInterval,
    required this.maghribAngle,
    required this.madhab,
    required this.highLatitudeRule,
    required this.adjustments,
  });

  /// Parsed Fajr angle.
  final double? fajrAngle;

  /// Parsed Isha angle.
  final double? ishaAngle;

  /// Parsed Isha interval.
  final int? ishaInterval;

  /// Parsed Maghrib angle.
  final double? maghribAngle;

  /// Selected madhab.
  final Madhab madhab;

  /// Selected high-latitude rule.
  final HighLatitudeRule highLatitudeRule;

  /// Per-prayer minute adjustments.
  final Map<Prayer, int?> adjustments;
}

/// Default field values for a [CalculationMethod].
CalculationMethodFieldValues calculationMethodFieldValues(
  CalculationMethod? method,
) {
  final base = method ?? calculationMethodDefaults;
  return CalculationMethodFieldValues(
    fajrAngle: base.fajrAngle,
    ishaAngle: base.ishaAngle,
    ishaInterval: base.ishaInterval,
    maghribAngle: base.maghribAngle,
    madhab: base.madhab,
    highLatitudeRule: base.highLatitudeRule,
    adjustments: {
      for (final prayer in Prayer.values) prayer: base.adjustments[prayer],
    },
  );
}

/// Builds a [CalculationMethod] from parsed field values.
CalculationMethod buildCalculationMethod({
  required CalculationMethod? base,
  required CalculationMethodFieldValues values,
}) {
  final newAdjustments = <Prayer, int>{
    for (final entry in values.adjustments.entries)
      if (entry.value != null) entry.key: entry.value!,
  };

  final newMethod = base?.copyWith(
    fajrAngle: values.fajrAngle,
    ishaAngle: values.ishaAngle,
    ishaInterval: values.ishaInterval,
    maghribAngle: values.maghribAngle,
    madhab: values.madhab,
    highLatitudeRule: values.highLatitudeRule,
    adjustments: newAdjustments.isEmpty ? null : newAdjustments,
  );

  if (newMethod?.props.toString() == base?.props.toString()) {
    return base ?? const UmmAlQura();
  }
  return newMethod ?? const UmmAlQura();
}
