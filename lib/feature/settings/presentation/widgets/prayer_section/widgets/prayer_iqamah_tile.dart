import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/theme/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final textStyle = theme.typography.sm.copyWith(
      color: colors.foreground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return FTile(
      prefix: Icon(prayer.icon, size: 32),
      title: Text(
        prayer.getLocaleName(context.l10n),
        style: theme.typography.xl.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colors.foreground,
        ),
      ),
      details: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => onDelta(-1),
            child: const Icon(FIcons.minus),
          ),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 120),
            child: FTextField(
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
                child: Text(context.l10n.minute, style: textStyle),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: () => onDelta(1),
            child: const Icon(FIcons.plus),
          ),
          const SizedBox(width: AppSpacing.xs),
          FTooltip(
            tipBuilder: (context, controller) =>
                Text(context.l10n.resetToDefaults),
            child: FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: onReset,
              child: const Icon(FIcons.rotateCcw),
            ),
          ),
        ],
      ),
    );
  }
}
