import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class PrayerSettingsCustomParametersCard extends ConsumerStatefulWidget {
  final double maxWidth;
  const PrayerSettingsCustomParametersCard({required this.maxWidth, super.key});

  @override
  ConsumerState<PrayerSettingsCustomParametersCard> createState() =>
      _PrayerSettingsCustomParametersCardState();
}

class _PrayerSettingsCustomParametersCardState
    extends ConsumerState<PrayerSettingsCustomParametersCard>
    with TickerProviderStateMixin {
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

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      prayerSettingsNotifierProvider,
      (previous, next) {
        if (previous != next && next.value?.method == CalculationMethod.other) {
          final customParams = next.value?.customParameters;
          if (customParams != null) {
            _updateControllers(customParams);
          }
        }
      },
      onError: (error, stackTrace) {
        ref.read(talkerNotifierProvider).handle(error, stackTrace);
        showFToast(
            context: context,
            title: Text(
                context.l10n.errorOccurredWhile("Loading Custom Parameters")),
            description: Text(error.toString()));
      },
    );

    final prayerSettings = ref.watch(prayerSettingsNotifierProvider);
    final isCustomMethod =
        prayerSettings.value?.method == CalculationMethod.other;

    if (!isCustomMethod) {
      return const SizedBox.shrink();
    }

    final theme = context.theme;

    return FCard(
      title: Row(
        children: [
          const Text("Custom Parameters"),
          const Spacer(),
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => setState(() => _isExpanded = !_isExpanded),
            child: Icon(
              _isExpanded ? FIcons.chevronUp : FIcons.chevronDown,
              size: 16,
            ),
          ),
        ],
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        sizeCurve: Curves.easeInOutCubic,
        crossFadeState:
            _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Tap to configure custom calculation parameters",
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
        secondChild: _buildCustomParametersContent(),
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prayerSettings = ref.read(prayerSettingsNotifierProvider);
    final customParams = prayerSettings.value?.customParameters;

    _fajrAngleController = TextEditingController(
        text: customParams?.fajrAngle.toString() ?? '18.0');
    _ishaAngleController = TextEditingController(
        text: customParams?.ishaAngle.toString() ?? '18.0');
    _ishaIntervalController = TextEditingController(
        text: customParams?.ishaInterval?.toString() ?? '');
    _maghribAngleController = TextEditingController(
        text: customParams?.maghribAngle?.toString() ?? '');

    _madhabController = FSelectController(
        vsync: this, value: customParams?.madhab ?? Madhab.shafi);
    _highLatitudeRuleController = FSelectController(
        vsync: this,
        value: customParams?.highLatitudeRule ??
            HighLatitudeRule.middleOfTheNight);

    // Initialize adjustment controllers
    _fajrAdjustmentController = TextEditingController(
        text: (customParams?.adjustments[Prayer.fajr] ?? 0).toString());
    _sunriseAdjustmentController = TextEditingController(
        text: (customParams?.adjustments[Prayer.sunrise] ?? 0).toString());
    _dhuhrAdjustmentController = TextEditingController(
        text: (customParams?.adjustments[Prayer.dhuhr] ?? 0).toString());
    _asrAdjustmentController = TextEditingController(
        text: (customParams?.adjustments[Prayer.asr] ?? 0).toString());
    _maghribAdjustmentController = TextEditingController(
        text: (customParams?.adjustments[Prayer.maghrib] ?? 0).toString());
    _ishaAdjustmentController = TextEditingController(
        text: (customParams?.adjustments[Prayer.isha] ?? 0).toString());
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FIcons.rotateCcw, size: 16),
                    SizedBox(width: 8),
                    Text("Reset to Defaults"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FButton(
                onPress: _saveCustomParameters,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FIcons.save, size: 16),
                    SizedBox(width: 8),
                    Text("Save Parameters"),
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
      hint: "0",
    );
  }

  Widget _buildAdjustmentsCard() {
    return FCard(
      title: const Text("Prayer Time Adjustments (minutes)"),
      child: Column(
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(
                  child:
                      _buildAdjustmentField("Fajr", _fajrAdjustmentController)),
              Expanded(
                  child: _buildAdjustmentField(
                      "Sunrise", _sunriseAdjustmentController)),
              Expanded(
                  child: _buildAdjustmentField(
                      "Dhuhr", _dhuhrAdjustmentController)),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                  child:
                      _buildAdjustmentField("Asr", _asrAdjustmentController)),
              Expanded(
                  child: _buildAdjustmentField(
                      "Maghrib", _maghribAdjustmentController)),
              Expanded(
                  child:
                      _buildAdjustmentField("Isha", _ishaAdjustmentController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedParametersCard() {
    return FCard(
      title: const Text("Advanced Settings"),
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
      hint: "0.0",
    );
  }

  Widget _buildBasicParametersCard() {
    return FCard(
      title: const Text("Basic Parameters"),
      child: Column(
        spacing: 16,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(
                  child:
                      _buildAngleField("Fajr Angle (°)", _fajrAngleController)),
              Expanded(
                  child:
                      _buildAngleField("Isha Angle (°)", _ishaAngleController)),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                  child: _buildIntervalField(
                      "Isha Interval (min)", _ishaIntervalController)),
              Expanded(
                  child: _buildAngleField(
                      "Maghrib Angle (°)", _maghribAngleController)),
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
      controller: _highLatitudeRuleController,
      label: const Text("High Latitude Rule"),
      format: (rule) => _getHighLatitudeRuleDisplayName(rule),
      children: HighLatitudeRule.values
          .map((rule) => FSelectItem(
                _getHighLatitudeRuleDisplayName(rule),
                rule,
              ))
          .toList(),
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
      hint: "Optional",
    );
  }

  Widget _buildMadhabSelector() {
    return FSelect<Madhab>(
      controller: _madhabController,
      label: const Text("Madhab"),
      format: (madhab) => _getMadhabDisplayName(madhab),
      children: Madhab.values
          .map((madhab) => FSelectItem(
                _getMadhabDisplayName(madhab),
                madhab,
              ))
          .toList(),
      onChange: (value) {
        if (value != null) {
          _updateCustomParameters();
        }
      },
    );
  }

  String _getHighLatitudeRuleDisplayName(HighLatitudeRule rule) {
    return switch (rule) {
      HighLatitudeRule.middleOfTheNight => "Middle of the Night",
      HighLatitudeRule.seventhOfTheNight => "Seventh of the Night",
      HighLatitudeRule.twilightAngle => "Twilight Angle",
    };
  }

  String _getMadhabDisplayName(Madhab madhab) {
    return switch (madhab) {
      Madhab.shafi => "Shafi",
      Madhab.hanafi => "Hanafi",
    };
  }

  void _resetToDefaults() {
    _fajrAngleController.text = '18.0';
    _ishaAngleController.text = '18.0';
    _ishaIntervalController.text = '';
    _maghribAngleController.text = '';
    _madhabController.value = Madhab.shafi;
    _highLatitudeRuleController.value = HighLatitudeRule.middleOfTheNight;

    _fajrAdjustmentController.text = '0';
    _sunriseAdjustmentController.text = '0';
    _dhuhrAdjustmentController.text = '0';
    _asrAdjustmentController.text = '0';
    _maghribAdjustmentController.text = '0';
    _ishaAdjustmentController.text = '0';

    _updateCustomParameters();

    showFToast(
      context: context,
      title: const Text("Reset Complete"),
      description: const Text("Parameters have been reset to default values."),
    );
  }

  void _saveCustomParameters() {
    _updateCustomParameters();
    showFToast(
      context: context,
      title: const Text("Parameters Saved"),
      description:
          const Text("Your custom parameters have been saved successfully."),
    );
  }

  void _updateControllers(CalculationParameters customParams) {
    _fajrAngleController.text = customParams.fajrAngle.toString();
    _ishaAngleController.text = customParams.ishaAngle.toString();
    _ishaIntervalController.text = customParams.ishaInterval?.toString() ?? '';
    _maghribAngleController.text = customParams.maghribAngle?.toString() ?? '';
    _madhabController.value = customParams.madhab;
    _highLatitudeRuleController.value = customParams.highLatitudeRule;

    _fajrAdjustmentController.text =
        (customParams.adjustments[Prayer.fajr] ?? 0).toString();
    _sunriseAdjustmentController.text =
        (customParams.adjustments[Prayer.sunrise] ?? 0).toString();
    _dhuhrAdjustmentController.text =
        (customParams.adjustments[Prayer.dhuhr] ?? 0).toString();
    _asrAdjustmentController.text =
        (customParams.adjustments[Prayer.asr] ?? 0).toString();
    _maghribAdjustmentController.text =
        (customParams.adjustments[Prayer.maghrib] ?? 0).toString();
    _ishaAdjustmentController.text =
        (customParams.adjustments[Prayer.isha] ?? 0).toString();
  }

  void _updateCustomParameters() {
    try {
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
        method: CalculationMethod.other,
        fajrAngle: fajrAngle,
        ishaAngle: ishaAngle,
        ishaInterval: ishaInterval,
        maghribAngle: maghribAngle,
        madhab: _madhabController.value ?? Madhab.shafi,
        highLatitudeRule: _highLatitudeRuleController.value ??
            HighLatitudeRule.middleOfTheNight,
        adjustments: adjustments,
        methodAdjustments: const {
          Prayer.fajr: 0,
          Prayer.sunrise: 0,
          Prayer.dhuhr: 0,
          Prayer.asr: 0,
          Prayer.maghrib: 0,
          Prayer.isha: 0,
        },
      );

      ref.read(prayerSettingsNotifierProvider.notifier).update(
            (settings) => settings.copyWith(customParameters: customParameters),
          );
    } catch (e) {
      showFToast(
        context: context,
        title: const Text("Invalid Parameters"),
        description: Text("Please check your input values: ${e.toString()}"),
      );
    }
  }
}
