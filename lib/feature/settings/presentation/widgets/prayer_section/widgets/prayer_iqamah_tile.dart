import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// A row for adjusting the iqamah offset of a single prayer.
class PrayerIqamahTile extends ConsumerWidget {
  /// Creates a new [PrayerIqamahTile] instance.
  const new({required this.prayer, required this.allowSigned, super.key});

  /// The prayer this row controls.
  final Prayer prayer;

  /// Whether negative values are allowed.
  final bool allowSigned;

  static const _iconSize = 36.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prayerName = prayer.getLocaleName(l10n);

    final label = _PrayerLabel(prayer: prayer, prayerName: prayerName);
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
  const new({required this.prayer, required this.prayerName});

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
            child: Icon(prayer.icon, size: 18, color: colors.foreground),
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

class _IqamahStepper extends HookConsumerWidget {
  const new({
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
    final controller = draft.controller(prayer);
    useListenable(controller);
    final canDecrease =
        enabled && (allowSigned || (int.tryParse(controller.text) ?? 0) > 0);

    return NonSelectable(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          _StepperIconButton(
            icon: FLucideIcons.minus,
            label: SettingsSemantics.decreaseIqamahAction(l10n, prayerName),
            enabled: canDecrease,
            onPress: () => draft.applyDelta(prayer, -1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 88, maxWidth: 112),
            child: FTextField(
              enabled: enabled,
              control: .managed(controller: draft.controller(prayer)),
              focusNode: draft.focusNode(prayer),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: FTextFieldStyleDelta.delta(
                border: FVariantsValueDelta.delta([
                  if (isUnsaved)
                    FVariantValueDeltaOperation.all(
                      OutlineInputBorder(
                        borderRadius: theme.radii.md,
                        borderSide: BorderSide(color: colors.primary),
                      ),
                    ),
                ]),
              ),
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
          _StepperIconButton(
            icon: FLucideIcons.plus,
            label: SettingsSemantics.increaseIqamahAction(l10n, prayerName),
            enabled: enabled,
            onPress: () => draft.applyDelta(prayer, 1),
          ),
          const SizedBox(width: AppSpacing.sm),
          FTooltip(
            tipBuilder: (context, controller) => Text(l10n.resetToDefaults),
            child: _StepperIconButton(
              semanticsTooltip: l10n.resetToDefaults,
              icon: FLucideIcons.rotateCcw,
              label: SettingsSemantics.resetIqamahAction(l10n, prayerName),
              enabled: enabled,
              onPress: () => draft.reset(context, prayer),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPress,
    this.semanticsTooltip,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPress;
  final String? semanticsTooltip;

  @override
  Widget build(BuildContext context) {
    return SettingsSemantics.iconAction(
      label: label,
      enabled: enabled,
      child: FButton.icon(
        variant: .ghost,
        semanticsTooltip: semanticsTooltip,
        onPress: enabled ? onPress : null,
        child: Icon(icon, size: 16),
      ),
    );
  }
}

/// List container for iqamah prayer rows.
class IqamahPrayerList extends StatelessWidget {
  /// Creates an [IqamahPrayerList].
  const new({required this.children, super.key});

  /// Prayer rows to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: context.theme.radii.lg,
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
