import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

/// Row of latitude / longitude input fields.
class CoordinatesRow extends ConsumerWidget {
  /// Creates a new [CoordinatesRow] instance.
  const CoordinatesRow({required this.enabled, super.key});

  /// Whether the fields are editable.
  final bool enabled;

  void _updateCoordinate(
    WidgetRef ref,
    Coordinates coords,
    String value,
    bool isLat,
  ) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;

    final newCoords = isLat
        ? Coordinates(parsed, coords.longitude)
        : Coordinates(coords.latitude, parsed);
    final notifier = ref.read(prayerSettingsProvider.notifier)
      ..setCoordinates(newCoords);
    unawaited(notifier.updateLocationData(coordinates: newCoords));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    return NonSelectable(
      child: Row(
      spacing: 12,
      children: [
        Expanded(
          child: CoordinateField(
            enabled: enabled,
            label: l10n.latitude,
            value: coordinates.latitude.toStringAsFixed(7),
            min: -90,
            max: 90,
            onChanged: (v) => _updateCoordinate(ref, coordinates, v, true),
          ),
        ),
        Expanded(
          child: CoordinateField(
            enabled: enabled,
            label: l10n.longitude,
            value: coordinates.longitude.toStringAsFixed(7),
            min: -180,
            max: 180,
            onChanged: (v) => _updateCoordinate(ref, coordinates, v, false),
          ),
        ),
      ],
      ),
    );
  }
}

/// A single numeric coordinate input field.
class CoordinateField extends HookWidget {
  /// Creates a new [CoordinateField] instance.
  const CoordinateField({
    required this.enabled,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  /// Whether the field is editable.
  final bool enabled;

  /// The label shown above the field.
  final String label;

  /// The current value as a string.
  final String value;

  /// Minimum allowed value.
  final double min;

  /// Maximum allowed value.
  final double max;

  /// Called when the user changes the value.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    // Sync external value only when not focused.
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
          // Only propagate user edits (field focused), not programmatic syncs.
          if (focusNode.hasFocus && v.text != value) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onChanged(v.text),
            );
          }
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
