import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/custom_parameters_content.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/param_controllers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget for the custom prayer parameters section.
class PrayerSettingsCustomParametersCard extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsCustomParametersCard] instance.
  const PrayerSettingsCustomParametersCard({required this.maxWidth, super.key});

  /// The maximum width of the section.
  final double maxWidth;

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
    ref.listen(prayerSettingsProvider, (_, next) {
      if (next.value?.method case final m?) controllers.syncFrom(m);
    });

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
      final current = ref.read(prayerSettingsProvider).value?.method;
      controllers.syncFrom(current);
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
        control: .managed(controller: useFAccordionController()),
        style: (style) => style.copyWith(
          dividerStyle: FDividerStyle(
            color: Colors.transparent,
            padding: EdgeInsetsGeometry.zero,
          ).call,
        ),
        children: [
          FAccordionItem(
            title: Text(context.l10n.customParametersTitle),
            child: CustomParametersContent(
              controllers: controllers,
              onSave: save,
              onReset: reset,
            ),
          ),
        ],
      ),
    );
  }
}
