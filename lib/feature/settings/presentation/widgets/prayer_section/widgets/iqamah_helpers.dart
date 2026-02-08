import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Increments or decrements an iqamah controller value.
void changeIqamah(TextEditingController controller, int delta) {
  final current = int.tryParse(controller.text.trim()) ?? 0;
  final next = current + delta;
  controller.text = next.toString();
}

/// Resets an iqamah controller to 0 and saves.
void resetIqamah(
  BuildContext context,
  WidgetRef ref,
  Prayer prayer,
  TextEditingController controller,
  Map<Prayer, TextEditingController> controllers,
  Map<Prayer, String> initialIqamahValues,
  ValueNotifier<Set<Prayer>> unsavedPrayers,
) {
  controller.text = '0';
  saveIqamahField(
    context,
    ref,
    prayer,
    controllers,
    initialIqamahValues,
    unsavedPrayers,
  );
}

/// Saves the current iqamah field value to the provider.
void saveIqamahField(
  BuildContext context,
  WidgetRef ref,
  Prayer prayer,
  Map<Prayer, TextEditingController> controllers,
  Map<Prayer, String> initialIqamahValues,
  ValueNotifier<Set<Prayer>> unsavedPrayers,
) {
  final controller = controllers[prayer]!;
  final text = controller.text.trim();

  // If the field is empty, do not update the provider yet.
  if (text.isEmpty) return;

  final value = int.tryParse(text);
  if (value != null) {
    ref
        .read(prayerSettingsProvider.notifier)
        .updatePrayerIqamahTime(prayer, value);

    final normalized = value.toString();
    if (controller.text != normalized) {
      controller.text = normalized;
    }

    if (initialIqamahValues[prayer] != normalized ||
        unsavedPrayers.value.contains(prayer)) {
      initialIqamahValues[prayer] = normalized;
      unsavedPrayers.value = {...unsavedPrayers.value}..remove(prayer);
    }
  }
  showFToast(
    context: context,
    title: Text(context.l10n.iqamahSavedTitle),
    description: Text(
      '${context.l10n.iqamahSavedDescription} '
      "'${prayer.getLocaleName(context.l10n)}'",
    ),
  );
}
