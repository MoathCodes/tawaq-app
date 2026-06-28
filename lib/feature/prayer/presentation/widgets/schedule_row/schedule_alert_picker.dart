import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

export 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';

/// Visual + label metadata for [ScheduleAlertMode].
extension ScheduleAlertModeUi on ScheduleAlertMode {
  /// Lucide icon for this mode.
  IconData get icon => switch (this) {
    ScheduleAlertMode.off => FLucideIcons.bellOff,
    ScheduleAlertMode.sound => FLucideIcons.volume2,
    ScheduleAlertMode.notifyOnly => FLucideIcons.bell,
  };

  /// Short label for compact UI.
  String label(
    AppLocalizations l10n, {
    PrayerAlertKind? alertKind,
  }) => switch (this) {
    ScheduleAlertMode.off => l10n.scheduleAlertOff,
    ScheduleAlertMode.sound => switch (alertKind) {
      PrayerAlertKind.iqamah => l10n.scheduleAlertIqamahSound,
      _ => l10n.scheduleAlertSound,
    },
    ScheduleAlertMode.notifyOnly => l10n.scheduleAlertNotify,
  };

  /// Longer hint for the picker popover.
  String hint(
    AppLocalizations l10n, {
    PrayerAlertKind? alertKind,
  }) => switch (this) {
    ScheduleAlertMode.off => l10n.scheduleAlertOffHint,
    ScheduleAlertMode.sound => switch (alertKind) {
      PrayerAlertKind.iqamah => l10n.scheduleAlertIqamahSoundHint,
      _ => l10n.scheduleAlertSoundHint,
    },
    ScheduleAlertMode.notifyOnly => l10n.scheduleAlertNotifyHint,
  };
}

/// Compact alert trigger that opens an [FSelectTileGroup] in a popover.
class ScheduleAlertPicker extends StatelessWidget {
  /// Creates a [ScheduleAlertPicker].
  const ScheduleAlertPicker({
    required this.mode,
    required this.modes,
    required this.interactiveModes,
    required this.eventLabel,
    this.alertKind,
    this.onChanged,
    super.key,
  });

  /// Current alert mode.
  final ScheduleAlertMode mode;

  /// Modes shown in the picker (order preserved).
  final List<ScheduleAlertMode> modes;

  /// Modes the user can actually select.
  final Set<ScheduleAlertMode> interactiveModes;

  /// What this picker controls (e.g. "Fajr adhan") for the popover title.
  final String eventLabel;

  /// Alert category — adjusts sound-mode labels for iqamah vs adhan.
  final PrayerAlertKind? alertKind;

  /// Called when an interactive mode is chosen.
  final ValueChanged<ScheduleAlertMode>? onChanged;

  /// Obligatory prayer alert picker (adhan / iqamah).
  factory ScheduleAlertPicker.obligatory({
    required ScheduleAlertMode mode,
    required String eventLabel,
    required PrayerAlertKind alertKind,
    required bool hasSettings,
    ValueChanged<ScheduleAlertMode>? onChanged,
    Key? key,
  }) {
    const modes = [
      ScheduleAlertMode.off,
      ScheduleAlertMode.sound,
      ScheduleAlertMode.notifyOnly,
    ];
    const interactiveModes = {
      ScheduleAlertMode.off,
      ScheduleAlertMode.sound,
      ScheduleAlertMode.notifyOnly,
    };
    return ScheduleAlertPicker(
      key: key,
      mode: mode,
      modes: modes,
      interactiveModes: hasSettings ? interactiveModes : const {},
      eventLabel: eventLabel,
      alertKind: alertKind,
      onChanged: onChanged,
    );
  }

