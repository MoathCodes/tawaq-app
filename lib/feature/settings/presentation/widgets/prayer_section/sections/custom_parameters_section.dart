import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/custom_parameters_content.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/param_controllers.dart';

/// Widget for the custom prayer parameters section.
class PrayerSettingsCustomParametersCard extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsCustomParametersCard] instance.
  const PrayerSettingsCustomParametersCard({
    required this.maxWidth,
    this.enabled = true,
    super.key,
  });

  /// The maximum width of the section.
  final double maxWidth;

  /// Whether custom parameter controls are interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read once on mount
    final initial = useMemoized(
      () => ref.read(prayerSettingsProvider).value?.method,
      const [],
    );

    // Controllers - all created with initial values
    final controllers = useParamControllers(initial);

    // Sync controllers when external changes occur
    // (e.g., calculation method change)
    ref.listen<CalculationMethod?>(
      prayerSettingsProvider.select((next) => next.value?.method),
      (_, method) {
        if (method case final m?) controllers.syncFrom(m);
      },
    );

    final l10n = context.l10n;

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
          title: Text(l10n.parametersSavedTitle),
          description: Text(l10n.parametersSavedDescription),
        );
      } catch (e) {
        showFToast(
          context: context,
          title: Text(l10n.invalidParametersTitle),
          description: Text(
            l10n.invalidParametersWithError(
              l10n.invalidParametersDescription,
              e.toString(),
            ),
          ),
        );
      }
    }

    void reset() {
      final current = ref.read(prayerSettingsProvider).value?.method;
      controllers.syncFrom(current);
      save();
      showFToast(
        context: context,
        title: Text(l10n.resetCompleteTitle),
        description: Text(l10n.resetCompleteDescription),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FAccordion(
        control: .managed(controller: useFAccordionController()),
        style: const .delta(
          dividerStyle: .delta(
            color: Colors.transparent,
            padding: .value(EdgeInsets.zero),
          ),
        ),
        children: [
          FAccordionItem(
            title: Text(l10n.customParametersTitle),
            child: CustomParametersContent(
              controllers: controllers,
              enabled: enabled,
              onSave: save,
              onReset: reset,
            ),
          ),
        ],
      ),
    );
  }
}
