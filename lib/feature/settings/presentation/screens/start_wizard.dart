import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/feature/settings/presentation/widgets/wizard/wizard_steps.dart';

/// Screen for the initial setup wizard.
class StartedScreen extends StatelessWidget {
  /// Creates a new [StartedScreen] instance.
  const StartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showFDialog<void>(
        context: context,
        builder: (_, _, _) => const _StartWizardDialog(),
      );
    });
    return FScaffold(
      child: Column(
        children: [
          Text(l10n.welcomeToApp),
          Text(l10n.setupPreferences),
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
        for (final c in [...iqamah.values, ...adjust.values]) {
          c.dispose();
        }
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
      direction: Axis.horizontal,
      title: SettingsSemantics.sectionHeader(
        label: titles[step.value],
        child: Text(titles[step.value]),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _buildStep(
          step: step.value,
          method: method,
          fajrAngle: fajrAngle,
          ishaAngle: ishaAngle,
          ishaInterval: ishaInterval,
          maghribAngle: maghribAngle,
          is24Hours: is24Hours,
          locName: locName,
          lat: lat,
          lng: lng,
          iqamah: iqamah,
          adjust: adjust,
        ),
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

  Widget _buildStep({
    required int step,
    required ValueNotifier<CalculationMethod?> method,
    required TextEditingController fajrAngle,
    required TextEditingController ishaAngle,
    required TextEditingController ishaInterval,
    required TextEditingController maghribAngle,
    required ValueNotifier<bool> is24Hours,
    required TextEditingController locName,
    required TextEditingController lat,
    required TextEditingController lng,
    required Map<Prayer, TextEditingController> iqamah,
    required Map<Prayer, TextEditingController> adjust,
  }) {
    return switch (step) {
      0 => const WelcomeStep(),
      1 => MethodStep(
        method: method,
        fajr: fajrAngle,
        isha: ishaAngle,
        ishaInt: ishaInterval,
        maghrib: maghribAngle,
      ),
      2 => TimeFormatStep(is24Hours: is24Hours),
      3 => LocationStep(name: locName, lat: lat, lng: lng),
      4 => IqamahStep(
        iqamah: iqamah,
        adjust: adjust,
        iqamahPrayers: _iqamahPrayers,
        adjustmentPrayers: _adjustmentPrayers,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
