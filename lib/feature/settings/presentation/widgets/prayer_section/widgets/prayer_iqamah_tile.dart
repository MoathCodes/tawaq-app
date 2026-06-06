import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// A tile for adjusting the iqamah time of a single prayer.
class PrayerIqamahTile extends StatelessWidget implements FTileMixin {
  /// Creates a new [PrayerIqamahTile] instance.
  const PrayerIqamahTile({
    required this.prayer,
    required this.controller,
    required this.focusNode,
    required this.allowSigned,
    required this.onDelta,
    required this.onSave,
    required this.onReset,
    this.enabled = true,
    super.key,
  });

  /// The prayer this tile controls.
  final Prayer prayer;

  /// Text controller for the iqamah value.
  final TextEditingController controller;

  /// Focus node for the text field.
  final FocusNode focusNode;

  /// Whether negative values are allowed.
  final bool allowSigned;

  /// Called when +/- buttons are tapped, with the delta.
  final ValueChanged<int> onDelta;

  /// Called when the user saves (submit / editing complete).
  final VoidCallback onSave;

  /// Called when the user resets this prayer's value.
  final VoidCallback onReset;

  /// Whether adjustment controls are interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final textStyle = theme.typography.sm.copyWith(
      color: colors.foreground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final prayerName = prayer.getLocaleName(l10n);

    return FTile(
      prefix: SettingsSemantics.decorative(
        Icon(prayer.icon, size: 32),
      ),
      title: Text(
        prayerName,
        style: theme.typography.xl.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      details: NonSelectable(
        child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          SettingsSemantics.iconAction(
            label: SettingsSemantics.decreaseIqamahAction(l10n, prayerName),
            enabled: enabled,
            child: FButton.icon(
              variant: .ghost,
              onPress: enabled ? () => onDelta(-1) : null,
              child: const Icon(FLucideIcons.minus),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 120),
            child: FTextField(
              enabled: enabled,
              control: .managed(controller: controller),
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                if (allowSigned)
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*$'))
                else
                  FilteringTextInputFormatter.digitsOnly,
              ],
              onEditingComplete: onSave,
              onSubmit: (_) => onSave(),
              suffixBuilder: (context, value, child) => Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: Text(l10n.minute, style: textStyle),
              ),
            ),
          ),
          SettingsSemantics.iconAction(
            label: SettingsSemantics.increaseIqamahAction(l10n, prayerName),
            enabled: enabled,
            child: FButton.icon(
              variant: .ghost,
              onPress: enabled ? () => onDelta(1) : null,
              child: const Icon(FLucideIcons.plus),
            ),
          ),
          FTooltip(
            tipBuilder: (context, controller) =>
                Text(l10n.resetToDefaults),
            child: SettingsSemantics.iconAction(
              label: SettingsSemantics.resetIqamahAction(l10n, prayerName),
              enabled: enabled,
              child: FButton.icon(
                variant: .ghost,
                onPress: enabled ? onReset : null,
                child: const Icon(FLucideIcons.rotateCcw),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
