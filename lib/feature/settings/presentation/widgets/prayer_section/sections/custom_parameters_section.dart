import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/custom_parameters_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/custom_parameters_content.dart';

/// Widget for the custom prayer parameters section.
class PrayerSettingsCustomParametersCard extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsCustomParametersCard] instance.
  const PrayerSettingsCustomParametersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(customParametersDraftProvider);

    final l10n = context.l10n;

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
            child: const CustomParametersContent(),
          ),
        ],
      ),
    );
  }
}
