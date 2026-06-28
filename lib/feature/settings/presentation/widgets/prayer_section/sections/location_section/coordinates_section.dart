import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_helpers.dart';

/// Manual latitude/longitude text fields.
class CoordinatesRow extends ConsumerWidget {
  /// Creates [CoordinatesRow].
  const CoordinatesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    return NonSelectable(
      child: ResponsiveFieldRow(
        maxColumns: 2,
        children: [
          CoordinateField(
            isLatitude: true,
            label: l10n.latitude,
            min: -90,
            max: 90,
          ),
          CoordinateField(
            isLatitude: false,
            label: l10n.longitude,
            min: -180,
            max: 180,
          ),
        ],
      ),
    );
  }
}

class CoordinateField extends HookConsumerWidget {
  const CoordinateField({
    required this.isLatitude,
    required this.label,
    required this.min,
    required this.max,
    super.key,
  });

  final bool isLatitude;
  final String label;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final value = isLatitude
        ? coordinates.latitude.toStringAsFixed(7)
        : coordinates.longitude.toStringAsFixed(7);

    final controller = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    useValueChanged<String, void>(value, (_, _) {
      if (!focusNode.hasFocus) controller.text = value;
      return;
    });

    useEffect(
      () {
        void onFocusChanged() {
          if (focusNode.hasFocus) return;
          final parsed = double.tryParse(controller.text);
          if (parsed == null) {
            controller.text = value;
            return;
          }
          final coords = ref.read(
            prayerSettingsProvider.select((s) => s.value?.coordinates),
          );
          if (coords == null) return;

          final newCoords = isLatitude
              ? Coordinates(parsed, coords.longitude)
              : Coordinates(coords.latitude, parsed);
          if (newCoords.latitude == coords.latitude &&
              newCoords.longitude == coords.longitude) {
            return;
          }
          unawaited(
            ref.read(prayerSettingsProvider.notifier).updateLocation(
              coordinates: newCoords,
            ),
          );
        }

        focusNode.addListener(onFocusChanged);
        return () => focusNode.removeListener(onFocusChanged);
      },
      [focusNode, controller, value, isLatitude],
    );

    return FTextField(
      enabled: enabled,
      focusNode: focusNode,
      control: .managed(
        controller: controller,
      ),
      label: Text(label),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9.-]')),
        CoordinateRangeFormatter(min: min, max: max),
      ],
    );
  }
}

class CoordinateRangeFormatter extends TextInputFormatter {
  const CoordinateRangeFormatter({required this.min, required this.max});

  final double min;
  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '-' || text == '.') return newValue;

    final parsed = double.tryParse(text);
    return (parsed != null && parsed >= min && parsed <= max)
        ? newValue
        : oldValue;
  }
}
