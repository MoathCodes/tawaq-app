import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';

/// Default calculation method used for fallback values.
const OtherCalculationMethod paramDefaults = CalculationMethod.other;

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
    fajrAngle.text = (p?.fajrAngle ?? paramDefaults.fajrAngle).toString();
    ishaAngle.text = (p?.ishaAngle ?? paramDefaults.ishaAngle).toString();
    ishaInterval.text = p?.ishaInterval?.toString() ?? '';
    maghribAngle.text = p?.maghribAngle?.toString() ?? '';
    madhab.value = p?.madhab ?? paramDefaults.madhab;
    highLatRule.value = p?.highLatitudeRule ?? paramDefaults.highLatitudeRule;
    for (final prayer in Prayer.values) {
      adjustments[prayer]?.text = (p?.adjustments[prayer] ?? 0).toString();
    }
  }

  /// Builds a new [CalculationMethod] from current controller values.
  CalculationMethod toMethod(CalculationMethod? base) {
    final newAdjustments = <Prayer, int>{
      for (final e in adjustments.entries) e.key: ?int.tryParse(e.value.text),
    };

    final newMethod = base?.copyWith(
      fajrAngle: double.tryParse(fajrAngle.text),
      ishaAngle: double.tryParse(ishaAngle.text),
      ishaInterval: int.tryParse(ishaInterval.text),
      maghribAngle: double.tryParse(maghribAngle.text),
      madhab: madhab.value,
      highLatitudeRule: highLatRule.value,
      adjustments: newAdjustments.isEmpty ? null : newAdjustments,
    );

    if (newMethod?.props.toString() == base?.props.toString()) {
      return base ?? const UmmAlQura();
    }
    return newMethod ?? const UmmAlQura();
  }
}

/// Hook that creates all [ParamControllers] with proper initialization.
ParamControllers useParamControllers(CalculationMethod? initial) {
  final p = initial;

  final fajrAngle = useAutoDisposingController(
    (p?.fajrAngle ?? paramDefaults.fajrAngle).toString(),
  );
  final ishaAngle = useAutoDisposingController(
    (p?.ishaAngle ?? paramDefaults.ishaAngle).toString(),
  );
  final ishaInterval = useAutoDisposingController(
    p?.ishaInterval?.toString() ?? '',
  );
  final maghribAngle = useAutoDisposingController(
    p?.maghribAngle?.toString() ?? '',
  );

  final madhab = useFSelectController<Madhab>(
    value: p?.madhab ?? paramDefaults.madhab,
  );
  final highLatRule = useFSelectController<HighLatitudeRule>(
    value: p?.highLatitudeRule ?? paramDefaults.highLatitudeRule,
  );

  final adjustments = useMemoized(
    () => {
      for (final prayer in Prayer.values)
        prayer: TextEditingController(
          text: (p?.adjustments[prayer] ?? 0).toString(),
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
