import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// =============================================================================
// Constants
// =============================================================================

const OtherCalculationMethod _defaults = CalculationMethod.other;

// =============================================================================
// Custom Hook for TextEditingController
// =============================================================================

/// Creates a memoized TextEditingController that auto-disposes.
TextEditingController _useController(String initialText) {
  final controller = useMemoized(
    () => TextEditingController(text: initialText),
    const [],
  );
  useEffect(() => controller.dispose, const []);
  return controller;
}

// =============================================================================
// Main Widget
// =============================================================================

/// Widget for the custom prayer parameters section.
class PrayerSettingsCustomParametersCard extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsCustomParametersCard] instance.
  const PrayerSettingsCustomParametersCard({required this.maxWidth, super.key});

  /// The maximum width of the section.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read once on mount
    final initial = useMemoized(
      () => ref.read(prayerSettingsProvider).value?.method,
      const [],
    );

    // Controllers - all created with initial values
    final controllers = _useParamControllers(initial);

    // Sync controllers when external changes occur
    // (e.g., calculation method change)
    ref.listen(prayerSettingsProvider, (_, next) {
      if (next.value?.method case final m?) controllers.syncFrom(m);
    });

    void save() {
      try {
        final method = ref.read(prayerSettingsProvider).value?.method;
        final newMethod = controllers.toMethod(method);
        if (newMethod != method) {
          unawaited(
            ref
                .read(prayerSettingsProvider.notifier)
                .update(
                  (s) => s.copyWith(method: newMethod),
                ),
          );
        }
        showFToast(
          context: context,
          title: Text(context.l10n.parametersSavedTitle),
          description: Text(context.l10n.parametersSavedDescription),
        );
      } catch (e) {
        showFToast(
          context: context,
          title: Text(context.l10n.invalidParametersTitle),
          description: Text('${context.l10n.invalidParametersDescription} $e'),
        );
      }
    }

    void reset() {
      final current = ref.read(prayerSettingsProvider).value?.method;
      controllers.syncFrom(current);
      save();
      showFToast(
        context: context,
        title: Text(context.l10n.resetCompleteTitle),
        description: Text(context.l10n.resetCompleteDescription),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FAccordion(
        control: .managed(controller: useFAccordionController()),
        style: (style) => style.copyWith(
          dividerStyle: FDividerStyle(
            color: Colors.transparent,
            padding: EdgeInsetsGeometry.zero,
          ).call,
        ),
        children: [
          FAccordionItem(
            title: Text(context.l10n.customParametersTitle),
            child: _Content(
              controllers: controllers,
              onSave: save,
              onReset: reset,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Controllers Container
// =============================================================================

/// Holds all controllers for the custom parameters form.
class _ParamControllers {
  _ParamControllers({
    required this.fajrAngle,
    required this.ishaAngle,
    required this.ishaInterval,
    required this.maghribAngle,
    required this.madhab,
    required this.highLatRule,
    required this.adjustments,
  });

  final TextEditingController fajrAngle;
  final TextEditingController ishaAngle;
  final TextEditingController ishaInterval;
  final TextEditingController maghribAngle;
  final FSelectController<Madhab> madhab;
  final FSelectController<HighLatitudeRule> highLatRule;
  final Map<Prayer, TextEditingController> adjustments;

  /// Syncs all controllers from a CalculationMethod.
  void syncFrom(CalculationMethod? p) {
    fajrAngle.text = (p?.fajrAngle ?? _defaults.fajrAngle).toString();
    ishaAngle.text = (p?.ishaAngle ?? _defaults.ishaAngle).toString();
    ishaInterval.text = p?.ishaInterval?.toString() ?? '';
    maghribAngle.text = p?.maghribAngle?.toString() ?? '';
    madhab.value = p?.madhab ?? _defaults.madhab;
    highLatRule.value = p?.highLatitudeRule ?? _defaults.highLatitudeRule;
    for (final prayer in Prayer.values) {
      adjustments[prayer]?.text = (p?.adjustments[prayer] ?? 0).toString();
    }
  }

  /// Builds a new CalculationMethod from current controller values.
  CalculationMethod toMethod(CalculationMethod? base) {
    // Only include non-zero adjustments
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

    // Return original if unchanged
    if (newMethod?.props.toString() == base?.props.toString()) {
      return base ?? const UmmAlQura();
    }
    return newMethod ?? const UmmAlQura();
  }
}

/// Creates all parameter controllers with proper initialization.
_ParamControllers _useParamControllers(CalculationMethod? initial) {
  final p = initial;

  // Angle controllers
  final fajrAngle = _useController(
    (p?.fajrAngle ?? _defaults.fajrAngle).toString(),
  );
  final ishaAngle = _useController(
    (p?.ishaAngle ?? _defaults.ishaAngle).toString(),
  );
  final ishaInterval = _useController(p?.ishaInterval?.toString() ?? '');
  final maghribAngle = _useController(p?.maghribAngle?.toString() ?? '');

  // Select controllers
  final madhab = useFSelectController<Madhab>(
    value: p?.madhab ?? _defaults.madhab,
  );
  final highLatRule = useFSelectController<HighLatitudeRule>(
    value: p?.highLatitudeRule ?? _defaults.highLatitudeRule,
  );

  // Adjustment controllers - one for each prayer
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

  return _ParamControllers(
    fajrAngle: fajrAngle,
    ishaAngle: ishaAngle,
    ishaInterval: ishaInterval,
    maghribAngle: maghribAngle,
    madhab: madhab,
    highLatRule: highLatRule,
    adjustments: adjustments,
  );
}

// =============================================================================
// Content Widget
// =============================================================================

class _Content extends StatelessWidget {
  const _Content({
    required this.controllers,
    required this.onSave,
    required this.onReset,
  });

  final _ParamControllers controllers;
  final VoidCallback onSave;
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
              _FieldRow([
                _NumericField(
                  label: l10n.fajrAngleLabel,
                  controller: c.fajrAngle,
                  decimal: true,
                ),
                _NumericField(
                  label: l10n.ishaAngleLabel,
                  controller: c.ishaAngle,
                  decimal: true,
                ),
              ]),
              _FieldRow([
                _NumericField(
                  label: l10n.ishaIntervalLabel,
                  controller: c.ishaInterval,
                  hint: l10n.optionalHint,
                ),
                _NumericField(
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
          child: _FieldRow([
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
              _FieldRow([
                _NumericField(
                  label: l10n.fajr,
                  controller: c.adjustments[Prayer.fajr]!,
                  signed: true,
                ),
                _NumericField(
                  label: l10n.sunrise,
                  controller: c.adjustments[Prayer.sunrise]!,
                  signed: true,
                ),
                _NumericField(
                  label: l10n.dhuhr,
                  controller: c.adjustments[Prayer.dhuhr]!,
                  signed: true,
                ),
              ]),
              _FieldRow([
                _NumericField(
                  label: l10n.asr,
                  controller: c.adjustments[Prayer.asr]!,
                  signed: true,
                ),
                _NumericField(
                  label: l10n.maghrib,
                  controller: c.adjustments[Prayer.maghrib]!,
                  signed: true,
                ),
                _NumericField(
                  label: l10n.isha,
                  controller: c.adjustments[Prayer.isha]!,
                  signed: true,
                ),
              ]),
            ],
          ),
        ),
        // Action buttons
        _FieldRow([
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

// =============================================================================
// Helper Widgets
// =============================================================================

/// A row of expanded widgets with consistent spacing.
class _FieldRow extends StatelessWidget {
  const _FieldRow(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [for (final child in children) Expanded(child: child)],
    );
  }
}

/// Generic numeric field that consolidates angle, interval,
/// and adjustment fields.
class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.label,
    required this.controller,
    this.decimal = false,
    this.signed = false,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final bool signed;
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
