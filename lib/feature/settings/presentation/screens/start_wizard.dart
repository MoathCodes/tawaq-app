import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
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
    // State
    final step = useState(0);
    final method = useState<CalculationMethod?>(null);
    final is24Hours = useState(false);

    // Custom parameters controllers
    final fajrAngleCtrl = useTextEditingController(text: '18.0');
    final ishaAngleCtrl = useTextEditingController(text: '18.0');
    final ishaIntervalCtrl = useTextEditingController();
    final maghribAngleCtrl = useTextEditingController();

    // Location controllers
    final locationNameCtrl = useTextEditingController();
    final latCtrl = useTextEditingController();
    final lngCtrl = useTextEditingController();

    // Iqamah controllers map
    final iqamahCtrls = useMemoized(
      () => {
        for (final p in _iqamahPrayers) p: TextEditingController(),
      },
    );

    // Adjustment controllers map
    final adjustmentCtrls = useMemoized(
      () => {
        for (final p in _adjustmentPrayers) p: TextEditingController(text: '0'),
      },
    );

    // Dispose map controllers
    useEffect(
      () {
        return () {
          for (final c in iqamahCtrls.values) {
            c.dispose();
          }
          for (final c in adjustmentCtrls.values) {
            c.dispose();
          }
        };
      },
      const [],
    );

    void back() {
      if (step.value > 0) step.value--;
    }

    void next() {
      if (step.value == 1 && method.value == null) {
        showFToast(
          context: context,
          title: Text(context.l10n.pleaseSelectMethod),
        );
        return;
      }
      if (step.value < 4) {
        step.value++;
      } else {
        Navigator.of(context).pop();
      }
    }

    String stepTitle(int s) {
      switch (s) {
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

    return FDialog(
      direction: .horizontal,
      title: Text(stepTitle(step.value)),
      body: Padding(
        padding: const .only(top: 4),
        child: _buildBody(
          context,
          step.value,
          method,
          is24Hours,
          fajrAngleCtrl,
          ishaAngleCtrl,
          ishaIntervalCtrl,
          maghribAngleCtrl,
          locationNameCtrl,
          latCtrl,
          lngCtrl,
          iqamahCtrls,
          adjustmentCtrls,
        ),
      ),
      actions: [
        if (step.value > 0)
          FButton(onPress: back, child: Text(context.l10n.back)),
        const Spacer(),
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(context.l10n.skip),
        ),
        FButton(
          onPress: next,
          child: Text(step.value < 4 ? context.l10n.next : context.l10n.done),
        ),
      ],
    );
  }
}

Widget _buildBody(
  BuildContext context,
  int step,
  ValueNotifier<CalculationMethod?> method,
  ValueNotifier<bool> is24Hours,
  TextEditingController fajrAngleCtrl,
  TextEditingController ishaAngleCtrl,
  TextEditingController ishaIntervalCtrl,
  TextEditingController maghribAngleCtrl,
  TextEditingController locationNameCtrl,
  TextEditingController latCtrl,
  TextEditingController lngCtrl,
  Map<Prayer, TextEditingController> iqamahCtrls,
  Map<Prayer, TextEditingController> adjustmentCtrls,
) {
  switch (step) {
    case 0:
      return _buildWelcome(context);
    case 1:
      return _buildMethod(
        context,
        method,
        fajrAngleCtrl,
        ishaAngleCtrl,
        ishaIntervalCtrl,
        maghribAngleCtrl,
      );
    case 2:
      return _buildTimeFormat(context, is24Hours);
    case 3:
      return _buildLocation(context, locationNameCtrl, latCtrl, lngCtrl);
    case 4:
      return _buildIqamahAndAdjustments(
        context,
        iqamahCtrls,
        adjustmentCtrls,
      );
    default:
      return _buildWelcome(context);
  }
}

Widget _buildIqamahAndAdjustments(
  BuildContext context,
  Map<Prayer, TextEditingController> iqamahCtrls,
  Map<Prayer, TextEditingController> adjustmentCtrls,
) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Text(context.l10n.iqamahAfterAdhan),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: _StartWizardDialog._iqamahPrayers
              .map(
                (p) => SizedBox(
                  width: 140,
                  child: FTextFormField(
                    control: .managed(controller: iqamahCtrls[p]),
                    keyboardType: TextInputType.number,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(context.l10n.adhanAdjustments),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          runSpacing: 8,
          spacing: 12,
          children: _StartWizardDialog._adjustmentPrayers
              .map(
                (p) => SizedBox(
                  width: 140,
                  child: FTextFormField(
                    control: .managed(controller: adjustmentCtrls[p]),
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

Widget _buildLocation(
  BuildContext context,
  TextEditingController locationNameCtrl,
  TextEditingController latCtrl,
  TextEditingController lngCtrl,
) {
  return Column(
    crossAxisAlignment: .start,
    mainAxisSize: MainAxisSize.min,
    children: [
      FTextFormField(
        control: .managed(controller: locationNameCtrl),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: FTextFormField(
              control: .managed(controller: latCtrl),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FTextFormField(
              control: .managed(controller: lngCtrl),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          FButton(
            onPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.deviceLocationNotImplemented),
                ),
              );
            },
            child: Text(context.l10n.useDeviceLocation),
          ),
          const SizedBox(width: AppSpacing.sm),
          FButton(
            onPress: () {
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

Widget _buildMethod(
  BuildContext context,
  ValueNotifier<CalculationMethod?> method,
  TextEditingController fajrAngleCtrl,
  TextEditingController ishaAngleCtrl,
  TextEditingController ishaIntervalCtrl,
  TextEditingController maghribAngleCtrl,
) {
  return Column(
    crossAxisAlignment: .start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.l10n.chooseCalculationMethod),
      const SizedBox(height: AppSpacing.sm),
      FSelect<CalculationMethod>(
        items: {
          for (final m in CalculationMethod.values)
            m.getLocaleName(context.l10n): m,
        },
      ),
      if (method.value == CalculationMethod.other) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(context.l10n.customParametersLabel),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FTextFormField(
                control: .managed(controller: fajrAngleCtrl),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FTextFormField(
                control: .managed(controller: ishaAngleCtrl),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FTextFormField(
                control: .managed(controller: ishaIntervalCtrl),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FTextFormField(
                control: .managed(controller: maghribAngleCtrl),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.placeholdersHint,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ],
  );
}

Widget _buildTimeFormat(BuildContext context, ValueNotifier<bool> is24Hours) {
  return Material(
    child: SwitchListTile(
      contentPadding: .zero,
      title: Text(context.l10n.use24HourFormat),
      value: is24Hours.value,
      onChanged: (v) => is24Hours.value = v,
    ),
  );
}

Widget _buildWelcome(BuildContext context) {
  return Column(
    crossAxisAlignment: .start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        context.l10n.setupPrayerSettingsTitle,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(context.l10n.setupPrayerSettingsSubtitle),
      SizedBox(
        width: 200,
        height: 80,
        child: FTextField.password(),
      ),
    ],
  );
}
