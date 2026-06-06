import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:tawaq/feature/settings/domain/use_cases/calculation_method_form.dart';

/// Default calculation method used for fallback values.
const OtherCalculationMethod paramDefaults = calculationMethodDefaults;

/// Creates a memoized [TextEditingController] that auto-disposes.
TextEditingController useAutoDisposingController(String initialText) {
  final controller = useMemoized(
    () => TextEditingController(text: initialText),
    const [],
  );
  useEffect(() => controller.dispose, const []);
  return controller;
}

/// Holds all controllers for the custom parameters form.
class ParamControllers {
  /// Creates a new [ParamControllers] instance.
  ParamControllers({
    required this.fajrAngle,
    required this.ishaAngle,
    required this.ishaInterval,
    required this.maghribAngle,
    required this.madhab,
    required this.highLatRule,
    required this.adjustments,
  });

  /// Controller for the Fajr angle.
  final TextEditingController fajrAngle;

  /// Controller for the Isha angle.
  final TextEditingController ishaAngle;

  /// Controller for the Isha interval.
  final TextEditingController ishaInterval;

  /// Controller for the Maghrib angle.
  final TextEditingController maghribAngle;

  /// Controller for the Madhab selection.
  final FSelectController<Madhab> madhab;

  /// Controller for the high latitude rule selection.
  final FSelectController<HighLatitudeRule> highLatRule;

  /// Controllers for per-prayer time adjustments.
  final Map<Prayer, TextEditingController> adjustments;

  /// Syncs all controllers from a [CalculationMethod].
  void syncFrom(CalculationMethod? p) {
    final values = calculationMethodFieldValues(p);
    fajrAngle.text = values.fajrAngle.toString();
    ishaAngle.text = values.ishaAngle.toString();
    ishaInterval.text = values.ishaInterval?.toString() ?? '';
    maghribAngle.text = values.maghribAngle?.toString() ?? '';
    madhab.value = values.madhab;
    highLatRule.value = values.highLatitudeRule;
    for (final prayer in Prayer.values) {
      adjustments[prayer]?.text = (values.adjustments[prayer] ?? 0).toString();
    }
  }

  /// Builds a new [CalculationMethod] from current controller values.
  CalculationMethod toMethod(CalculationMethod? base) {
    return buildCalculationMethod(
      base: base,
      values: CalculationMethodFieldValues(
        fajrAngle: double.tryParse(fajrAngle.text),
        ishaAngle: double.tryParse(ishaAngle.text),
        ishaInterval: int.tryParse(ishaInterval.text),
        maghribAngle: double.tryParse(maghribAngle.text),
        madhab: madhab.value ?? paramDefaults.madhab,
        highLatitudeRule: highLatRule.value ?? paramDefaults.highLatitudeRule,
        adjustments: {
          for (final entry in adjustments.entries)
            entry.key: int.tryParse(entry.value.text),
        },
      ),
    );
  }
}

/// Hook that creates all [ParamControllers] with proper initialization.
ParamControllers useParamControllers(CalculationMethod? initial) {
  final values = calculationMethodFieldValues(initial);

  final fajrAngle = useAutoDisposingController(values.fajrAngle.toString());
  final ishaAngle = useAutoDisposingController(values.ishaAngle.toString());
  final ishaInterval = useAutoDisposingController(
    values.ishaInterval?.toString() ?? '',
  );
  final maghribAngle = useAutoDisposingController(
    values.maghribAngle?.toString() ?? '',
  );

  final madhab = useFSelectController<Madhab>(value: values.madhab);
  final highLatRule = useFSelectController<HighLatitudeRule>(
    value: values.highLatitudeRule,
  );

  final adjustments = useMemoized(
    () => {
      for (final prayer in Prayer.values)
        prayer: TextEditingController(
          text: (values.adjustments[prayer] ?? 0).toString(),
        ),
    },
    const [],
  );
  useEffect(
    () => () {
      for (final c in adjustments.values) {
        c.dispose();
      }
    },
    const [],
  );

  return ParamControllers(
    fajrAngle: fajrAngle,
    ishaAngle: ishaAngle,
    ishaInterval: ishaInterval,
    maghribAngle: maghribAngle,
    madhab: madhab,
    highLatRule: highLatRule,
    adjustments: adjustments,
  );
}
