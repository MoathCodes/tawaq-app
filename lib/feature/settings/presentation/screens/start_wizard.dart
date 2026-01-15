import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';

/// Screen for the initial setup wizard.
class StartedScreen extends StatelessWidget {
  /// Creates a new [StartedScreen] instance.
  const StartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showFDialog<void>(
        context: context,
        builder: (_, _, _) => const _StartWizardDialog(),
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

class _StartWizardDialog extends HookWidget {
  const _StartWizardDialog();

  static const List<Prayer> _iqamahPrayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];
  static const List<Prayer> _adjustmentPrayers = [
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  @override
  Widget build(BuildContext context) {
    final step = useState(0);
    final method = useState<CalculationMethod?>(null);
    final is24Hours = useState(false);
    final l10n = context.l10n;

    // Controllers
    final fajrAngle = useTextEditingController(text: '18.0');
    final ishaAngle = useTextEditingController(text: '18.0');
    final ishaInterval = useTextEditingController();
    final maghribAngle = useTextEditingController();
    final locName = useTextEditingController();
    final lat = useTextEditingController();
    final lng = useTextEditingController();
    final iqamah = useMemoized(
      () => {for (final p in _iqamahPrayers) p: TextEditingController()},
    );
    final adjust = useMemoized(
      () => {
        for (final p in _adjustmentPrayers) p: TextEditingController(text: '0'),
      },
    );

    useEffect(
      () => () {
        for (final c in [...iqamah.values, ...adjust.values]) c.dispose();
      },
      const [],
    );

    void next() {
      if (step.value == 1 && method.value == null) {
        showFToast(context: context, title: Text(l10n.pleaseSelectMethod));
        return;
      }
      step.value < 4 ? step.value++ : Navigator.of(context).pop();
    }

    final titles = [
      l10n.wizardStep_welcome,
      l10n.wizardStep_calculationMethod,
      l10n.wizardStep_timeFormat,
      l10n.wizardStep_location,
      l10n.wizardStep_iqamahAdjustments,
    ];

    return FDialog(
      direction: .horizontal,
      title: Text(titles[step.value]),
      body: Padding(
        padding: const .only(top: 4),
        child: [
          _WelcomeStep(l10n: l10n),
          _MethodStep(
            l10n: l10n,
            method: method,
            fajr: fajrAngle,
            isha: ishaAngle,
            ishaInt: ishaInterval,
            maghrib: maghribAngle,
          ),
          _TimeFormatStep(l10n: l10n, is24Hours: is24Hours),
          _LocationStep(l10n: l10n, name: locName, lat: lat, lng: lng),
          _IqamahStep(l10n: l10n, iqamah: iqamah, adjust: adjust),
        ][step.value],
      ),
      actions: [
        if (step.value > 0)
          FButton(onPress: () => step.value--, child: Text(l10n.back)),
        const Spacer(),
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(l10n.skip),
        ),
        FButton(
          onPress: next,
          child: Text(step.value < 4 ? l10n.next : l10n.done),
        ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        l10n.setupPrayerSettingsTitle,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.setupPrayerSettingsSubtitle),
    ],
  );
}

class _MethodStep extends StatelessWidget {
  const _MethodStep({
    required this.l10n,
    required this.method,
    required this.fajr,
    required this.isha,
    required this.ishaInt,
    required this.maghrib,
  });
  final AppLocalizations l10n;
  final ValueNotifier<CalculationMethod?> method;
  final TextEditingController fajr;
  final TextEditingController isha;
  final TextEditingController ishaInt;
  final TextEditingController maghrib;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(l10n.chooseCalculationMethod),
      const SizedBox(height: AppSpacing.sm),
      FSelect<CalculationMethod>(
        items: {
          for (final m in CalculationMethod.values) m.getLocaleName(l10n): m,
        },
      ),
      if (method.value == CalculationMethod.other) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.customParametersLabel),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _NumField(ctrl: fajr)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _NumField(ctrl: isha)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _NumField(ctrl: ishaInt, dec: false)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _NumField(ctrl: maghrib)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.placeholdersHint,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ],
  );
}

class _TimeFormatStep extends StatelessWidget {
  const _TimeFormatStep({required this.l10n, required this.is24Hours});
  final AppLocalizations l10n;
  final ValueNotifier<bool> is24Hours;

  @override
  Widget build(BuildContext context) => Material(
    child: SwitchListTile(
      contentPadding: .zero,
      title: Text(l10n.use24HourFormat),
      value: is24Hours.value,
      onChanged: (v) => is24Hours.value = v,
    ),
  );
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.l10n,
    required this.name,
    required this.lat,
    required this.lng,
  });
  final AppLocalizations l10n;
  final TextEditingController name;
  final TextEditingController lat;
  final TextEditingController lng;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    mainAxisSize: MainAxisSize.min,
    children: [
      FTextFormField(control: .managed(controller: name)),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(child: _NumField(ctrl: lat, signed: true)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _NumField(ctrl: lng, signed: true)),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          FButton(
            onPress: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.deviceLocationNotImplemented)),
            ),
            child: Text(l10n.useDeviceLocation),
          ),
          const SizedBox(width: AppSpacing.sm),
          FButton(
            onPress: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.detectTimezoneNotImplemented)),
            ),
            child: Text(l10n.detectTimezone),
          ),
        ],
      ),
    ],
  );
}

class _IqamahStep extends StatelessWidget {
  const _IqamahStep({
    required this.l10n,
    required this.iqamah,
    required this.adjust,
  });
  final AppLocalizations l10n;
  final Map<Prayer, TextEditingController> iqamah;
  final Map<Prayer, TextEditingController> adjust;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Text(l10n.iqamahAfterAdhan),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: _StartWizardDialog._iqamahPrayers
              .map(
                (p) => SizedBox(
                  width: 140,
                  child: FTextFormField(
                    control: .managed(controller: iqamah[p]),
                    keyboardType: TextInputType.number,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.adhanAdjustments),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: _StartWizardDialog._adjustmentPrayers
              .map(
                (p) => SizedBox(
                  width: 140,
                  child: FTextFormField(
                    control: .managed(controller: adjust[p]),
                    keyboardType: TextInputType.number,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _NumField extends StatelessWidget {
  const _NumField({required this.ctrl, this.dec = true, this.signed = false});
  final TextEditingController ctrl;
  final bool dec;
  final bool signed;

  @override
  Widget build(BuildContext context) => FTextFormField(
    control: .managed(controller: ctrl),
    keyboardType: TextInputType.numberWithOptions(decimal: dec, signed: signed),
  );
}