  /// Sunnah time alert picker (notify-only).
  factory ScheduleAlertPicker.sunnah({
    required ScheduleAlertMode mode,
    required String eventLabel,
    required bool hasSettings,
    ValueChanged<ScheduleAlertMode>? onChanged,
    Key? key,
  }) {
    const modes = [
      ScheduleAlertMode.off,
      ScheduleAlertMode.notifyOnly,
    ];
    const interactiveModes = {
      ScheduleAlertMode.off,
      ScheduleAlertMode.notifyOnly,
    };
    return ScheduleAlertPicker(
      key: key,
      mode: mode,
      modes: modes,
      interactiveModes: hasSettings ? interactiveModes : const {},
      eventLabel: eventLabel,
      alertKind: PrayerAlertKind.sunnah,
      onChanged: onChanged,
    );
  }

  static const _triggerSize = 30.0;

  static const _compactTileStyle = FItemStyleDelta.delta(
    padding: .value(EdgeInsets.zero),
    contentStyle: .delta(
      titleSpacing: 0,
      suffixedPadding: .value(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
      ),
      prefixIconSpacing: AppSpacing.sm,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;
    final canPick = onChanged != null && interactiveModes.isNotEmpty;
    final active = mode != ScheduleAlertMode.off;
    final pickerSemanticsLabel =
        '${l10n.scheduleAlertPickerTitle(eventLabel)}, '
        '${mode.label(l10n, alertKind: alertKind)}';
    final trigger = AnimatedContainer(
      duration: theme.durations.fast,
      width: _triggerSize,
      height: _triggerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? colors.primary.withValues(alpha: 0.12)
            : colors.secondary.withValues(alpha: 0.65),
        border: Border.all(
          color: active
              ? colors.primary.withValues(alpha: 0.4)
              : colors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Icon(
        mode.icon,
        size: 14,
        color: active ? colors.primary : colors.mutedForeground,
      ),
    );

    if (!canPick) {
      return Semantics(
        label: pickerSemanticsLabel,
        readOnly: true,
        child: trigger,
      );
    }

    return FPopover(
      popoverBuilder: (context, controller) {
        final optionTitleStyle = theme.typography.body.xs.copyWith(
          fontWeight: FontWeight.w600,
        );
        final optionHintStyle = theme.typography.body.xs.copyWith(
          color: colors.mutedForeground,
          height: 1.15,
        );
        final popoverConstraints = dialogConstraints(
          context,
          preferredWidth: 248,
          minWidth: 192,
        );
        final tileMaxHeight = switch (
          selectPopoverPortalConstraints(context, maxHeight: 168)
        ) {
          FAutoWidthPortalConstraints(:final maxHeight) => maxHeight,
          _ => 168.0,
        };

        return ConstrainedBox(
          constraints: popoverConstraints,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.scheduleAlertPickerTitle(eventLabel),
                    style: theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: theme.radii.sm,
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.85),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: theme.radii.sm,
                    child: FSelectTileGroup<ScheduleAlertMode>(
                      key: ValueKey(mode),
                      divider: FItemDivider.full,
                      maxHeight: tileMaxHeight,
                      control: FMultiValueControl.managedRadio(
                        initial: mode,
                        onChange: (selected) {
                          final next = selected.firstOrNull;
                          if (next == null ||
                              next == mode ||
                              !interactiveModes.contains(next)) {
                            return;
                          }
                          onChanged?.call(next);
                          unawaited(controller.hide());
                        },
                      ),
                      children: [
                        for (final option in modes)
                          FSelectTile.suffix(
                            style: _compactTileStyle,
                            checkedIcon: Icon(
                              FLucideIcons.check,
                              size: 16,
                              color: colors.primary,
                            ),
                            uncheckedIcon: const Icon(
                              FLucideIcons.check,
                              size: 16,
                              color: Colors.transparent,
                            ),
                            prefix: Icon(option.icon, size: 16),
                            title: Text(
                              option.label(l10n, alertKind: alertKind),
                              style: optionTitleStyle,
                            ),
                            subtitle: Text(
                              option.hint(l10n, alertKind: alertKind),
                              style: optionHintStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: option,
                            enabled: interactiveModes.contains(option),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      builder: (_, controller, child) => MouseClick(
        onClick: controller.toggle,
        semanticsLabel: pickerSemanticsLabel,
        child: child!,
      ),
      child: trigger,
    );
  }
}
