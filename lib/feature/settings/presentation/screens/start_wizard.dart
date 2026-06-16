import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/wizard_setup_provider.dart';
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

class _StartWizardDialog extends ConsumerWidget {
  const _StartWizardDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(wizardSetupProvider.select((s) => s.step));
    final wizard = ref.read(wizardSetupProvider.notifier);
    final l10n = context.l10n;

    final titles = [
      l10n.wizardStep_welcome,
      l10n.wizardStep_calculationMethod,
      l10n.wizardStep_timeFormat,
      l10n.wizardStep_location,
      l10n.wizardStep_iqamahAdjustments,
    ];

    final dialogSize = dialogConstraints(
      context,
      preferredWidth: 520,
      preferredHeight: 560,
    );
    final maxBodyHeight = MediaQuery.sizeOf(context).height * 0.55;

    return FDialog.adaptive(
      constraints: dialogSize,
      title: SettingsSemantics.sectionHeader(
        label: titles[step],
        child: Text(titles[step]),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBodyHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: switch (step) {
              0 => const WelcomeStep(),
              1 => const MethodStep(),
              2 => const TimeFormatStep(),
              3 => const LocationStep(),
              4 => const IqamahStep(),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
      actions: [
        FButton(
          onPress: () => wizard.next(context),
          child: Text(step < 4 ? l10n.next : l10n.done),
        ),
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(l10n.skip),
        ),
        if (step > 0)
          FButton(
            onPress: wizard.back,
            child: Text(l10n.back),
          ),
      ],
    );
  }
}
