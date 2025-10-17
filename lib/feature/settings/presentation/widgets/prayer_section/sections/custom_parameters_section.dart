import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class PrayerSettingsCustomParametersCard extends ConsumerStatefulWidget {
  const PrayerSettingsCustomParametersCard({required this.maxWidth, super.key});
  final double maxWidth;

  @override
  ConsumerState<PrayerSettingsCustomParametersCard> createState() =>
      _PrayerSettingsCustomParametersCardState();
}

class _PrayerSettingsCustomParametersCardState
    extends ConsumerState<PrayerSettingsCustomParametersCard>
    with TickerProviderStateMixin {
  late FAccordionController _accordionController;

  late TextEditingController _fajrAngleController;
  late TextEditingController _ishaAngleController;
  late TextEditingController _ishaIntervalController;
  late TextEditingController _maghribAngleController;

  late FSelectController<Madhab> _madhabController;
  late FSelectController<HighLatitudeRule> _highLatitudeRuleController;

  // Adjustment controllers for each prayer
  late TextEditingController _fajrAdjustmentController;
  late TextEditingController _sunriseAdjustmentController;
  late TextEditingController _dhuhrAdjustmentController;
  late TextEditingController _asrAdjustmentController;
  late TextEditingController _maghribAdjustmentController;
  late TextEditingController _ishaAdjustmentController;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      prayerSettingsProvider,
      (previous, next) {
        _updateControllers(next.value?.customParameters);
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FAccordion(
        controller: _accordionController,
        style: (style) => style.copyWith(
          dividerStyle: FDividerStyle(
            color: Colors.transparent,
            padding: const EdgeInsetsGeometry.all(0),
          ).call,
        ),
        children: [
          FAccordionItem(
            title: Text(context.l10n.customParametersTitle),
            child: _buildCustomParametersContent(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fajrAngleController.dispose();
    _ishaAngleController.dispose();
    _ishaIntervalController.dispose();
    _maghribAngleController.dispose();
    _madhabController.dispose();
    _highLatitudeRuleController.dispose();
    _fajrAdjustmentController.dispose();
    _sunriseAdjustmentController.dispose();
    _dhuhrAdjustmentController.dispose();
    _asrAdjustmentController.dispose();
    _maghribAdjustmentController.dispose();
    _ishaAdjustmentController.dispose();
    _accordionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prayerSettings = ref.read(prayerSettingsProvider);
    final customParams = prayerSettings.value?.customParameters;
    final defaultParams = CalculationMethod.other.parameters;

    _accordionController = FAccordionController();

    _fajrAngleController = TextEditingController(
      text:
          customParams?.fajrAngle.toString() ??
          defaultParams.fajrAngle.toString(),
    );
    _ishaAngleController = TextEditingController(
      text:
          customParams?.ishaAngle.toString() ??
          defaultParams.ishaAngle.toString(),
    );
    _ishaIntervalController = TextEditingController(
      text:
          customParams?.ishaInterval?.toString() ??
          defaultParams.ishaInterval?.toString() ??
          '',
    );
    _maghribAngleController = TextEditingController(
      text:
          customParams?.maghribAngle?.toString() ??
          defaultParams.maghribAngle?.toString() ??
          '',
    );

    _madhabController = FSelectController(
      vsync: this,
      value: customParams?.madhab ?? defaultParams.madhab,
    );
    _highLatitudeRuleController = FSelectController(
      vsync: this,
      value: customParams?.highLatitudeRule ?? defaultParams.highLatitudeRule,
    );

    // Initialize adjustment controllers
    _fajrAdjustmentController = TextEditingController(
      text:
          (customParams?.adjustments[Prayer.fajr] ??
                  defaultParams.adjustments[Prayer.fajr] ??
                  0)
              .toString(),
    );
    _sunriseAdjustmentController = TextEditingController(
      text:
          (customParams?.adjustments[Prayer.sunrise] ??
                  defaultParams.adjustments[Prayer.sunrise] ??
                  0)
              .toString(),
    );
    _dhuhrAdjustmentController = TextEditingController(
      text:
          (customParams?.adjustments[Prayer.dhuhr] ??
                  defaultParams.adjustments[Prayer.dhuhr] ??
                  0)
              .toString(),
    );
    _asrAdjustmentController = TextEditingController(
      text:
          (customParams?.adjustments[Prayer.asr] ??
                  defaultParams.adjustments[Prayer.asr] ??
                  0)
              .toString(),
    );
    _maghribAdjustmentController = TextEditingController(
      text:
          (customParams?.adjustments[Prayer.maghrib] ??
                  defaultParams.adjustments[Prayer.maghrib] ??
                  0)
              .toString(),
    );
    _ishaAdjustmentController = TextEditingController(
      text:
          (customParams?.adjustments[Prayer.isha] ??
                  defaultParams.adjustments[Prayer.isha] ??
                  0)
              .toString(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: FButton(
                style: FButtonStyle.secondary(),
                onPress: _resetToDefaults,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FIcons.rotateCcw, size: 16),
                    const SizedBox(width: 8),
                    Text(context.l10n.resetToDefaults),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FButton(
                onPress: _saveCustomParameters,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FIcons.save, size: 16),
                    const SizedBox(width: 8),
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

  Widget _buildAdjustmentField(String label, TextEditingController controller) {
    return FTextField(
      label: Text(label),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      hint: '0',
    );
  }

  Widget _buildAdjustmentsCard() {
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
                  context.l10n.fajr,
                  _fajrAdjustmentController,
                ),
              ),
              Expanded(
                child: _buildAdjustmentField(
                  context.l10n.sunrise,
                  _sunriseAdjustmentController,
                ),
              ),
              Expanded(
                child: _buildAdjustmentField(
                  context.l10n.dhuhr,
                  _dhuhrAdjustmentController,
                ),
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: _buildAdjustmentField(
                  context.l10n.asr,
                  _asrAdjustmentController,
                ),
              ),
              Expanded(
                child: _buildAdjustmentField(
                  context.l10n.maghrib,
                  _maghribAdjustmentController,
                ),
              ),
              Expanded(
                child: _buildAdjustmentField(
                  context.l10n.isha,
                  _ishaAdjustmentController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedParametersCard() {
    return FCard(
      title: Text(context.l10n.advancedSettingsTitle),
      child: Column(
        spacing: 16,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(child: _buildMadhabSelector()),
              Expanded(child: _buildHighLatitudeRuleSelector()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAngleField(String label, TextEditingController controller) {
    return FTextField(
      label: Text(label),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      hint: '0.0',
    );
  }

  Widget _buildBasicParametersCard() {
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
                  context.l10n.fajrAngleLabel,
                  _fajrAngleController,
                ),
              ),
              Expanded(
                child: _buildAngleField(
                  context.l10n.ishaAngleLabel,
                  _ishaAngleController,
                ),
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: _buildIntervalField(
                  context.l10n.ishaIntervalLabel,
                  _ishaIntervalController,
                ),
              ),
              Expanded(
                child: _buildAngleField(
                  context.l10n.maghribAngleLabel,
                  _maghribAngleController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomParametersContent() {
    return Column(
      spacing: 16,
      children: [
        const SizedBox(height: 8),
        _buildBasicParametersCard(),
        _buildAdvancedParametersCard(),
        _buildAdjustmentsCard(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHighLatitudeRuleSelector() {
    return FSelect<HighLatitudeRule>(
      items: {
        for (final rule in HighLatitudeRule.values)
          _getHighLatitudeRuleDisplayName(rule): rule,
      },
      controller: _highLatitudeRuleController,
      label: Text(context.l10n.highLatitudeRuleLabel),
      onChange: (value) {
        if (value != null) {
          _updateCustomParameters();
        }
      },
    );
  }

  Widget _buildIntervalField(String label, TextEditingController controller) {
    return FTextField(
      label: Text(label),
      controller: controller,
      keyboardType: TextInputType.number,
      hint: context.l10n.optionalHint,
    );
  }

  Widget _buildMadhabSelector() {
    return FSelect<Madhab>(
      items: {
        for (final madhab in Madhab.values)
          _getMadhabDisplayName(madhab): madhab,
      },
      controller: _madhabController,
      label: Text(context.l10n.madhabLabel),
      onChange: (value) {
        if (value != null) {
          _updateCustomParameters();
        }
      },
    );
  }

  String _getHighLatitudeRuleDisplayName(HighLatitudeRule rule) {
    return switch (rule) {
      HighLatitudeRule.middleOfTheNight =>
        context.l10n.highLatitudeRule_middleOfTheNight,
      HighLatitudeRule.seventhOfTheNight =>
        context.l10n.highLatitudeRule_seventhOfTheNight,
      HighLatitudeRule.twilightAngle =>
        context.l10n.highLatitudeRule_twilightAngle,
    };
  }

  String _getMadhabDisplayName(Madhab madhab) {
    return switch (madhab) {
      Madhab.shafi => context.l10n.madhab_shafi,
      Madhab.hanafi => context.l10n.madhab_hanafi,
    };
  }

  void _resetToDefaults() {
    _updateControllers(
      ref.read(prayerSettingsProvider).value?.method.parameters,
    );

    _updateCustomParameters();

    showFToast(
      context: context,
      title: Text(context.l10n.resetCompleteTitle),
      description: Text(context.l10n.resetCompleteDescription),
    );
  }

  void _saveCustomParameters() {
    _updateCustomParameters();
    showFToast(
      context: context,
      title: Text(context.l10n.parametersSavedTitle),
      description: Text(context.l10n.parametersSavedDescription),
    );
  }

  void _updateControllers(CalculationParameters? customParams) {
    final defaultParams = CalculationMethod.other.parameters;

    _fajrAngleController.text =
        customParams?.fajrAngle.toString() ??
        defaultParams.fajrAngle.toString();

    _ishaAngleController.text =
        customParams?.ishaAngle.toString() ??
        defaultParams.ishaAngle.toString();

    _ishaIntervalController.text =
        customParams?.ishaInterval?.toString() ??
        defaultParams.ishaInterval?.toString() ??
        '';

    _maghribAngleController.text =
        customParams?.maghribAngle?.toString() ??
        defaultParams.maghribAngle?.toString() ??
        '';

    _madhabController.value = customParams?.madhab ?? defaultParams.madhab;

    _highLatitudeRuleController.value =
        customParams?.highLatitudeRule ?? defaultParams.highLatitudeRule;

    // Update adjustment controllers
    _fajrAdjustmentController.text =
        (customParams?.adjustments[Prayer.fajr] ??
                defaultParams.adjustments[Prayer.fajr] ??
                0)
            .toString();

    _sunriseAdjustmentController.text =
        (customParams?.adjustments[Prayer.sunrise] ??
                defaultParams.adjustments[Prayer.sunrise] ??
                0)
            .toString();

    _dhuhrAdjustmentController.text =
        (customParams?.adjustments[Prayer.dhuhr] ??
                defaultParams.adjustments[Prayer.dhuhr] ??
                0)
            .toString();

    _asrAdjustmentController.text =
        (customParams?.adjustments[Prayer.asr] ??
                defaultParams.adjustments[Prayer.asr] ??
                0)
            .toString();

    _maghribAdjustmentController.text =
        (customParams?.adjustments[Prayer.maghrib] ??
                defaultParams.adjustments[Prayer.maghrib] ??
                0)
            .toString();

    _ishaAdjustmentController.text =
        (customParams?.adjustments[Prayer.isha] ??
                defaultParams.adjustments[Prayer.isha] ??
                0)
            .toString();
  }

  void _updateCustomParameters() {
    try {
      final params = ref.read(prayerSettingsProvider).value?.customParameters;
      final fajrAngle = double.tryParse(_fajrAngleController.text) ?? 18.0;
      final ishaAngle = double.tryParse(_ishaAngleController.text) ?? 18.0;
      final ishaInterval = _ishaIntervalController.text.isEmpty
          ? null
          : int.tryParse(_ishaIntervalController.text);
      final maghribAngle = _maghribAngleController.text.isEmpty
          ? null
          : double.tryParse(_maghribAngleController.text);

      final adjustments = {
        Prayer.fajr: int.tryParse(_fajrAdjustmentController.text) ?? 0,
        Prayer.sunrise: int.tryParse(_sunriseAdjustmentController.text) ?? 0,
        Prayer.dhuhr: int.tryParse(_dhuhrAdjustmentController.text) ?? 0,
        Prayer.asr: int.tryParse(_asrAdjustmentController.text) ?? 0,
        Prayer.maghrib: int.tryParse(_maghribAdjustmentController.text) ?? 0,
        Prayer.isha: int.tryParse(_ishaAdjustmentController.text) ?? 0,
      };

      final customParameters = CalculationParameters(
        method: params?.method ?? CalculationMethod.other,
        fajrAngle: fajrAngle,
        ishaAngle: ishaAngle,
        ishaInterval: ishaInterval,
        maghribAngle: maghribAngle,
        madhab: _madhabController.value ?? Madhab.shafi,
        highLatitudeRule:
            _highLatitudeRuleController.value ??
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
            (settings) => settings.copyWith(customParameters: customParameters),
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
}
