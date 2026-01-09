import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget for the custom prayer parameters section.
class PrayerSettingsCustomParametersCard extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsCustomParametersCard] instance.
  const PrayerSettingsCustomParametersCard({required this.maxWidth, super.key});

  /// The maximum width of the card.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaults = CalculationMethod.other.parameters;

    // Read once on mount, don't watch (to avoid rebuilds)
    final initialParams = useMemoized(
      () => ref.read(prayerSettingsProvider).value?.customParameters,
      const [],
    );

    // Controllers
    final accordionController = useFAccordionController();

    // Angle controllers - created once with initial values
    final fajrAngle = useMemoized(
      () => TextEditingController(
        text: (initialParams?.fajrAngle ?? defaults.fajrAngle).toString(),
      ),
      const [],
    );
    final ishaAngle = useMemoized(
      () => TextEditingController(
        text: (initialParams?.ishaAngle ?? defaults.ishaAngle).toString(),
      ),
      const [],
    );
    final ishaInterval = useMemoized(
      () => TextEditingController(
        text: initialParams?.ishaInterval?.toString() ?? '',
      ),
      const [],
    );
    final maghribAngle = useMemoized(
      () => TextEditingController(
        text: initialParams?.maghribAngle?.toString() ?? '',
      ),
      const [],
    );

    // Dispose angle controllers
    useEffect(
      () => () {
        fajrAngle.dispose();
        ishaAngle.dispose();
        ishaInterval.dispose();
        maghribAngle.dispose();
      },
      const [],
    );

    // Select controllers
    final madhab = useFSelectController<Madhab>(
      initialValue: initialParams?.madhab ?? defaults.madhab,
    );
    final highLatRule = useFSelectController<HighLatitudeRule>(
      initialValue:
          initialParams?.highLatitudeRule ?? defaults.highLatitudeRule,
    );

    // Adjustment controllers
    final adjustments = useMemoized(
      () => {
        for (final prayer in Prayer.values)
          prayer: TextEditingController(
            text: (initialParams?.adjustments[prayer] ?? 0).toString(),
          ),
      },
      const [],
    );

    useEffect(
      () =>
          () => adjustments.values.forEach((c) => c.dispose()),
      const [],
    );

    CalculationParameters buildParams() {
      final currentParams = ref
          .read(prayerSettingsProvider)
          .value
          ?.customParameters;
      return CalculationParameters(
        method: currentParams?.method ?? CalculationMethod.other,
        fajrAngle: double.tryParse(fajrAngle.text) ?? 18.0,
        ishaAngle: double.tryParse(ishaAngle.text) ?? 18.0,
        ishaInterval: int.tryParse(ishaInterval.text),
        maghribAngle: double.tryParse(maghribAngle.text),
        madhab: madhab.value ?? Madhab.shafi,
        highLatitudeRule:
            highLatRule.value ?? HighLatitudeRule.middleOfTheNight,
        adjustments: {
          for (final e in adjustments.entries)
            e.key: int.tryParse(e.value.text) ?? 0,
        },
        methodAdjustments: currentParams?.methodAdjustments ?? const {},
      );
    }

    void syncControllers(CalculationParameters? p) {
      final d = defaults;
      fajrAngle.text = (p?.fajrAngle ?? d.fajrAngle).toString();
      ishaAngle.text = (p?.ishaAngle ?? d.ishaAngle).toString();
      ishaInterval.text = p?.ishaInterval?.toString() ?? '';
      maghribAngle.text = p?.maghribAngle?.toString() ?? '';
      madhab.value = p?.madhab ?? d.madhab;
      highLatRule.value = p?.highLatitudeRule ?? d.highLatitudeRule;
      for (final prayer in Prayer.values) {
        adjustments[prayer]?.text = (p?.adjustments[prayer] ?? 0).toString();
      }
    }

    // Listen for external changes (e.g., calculation method change) to sync controllers
    ref.listen(prayerSettingsProvider, (previous, next) {
      final newParams = next.value?.customParameters;
      if (newParams != null) {
        syncControllers(newParams);
      }
    });

    void save() {
      try {
        ref
            .read(prayerSettingsProvider.notifier)
            .update(
              (s) => s.copyWith(customParameters: buildParams()),
            );
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
      final currentSettings = ref.read(prayerSettingsProvider);
      syncControllers(currentSettings.value?.method.parameters);
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
        control: .managed(controller: accordionController),
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
              fajrAngle: fajrAngle,
              ishaAngle: ishaAngle,
              ishaInterval: ishaInterval,
              maghribAngle: maghribAngle,
              madhab: madhab,
              highLatRule: highLatRule,
              adjustments: adjustments,
              onSave: save,
              onReset: reset,
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.fajrAngle,
    required this.ishaAngle,
    required this.ishaInterval,
    required this.maghribAngle,
    required this.madhab,
    required this.highLatRule,
    required this.adjustments,
    required this.onSave,
    required this.onReset,
  });

  final TextEditingController fajrAngle;
  final TextEditingController ishaAngle;
  final TextEditingController ishaInterval;
  final TextEditingController maghribAngle;
  final FSelectController<Madhab> madhab;
  final FSelectController<HighLatitudeRule> highLatRule;
  final Map<Prayer, TextEditingController> adjustments;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _AngleField(
                      label: l10n.fajrAngleLabel,
                      controller: fajrAngle,
                    ),
                  ),
                  Expanded(
                    child: _AngleField(
                      label: l10n.ishaAngleLabel,
                      controller: ishaAngle,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _IntervalField(
                      label: l10n.ishaIntervalLabel,
                      controller: ishaInterval,
                    ),
                  ),
                  Expanded(
                    child: _AngleField(
                      label: l10n.maghribAngleLabel,
                      controller: maghribAngle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Advanced settings
        FCard(
          title: Text(l10n.advancedSettingsTitle),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: FSelect<Madhab>(
                  control: .managed(controller: madhab),
                  items: {
                    l10n.madhab_shafi: Madhab.shafi,
                    l10n.madhab_hanafi: Madhab.hanafi,
                  },
                  label: Text(l10n.madhabLabel),
                ),
              ),
              Expanded(
                child: FSelect<HighLatitudeRule>(
                  control: .managed(controller: highLatRule),
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
              ),
            ],
          ),
        ),
        // Adjustments
        FCard(
          title: Text(l10n.prayerTimeAdjustmentsTitle),
          child: Column(
            spacing: 12,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _AdjustmentField(
                      label: l10n.fajr,
                      controller: adjustments[Prayer.fajr]!,
                    ),
                  ),
                  Expanded(
                    child: _AdjustmentField(
                      label: l10n.sunrise,
                      controller: adjustments[Prayer.sunrise]!,
                    ),
                  ),
                  Expanded(
                    child: _AdjustmentField(
                      label: l10n.dhuhr,
                      controller: adjustments[Prayer.dhuhr]!,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _AdjustmentField(
                      label: l10n.asr,
                      controller: adjustments[Prayer.asr]!,
                    ),
                  ),
                  Expanded(
                    child: _AdjustmentField(
                      label: l10n.maghrib,
                      controller: adjustments[Prayer.maghrib]!,
                    ),
                  ),
                  Expanded(
                    child: _AdjustmentField(
                      label: l10n.isha,
                      controller: adjustments[Prayer.isha]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Action buttons
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: FButton(
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
            ),
            Expanded(
              child: FButton(
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
            ),
          ],
        ),
      ],
    );
  }
}

class _AngleField extends StatelessWidget {
  const _AngleField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      control: .managed(controller: controller),
      label: Text(label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      hint: '0.0',
    );
  }
}

class _IntervalField extends StatelessWidget {
  const _IntervalField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      control: .managed(controller: controller),
      label: Text(label),
      keyboardType: TextInputType.number,
      hint: context.l10n.optionalHint,
    );
  }
}

class _AdjustmentField extends StatelessWidget {
  const _AdjustmentField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      control: .managed(controller: controller),
      label: Text(label),
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      hint: '0',
    );
  }
}
