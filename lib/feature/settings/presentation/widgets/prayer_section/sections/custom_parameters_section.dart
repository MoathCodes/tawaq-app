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
    final prayerSettings = ref.read(prayerSettingsProvider);
    final customParams = prayerSettings.value?.customParameters;
    final defaultParams = CalculationMethod.other.parameters;

    // Controllers
    final accordionController = useFAccordionController();

    // Text controllers for angles
    final fajrAngleController = useMemoized(
      () => TextEditingController(
        text:
            customParams?.fajrAngle.toString() ??
            defaultParams.fajrAngle.toString(),
      ),
    );
    final ishaAngleController = useMemoized(
      () => TextEditingController(
        text:
            customParams?.ishaAngle.toString() ??
            defaultParams.ishaAngle.toString(),
      ),
    );
    final ishaIntervalController = useMemoized(
      () => TextEditingController(
        text:
            customParams?.ishaInterval?.toString() ??
            defaultParams.ishaInterval?.toString() ??
            '',
      ),
    );
    final maghribAngleController = useMemoized(
      () => TextEditingController(
        text:
            customParams?.maghribAngle?.toString() ??
            defaultParams.maghribAngle?.toString() ??
            '',
      ),
    );

    // Select controllers (need vsync)
    final madhabController = useFSelectController<Madhab>(
      initialValue: customParams?.madhab ?? defaultParams.madhab,
    );
    final highLatitudeRuleController = useFSelectController<HighLatitudeRule>(
      initialValue:
          customParams?.highLatitudeRule ?? defaultParams.highLatitudeRule,
    );

    // Adjustment controllers
    final fajrAdjustmentController = useMemoized(
      () => TextEditingController(
        text:
            (customParams?.adjustments[Prayer.fajr] ??
                    defaultParams.adjustments[Prayer.fajr] ??
                    0)
                .toString(),
      ),
    );
    final sunriseAdjustmentController = useMemoized(
      () => TextEditingController(
        text:
            (customParams?.adjustments[Prayer.sunrise] ??
                    defaultParams.adjustments[Prayer.sunrise] ??
                    0)
                .toString(),
      ),
    );
    final dhuhrAdjustmentController = useMemoized(
      () => TextEditingController(
        text:
            (customParams?.adjustments[Prayer.dhuhr] ??
                    defaultParams.adjustments[Prayer.dhuhr] ??
                    0)
                .toString(),
      ),
    );
    final asrAdjustmentController = useMemoized(
      () => TextEditingController(
        text:
            (customParams?.adjustments[Prayer.asr] ??
                    defaultParams.adjustments[Prayer.asr] ??
                    0)
                .toString(),
      ),
    );
    final maghribAdjustmentController = useMemoized(
      () => TextEditingController(
        text:
            (customParams?.adjustments[Prayer.maghrib] ??
                    defaultParams.adjustments[Prayer.maghrib] ??
                    0)
                .toString(),
      ),
    );
    final ishaAdjustmentController = useMemoized(
      () => TextEditingController(
        text:
            (customParams?.adjustments[Prayer.isha] ??
                    defaultParams.adjustments[Prayer.isha] ??
                    0)
                .toString(),
      ),
    );

    // Dispose all memoized controllers
    useEffect(
      () {
        return () {
          fajrAngleController.dispose();
          ishaAngleController.dispose();
          ishaIntervalController.dispose();
          maghribAngleController.dispose();
          fajrAdjustmentController.dispose();
          sunriseAdjustmentController.dispose();
          dhuhrAdjustmentController.dispose();
          asrAdjustmentController.dispose();
          maghribAdjustmentController.dispose();
          ishaAdjustmentController.dispose();
        };
      },
      const [],
    );

    void updateControllers(CalculationParameters? params) {
      final dp = CalculationMethod.other.parameters;

      fajrAngleController.text =
          params?.fajrAngle.toString() ?? dp.fajrAngle.toString();

      ishaAngleController.text =
          params?.ishaAngle.toString() ?? dp.ishaAngle.toString();

      ishaIntervalController.text =
          params?.ishaInterval?.toString() ?? dp.ishaInterval?.toString() ?? '';

      maghribAngleController.text =
          params?.maghribAngle?.toString() ?? dp.maghribAngle?.toString() ?? '';

      madhabController.value = params?.madhab ?? dp.madhab;

      highLatitudeRuleController.value =
          params?.highLatitudeRule ?? dp.highLatitudeRule;

      fajrAdjustmentController.text =
          (params?.adjustments[Prayer.fajr] ?? dp.adjustments[Prayer.fajr] ?? 0)
              .toString();

      sunriseAdjustmentController.text =
          (params?.adjustments[Prayer.sunrise] ??
                  dp.adjustments[Prayer.sunrise] ??
                  0)
              .toString();

      dhuhrAdjustmentController.text =
          (params?.adjustments[Prayer.dhuhr] ??
                  dp.adjustments[Prayer.dhuhr] ??
                  0)
              .toString();

      asrAdjustmentController.text =
          (params?.adjustments[Prayer.asr] ?? dp.adjustments[Prayer.asr] ?? 0)
              .toString();

      maghribAdjustmentController.text =
          (params?.adjustments[Prayer.maghrib] ??
                  dp.adjustments[Prayer.maghrib] ??
                  0)
              .toString();

      ishaAdjustmentController.text =
          (params?.adjustments[Prayer.isha] ?? dp.adjustments[Prayer.isha] ?? 0)
              .toString();
    }

    void updateCustomParameters() {
      try {
        final params = ref.read(prayerSettingsProvider).value?.customParameters;
        final fajrAngle = double.tryParse(fajrAngleController.text) ?? 18.0;
        final ishaAngle = double.tryParse(ishaAngleController.text) ?? 18.0;
        final ishaInterval = ishaIntervalController.text.isEmpty
            ? null
            : int.tryParse(ishaIntervalController.text);
        final maghribAngle = maghribAngleController.text.isEmpty
            ? null
            : double.tryParse(maghribAngleController.text);

        final adjustments = {
          Prayer.fajr: int.tryParse(fajrAdjustmentController.text) ?? 0,
          Prayer.sunrise: int.tryParse(sunriseAdjustmentController.text) ?? 0,
          Prayer.dhuhr: int.tryParse(dhuhrAdjustmentController.text) ?? 0,
          Prayer.asr: int.tryParse(asrAdjustmentController.text) ?? 0,
          Prayer.maghrib: int.tryParse(maghribAdjustmentController.text) ?? 0,
          Prayer.isha: int.tryParse(ishaAdjustmentController.text) ?? 0,
        };

        final customParameters = CalculationParameters(
          method: params?.method ?? CalculationMethod.other,
          fajrAngle: fajrAngle,
          ishaAngle: ishaAngle,
          ishaInterval: ishaInterval,
          maghribAngle: maghribAngle,
          madhab: madhabController.value ?? Madhab.shafi,
          highLatitudeRule:
              highLatitudeRuleController.value ??
              HighLatitudeRule.middleOfTheNight,
          adjustments: adjustments,
          methodAdjustments:
              params?.methodAdjustments ??
              const {
                Prayer.fajr: 0,
                Prayer.sunrise: 0,
                Prayer.dhuhr: 0,
                Prayer.asr: 0,
                Prayer.maghrib: 0,
                Prayer.isha: 0,
              },
        );

        ref
            .read(prayerSettingsProvider.notifier)
            .update(
              (settings) =>
                  settings.copyWith(customParameters: customParameters),
            );
      } catch (e) {
        showFToast(
          context: context,
          title: Text(context.l10n.invalidParametersTitle),
          description: Text(
            '${context.l10n.invalidParametersDescription} $e',
          ),
        );
      }
    }

    void resetToDefaults() {
      updateControllers(
        ref.read(prayerSettingsProvider).value?.method.parameters,
      );

      updateCustomParameters();

      showFToast(
        context: context,
        title: Text(context.l10n.resetCompleteTitle),
        description: Text(context.l10n.resetCompleteDescription),
      );
    }

    void saveCustomParameters() {
      updateCustomParameters();
      showFToast(
        context: context,
        title: Text(context.l10n.parametersSavedTitle),
        description: Text(context.l10n.parametersSavedDescription),
      );
    }

    // Listen for external updates
    ref.listen(
      prayerSettingsProvider,
      (previous, next) {
        updateControllers(next.value?.customParameters);
      },
      onError: (error, stackTrace) {
        showFToast(
          context: context,
          title: Text(
            context.l10n.errorOccurredWhile(
              context.l10n.errorOccurredWhile(
                context.l10n.customParametersTitle,
              ),
            ),
          ),
          description: Text(error.toString()),
        );
      },
    );

    return Padding(
      padding: const .symmetric(horizontal: 2),
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
            child: _buildCustomParametersContent(
              context,
              ref,
              fajrAngleController,
              ishaAngleController,
              ishaIntervalController,
              maghribAngleController,
              madhabController,
              highLatitudeRuleController,
              fajrAdjustmentController,
              sunriseAdjustmentController,
              dhuhrAdjustmentController,
              asrAdjustmentController,
              maghribAdjustmentController,
              ishaAdjustmentController,
              updateCustomParameters,
              resetToDefaults,
              saveCustomParameters,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCustomParametersContent(
  BuildContext context,
  WidgetRef ref,
  TextEditingController fajrAngleController,
  TextEditingController ishaAngleController,
  TextEditingController ishaIntervalController,
  TextEditingController maghribAngleController,
  FSelectController<Madhab> madhabController,
  FSelectController<HighLatitudeRule> highLatitudeRuleController,
  TextEditingController fajrAdjustmentController,
  TextEditingController sunriseAdjustmentController,
  TextEditingController dhuhrAdjustmentController,
  TextEditingController asrAdjustmentController,
  TextEditingController maghribAdjustmentController,
  TextEditingController ishaAdjustmentController,
  VoidCallback updateCustomParameters,
  VoidCallback resetToDefaults,
  VoidCallback saveCustomParameters,
) {
  return Column(
    spacing: 16,
    children: [
      const SizedBox(height: AppSpacing.sm),
      _buildBasicParametersCard(
        context,
        fajrAngleController,
        ishaAngleController,
        ishaIntervalController,
        maghribAngleController,
      ),
      _buildAdvancedParametersCard(
        context,
        madhabController,
        highLatitudeRuleController,
        updateCustomParameters,
      ),
      _buildAdjustmentsCard(
        context,
        fajrAdjustmentController,
        sunriseAdjustmentController,
        dhuhrAdjustmentController,
        asrAdjustmentController,
        maghribAdjustmentController,
        ishaAdjustmentController,
      ),
      _buildActionButtons(context, resetToDefaults, saveCustomParameters),
    ],
  );
}

Widget _buildActionButtons(
  BuildContext context,
  VoidCallback resetToDefaults,
  VoidCallback saveCustomParameters,
) {
  return Column(
    spacing: 12,
    children: [
      Row(
        spacing: 12,
        children: [
          Expanded(
            child: FButton(
              style: FButtonStyle.secondary(),
              onPress: resetToDefaults,
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  const Icon(FIcons.rotateCcw, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(context.l10n.resetToDefaults),
                ],
              ),
            ),
          ),
          Expanded(
            child: FButton(
              onPress: saveCustomParameters,
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  const Icon(FIcons.save, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(context.l10n.saveParameters),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildAdjustmentField(
  BuildContext context,
  String label,
  TextEditingController controller,
) {
  return FTextField(
    control: .managed(controller: controller),
    label: Text(label),
    keyboardType: const TextInputType.numberWithOptions(signed: true),
    hint: '0',
  );
}

Widget _buildAdjustmentsCard(
  BuildContext context,
  TextEditingController fajrAdjustmentController,
  TextEditingController sunriseAdjustmentController,
  TextEditingController dhuhrAdjustmentController,
  TextEditingController asrAdjustmentController,
  TextEditingController maghribAdjustmentController,
  TextEditingController ishaAdjustmentController,
) {
  return FCard(
    title: Text(context.l10n.prayerTimeAdjustmentsTitle),
    child: Column(
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildAdjustmentField(
                context,
                context.l10n.fajr,
                fajrAdjustmentController,
              ),
            ),
            Expanded(
              child: _buildAdjustmentField(
                context,
                context.l10n.sunrise,
                sunriseAdjustmentController,
              ),
            ),
            Expanded(
              child: _buildAdjustmentField(
                context,
                context.l10n.dhuhr,
                dhuhrAdjustmentController,
              ),
            ),
          ],
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildAdjustmentField(
                context,
                context.l10n.asr,
                asrAdjustmentController,
              ),
            ),
            Expanded(
              child: _buildAdjustmentField(
                context,
                context.l10n.maghrib,
                maghribAdjustmentController,
              ),
            ),
            Expanded(
              child: _buildAdjustmentField(
                context,
                context.l10n.isha,
                ishaAdjustmentController,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildAdvancedParametersCard(
  BuildContext context,
  FSelectController<Madhab> madhabController,
  FSelectController<HighLatitudeRule> highLatitudeRuleController,
  VoidCallback updateCustomParameters,
) {
  return FCard(
    title: Text(context.l10n.advancedSettingsTitle),
    child: Column(
      spacing: 16,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildMadhabSelector(
                context,
                madhabController,
                updateCustomParameters,
              ),
            ),
            Expanded(
              child: _buildHighLatitudeRuleSelector(
                context,
                highLatitudeRuleController,
                updateCustomParameters,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildAngleField(
  BuildContext context,
  String label,
  TextEditingController controller,
) {
  return FTextField(
    control: .managed(controller: controller),
    label: Text(label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    hint: '0.0',
  );
}

Widget _buildBasicParametersCard(
  BuildContext context,
  TextEditingController fajrAngleController,
  TextEditingController ishaAngleController,
  TextEditingController ishaIntervalController,
  TextEditingController maghribAngleController,
) {
  return FCard(
    title: Text(context.l10n.basicParametersTitle),
    child: Column(
      spacing: 16,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildAngleField(
                context,
                context.l10n.fajrAngleLabel,
                fajrAngleController,
              ),
            ),
            Expanded(
              child: _buildAngleField(
                context,
                context.l10n.ishaAngleLabel,
                ishaAngleController,
              ),
            ),
          ],
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: _buildIntervalField(
                context,
                context.l10n.ishaIntervalLabel,
                ishaIntervalController,
              ),
            ),
            Expanded(
              child: _buildAngleField(
                context,
                context.l10n.maghribAngleLabel,
                maghribAngleController,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildHighLatitudeRuleSelector(
  BuildContext context,
  FSelectController<HighLatitudeRule> highLatitudeRuleController,
  VoidCallback updateCustomParameters,
) {
  return FSelect<HighLatitudeRule>(
    control: .managed(
      controller: highLatitudeRuleController,
      onChange: (value) {
        if (value != null) {
          updateCustomParameters();
        }
      },
    ),
    items: {
      for (final rule in HighLatitudeRule.values)
        _getHighLatitudeRuleDisplayName(context, rule): rule,
    },
    label: Text(context.l10n.highLatitudeRuleLabel),
  );
}

Widget _buildIntervalField(
  BuildContext context,
  String label,
  TextEditingController controller,
) {
  return FTextField(
    control: .managed(controller: controller),
    label: Text(label),
    keyboardType: TextInputType.number,
    hint: context.l10n.optionalHint,
  );
}

Widget _buildMadhabSelector(
  BuildContext context,
  FSelectController<Madhab> madhabController,
  VoidCallback updateCustomParameters,
) {
  return FSelect<Madhab>(
    control: .managed(
      controller: madhabController,
      onChange: (value) {
        if (value != null) {
          updateCustomParameters();
        }
      },
    ),
    items: {
      for (final madhab in Madhab.values)
        _getMadhabDisplayName(context, madhab): madhab,
    },
    label: Text(context.l10n.madhabLabel),
  );
}

String _getHighLatitudeRuleDisplayName(
  BuildContext context,
  HighLatitudeRule rule,
) {
  return switch (rule) {
    HighLatitudeRule.middleOfTheNight =>
      context.l10n.highLatitudeRule_middleOfTheNight,
    HighLatitudeRule.seventhOfTheNight =>
      context.l10n.highLatitudeRule_seventhOfTheNight,
    HighLatitudeRule.twilightAngle =>
      context.l10n.highLatitudeRule_twilightAngle,
  };
}

String _getMadhabDisplayName(BuildContext context, Madhab madhab) {
  return switch (madhab) {
    Madhab.shafi => context.l10n.madhab_shafi,
    Madhab.hanafi => context.l10n.madhab_hanafi,
  };
}
