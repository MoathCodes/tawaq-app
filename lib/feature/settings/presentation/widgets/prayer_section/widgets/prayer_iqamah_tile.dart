import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

final _squareShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(0),
);

final _iqamahStepperButtonStyle = FButtonStyleDelta.delta(
  decoration: FVariantsDelta.delta([
    FVariantOperation.all(
      DecorationDelta.shapeDelta(shape: _squareShape),
    ),
  ]),
  contentStyle: const FButtonContentStyleDelta.delta(
    padding: EdgeInsetsGeometryDelta.value(
      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
  ),
);

FTextFieldStyleDelta _iqamahStepperFieldStyle({
  required FColors colors,
  required Color borderColor,
  required double borderWidth,
}) {
  OutlineInputBorder squareBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: color, width: borderWidth),
  );

  return FTextFieldStyleDelta.delta(
    color: FVariantsValueDelta.delta([
      FVariantValueDeltaOperation.base(colors.card),
      FVariantValueDeltaOperation.exact(
        {FTextFieldVariant.disabled},
        colors.disable(colors.card),
      ),
    ]),
    border: FVariantsValueDelta.delta([
      FVariantValueDeltaOperation.all(squareBorder(borderColor)),
      FVariantValueDeltaOperation.exact(
        {FTextFieldVariant.focused},
        squareBorder(colors.primary),
      ),
      FVariantValueDeltaOperation.exact(
        {FTextFieldVariant.disabled},
        squareBorder(colors.disable(colors.border)),
      ),
      FVariantValueDeltaOperation.exact(
        {FTextFieldVariant.error},
        squareBorder(colors.error),
      ),
    ]),
    contentPadding: const EdgeInsetsGeometryDelta.value(
      EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    ),
  );
}

/// A row for adjusting the iqamah offset of a single prayer.
class PrayerIqamahTile extends ConsumerWidget {
  /// Creates a new [PrayerIqamahTile] instance.
  const PrayerIqamahTile({
    required this.prayer,
    required this.allowSigned,
    super.key,
  });

  /// The prayer this row controls.
  final Prayer prayer;

  /// Whether negative values are allowed.
  final bool allowSigned;

  static const _iconSize = 36.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prayerName = prayer.getLocaleName(l10n);

    final label = _PrayerLabel(
      prayer: prayer,
      prayerName: prayerName,
    );
    final stepper = _IqamahStepper(
      prayer: prayer,
      prayerName: prayerName,
      allowSigned: allowSigned,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = !isContainerAtLeast(
            context,
            constraints,
            FBreakpoint.sm,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [label, stepper],
            );
          }
          return Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(child: label),
              stepper,
            ],
          );
        },
      ),
    );
  }
}

class _PrayerLabel extends StatelessWidget {
  const _PrayerLabel({
    required this.prayer,
    required this.prayerName,
  });

  final Prayer prayer;
  final String prayerName;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Row(
      spacing: AppSpacing.sm,
      children: [
        SettingsSemantics.decorative(
          Container(
            width: PrayerIqamahTile._iconSize,
            height: PrayerIqamahTile._iconSize,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: theme.radii.md,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              prayer.icon,
              size: 18,
              color: colors.foreground,
            ),
          ),
        ),
        Expanded(
          child: Text(
            prayerName,
            style: theme.typography.body.md.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
        ),
      ],
    );
  }
}

class _IqamahStepper extends ConsumerWidget {
  const _IqamahStepper({
    required this.prayer,
    required this.prayerName,
    required this.allowSigned,
  });

  final Prayer prayer;
  final String prayerName;
  final bool allowSigned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(iqamahDraftProvider.notifier);
    final enabled = ref.watch(
      prayerSettingsProvider.select((value) => value.hasValue),
    );
    final isUnsaved = ref.watch(
      iqamahDraftProvider.select(
        (state) => state.unsavedPrayers.contains(prayer),
      ),
    );

    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final unitStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );
    final borderColor = isUnsaved
        ? Color.lerp(colors.border, colors.primary, 0.55)!
        : colors.border;
    final borderWidth = isUnsaved ? 1.5 : theme.style.borderWidth;
    final fieldStyle = _iqamahStepperFieldStyle(
      colors: colors,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );

    return NonSelectable(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: borderColor, width: isUnsaved ? 1.5 : 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepperIconButton(
                icon: FLucideIcons.minus,
                label: SettingsSemantics.decreaseIqamahAction(l10n, prayerName),
                enabled: enabled,
                onPress: () => draft.applyDelta(prayer, -1),
              ),
              _StepperDivider(color: colors.border),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 88, maxWidth: 112),
                child: FTextField(
                  enabled: enabled,
                  control: .managed(controller: draft.controller(prayer)),
                  focusNode: draft.focusNode(prayer),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: fieldStyle,
                  inputFormatters: [
                    if (allowSigned)
                      FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*$'))
                    else
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  onEditingComplete: () => draft.save(context, prayer),
                  onSubmit: (_) => draft.save(context, prayer),
                  suffixBuilder: (context, value, child) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Text(l10n.minute, style: unitStyle),
                  ),
                ),
              ),
              _StepperDivider(color: colors.border),
              _StepperIconButton(
                icon: FLucideIcons.plus,
                label: SettingsSemantics.increaseIqamahAction(l10n, prayerName),
                enabled: enabled,
                onPress: () => draft.applyDelta(prayer, 1),
              ),
              _StepperDivider(color: colors.border),
              FTooltip(
                semanticsLabel: l10n.resetToDefaults,
                tipBuilder: (context, controller) =>
                    Text(l10n.resetToDefaults),
                child: _StepperIconButton(
                  icon: FLucideIcons.rotateCcw,
                  label: SettingsSemantics.resetIqamahAction(l10n, prayerName),
                  enabled: enabled,
                  onPress: () => draft.reset(context, prayer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPress,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return SettingsSemantics.iconAction(
      label: label,
      enabled: enabled,
      child: FButton.icon(
        variant: .ghost,
        style: _iqamahStepperButtonStyle,
        onPress: enabled ? onPress : null,
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _StepperDivider extends StatelessWidget {
  const _StepperDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: color,
    );
  }
}

/// List container for iqamah prayer rows.
class IqamahPrayerList extends StatelessWidget {
  /// Creates an [IqamahPrayerList].
  const IqamahPrayerList({
    required this.children,
    super.key,
  });

  /// Prayer rows to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.border,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }
}
