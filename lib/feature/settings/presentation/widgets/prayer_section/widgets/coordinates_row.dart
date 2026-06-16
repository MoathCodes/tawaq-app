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
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_controls_row.dart'
    show manualLocationControlsEnabled;

/// Row of latitude / longitude input fields.
class CoordinatesRow extends ConsumerWidget {
  /// Creates a new [CoordinatesRow] instance.
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

/// A single numeric coordinate input field.
class CoordinateField extends HookConsumerWidget {
  /// Creates a new [CoordinateField] instance.
  const CoordinateField({
    required this.isLatitude,
    required this.label,
    required this.min,
    required this.max,
    super.key,
  });

  /// Whether this field edits latitude (otherwise longitude).
  final bool isLatitude;

  /// The label shown above the field.
  final String label;

  /// Minimum allowed value.
  final double min;

  /// Maximum allowed value.
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

    return FTextField(
      enabled: enabled,
      focusNode: focusNode,
      control: .managed(
        controller: controller,
        onChange: (v) async {
          if (!focusNode.hasFocus || v.text == value) return;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final parsed = double.tryParse(v.text);
            if (parsed == null) return;

            final coords = ref.read(
              prayerSettingsProvider.select((s) => s.value?.coordinates),
            );
            if (coords == null) return;

            final newCoords = isLatitude
                ? Coordinates(parsed, coords.longitude)
                : Coordinates(coords.latitude, parsed);
            final notifier = ref.read(prayerSettingsProvider.notifier)
              ..setCoordinates(newCoords);
            unawaited(notifier.updateLocationData(coordinates: newCoords));
          });
        },
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

/// Input formatter that validates coordinate ranges.
class CoordinateRangeFormatter extends TextInputFormatter {
  /// Creates a new [CoordinateRangeFormatter] instance.
  const CoordinateRangeFormatter({required this.min, required this.max});

  /// Minimum allowed value.
  final double min;

  /// Maximum allowed value.
  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '-' || text == '.') return newValue;

    final value = double.tryParse(text);
    return (value != null && value >= min && value <= max)
        ? newValue
        : oldValue;
  }
}
