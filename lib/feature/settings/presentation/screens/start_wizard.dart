import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';

class StartedScreen extends StatelessWidget {
  const StartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFDialog(
        context: context,
        builder: (context, style, animation) => const _StartWizardDialog(),
      );
    });
    return FScaffold(
      child: Column(
        children: [
          Text(context.l10n.welcomeToApp),
          Text(context.l10n.setupPreferences),
        ],
      ),
    );
  }
}

class _StartWizardDialog extends StatefulWidget {
  const _StartWizardDialog();

  @override
  State<_StartWizardDialog> createState() => _StartWizardDialogState();
}

class _StartWizardDialogState extends State<_StartWizardDialog> {
  // Navigation
  int _step = 0;

  // Collected values (UI only; no persistence here)
  CalculationMethod? _method;
  bool _is24Hours = false;

  // Custom parameters (visible only when method == other)
  final TextEditingController _fajrAngleCtrl = TextEditingController(
    text: '18.0',
  );
  final TextEditingController _ishaAngleCtrl = TextEditingController(
    text: '18.0',
  );
  final TextEditingController _ishaIntervalCtrl = TextEditingController();
  final TextEditingController _maghribAngleCtrl = TextEditingController();

  // Location
  final TextEditingController _locationNameCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  // Iqamah and adhan adjustments (minutes)
  final List<Prayer> _iqamahPrayers = const [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  final List<Prayer> _adjustmentPrayers = const [
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  late final Map<Prayer, TextEditingController> _iqamahCtrls = {
    for (final p in _iqamahPrayers) p: TextEditingController(),
  };

  late final Map<Prayer, TextEditingController> _adjustmentCtrls = {
    for (final p in _adjustmentPrayers) p: TextEditingController(text: '0'),
  };

  @override
  Widget build(BuildContext context) {
    return FDialog(
      direction: Axis.horizontal,
      title: Text(_stepTitle(_step)),
      body: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _buildBody(),
      ),
      actions: [
        if (_step > 0) FButton(onPress: _back, child: Text(context.l10n.back)),
        const Spacer(),
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(context.l10n.skip),
        ),
        FButton(
          onPress: _next,
          child: Text(_step < 4 ? context.l10n.next : context.l10n.done),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fajrAngleCtrl.dispose();
    _ishaAngleCtrl.dispose();
    _ishaIntervalCtrl.dispose();
    _maghribAngleCtrl.dispose();
    _locationNameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    for (final c in _iqamahCtrls.values) {
      c.dispose();
    }
    for (final c in _adjustmentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildWelcome();
      case 1:
        return _buildMethod();
      case 2:
        return _buildTimeFormat();
      case 3:
        return _buildLocation();
      case 4:
        return _buildIqamahAndAdjustments();
      default:
        return _buildWelcome();
    }
  }

  Widget _buildIqamahAndAdjustments() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.iqamahAfterAdhan),
          const SizedBox(height: 8),
          Wrap(
            runSpacing: 8,
            spacing: 12,
            children: _iqamahPrayers
                .map(
                  (p) => SizedBox(
                    width: 140,
                    child: FTextFormField(
                      controller: _iqamahCtrls[p],
                      keyboardType: TextInputType.number,
                      // decoration: InputDecoration(labelText: p.name),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.adhanAdjustments),
          const SizedBox(height: 8),
          Wrap(
            runSpacing: 8,
            spacing: 12,
            children: _adjustmentPrayers
                .map(
                  (p) => SizedBox(
                    width: 140,
                    child: FTextFormField(
                      controller: _adjustmentCtrls[p],
                      keyboardType: TextInputType.number,
                      // decoration: InputDecoration(labelText: p.name),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FTextFormField(
          controller: _locationNameCtrl,
          // decoration: const InputDecoration(
          //   labelText: 'City or place name',
          //   hintText: 'e.g., Riyadh',
          // ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FTextFormField(
                controller: _latCtrl,
                // decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FTextFormField(
                controller: _lngCtrl,
                // decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FButton(
              onPress: () {
                // Placeholder: you can hook device location here later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.deviceLocationNotImplemented),
                  ),
                );
              },
              child: Text(context.l10n.useDeviceLocation),
            ),
            const SizedBox(width: 8),
            FButton(
              onPress: () {
                // Placeholder: you can hook timezone detection here later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.detectTimezoneNotImplemented),
                  ),
                );
              },
              child: Text(context.l10n.detectTimezone),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.chooseCalculationMethod),
        const SizedBox(height: 8),
        FSelect<CalculationMethod>(
          items: {
            for (final method in CalculationMethod.values)
              method.getLocaleName(context.l10n): method,
          },
        ),
        if (_method == CalculationMethod.other) ...[
          const SizedBox(height: 16),
          Text(context.l10n.customParametersLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FTextFormField(
                  controller: _fajrAngleCtrl,
                  // decoration:
                  //     const InputDecoration(labelText: 'Fajr angle (°)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FTextFormField(
                  controller: _ishaAngleCtrl,
                  // decoration:
                  //     const InputDecoration(labelText: 'Isha angle (°)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FTextFormField(
                  controller: _ishaIntervalCtrl,
                  // decoration:
                  //     const InputDecoration(labelText: 'Isha interval (min)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FTextFormField(
                  controller: _maghribAngleCtrl,
                  // decoration:
                  //     const InputDecoration(labelText: 'Maghrib angle (°)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.placeholdersHint,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeFormat() {
    return Material(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.l10n.use24HourFormat),
        value: _is24Hours,
        onChanged: (v) => setState(() => _is24Hours = v),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.setupPrayerSettingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(context.l10n.setupPrayerSettingsSubtitle),
        SizedBox(
          width: 200,
          height: 80,
          child: FTextField.password(
          ),
        ),
      ],
    );
  }

  void _next() {
    if (_step == 1 && _method == null) {
      showFToast(
        context: context,
        title: Text(context.l10n.pleaseSelectMethod),
      );
      return;
    }
    if (_step < 4) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pop();
    }
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return context.l10n.wizardStep_welcome;
      case 1:
        return context.l10n.wizardStep_calculationMethod;
      case 2:
        return context.l10n.wizardStep_timeFormat;
      case 3:
        return context.l10n.wizardStep_location;
      case 4:
        return context.l10n.wizardStep_iqamahAdjustments;
      default:
        return context.l10n.wizardStep_getStarted;
    }
  }
}
