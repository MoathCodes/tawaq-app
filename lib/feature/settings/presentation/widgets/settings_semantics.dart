import 'package:flutter/material.dart';
import 'package:forui/forui.dart' show FButton;
import 'package:forui/widgets/button.dart' show FButton;
import 'package:tawaq/core/widgets/merged_action_semantics.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Accessibility helpers for the settings feature.
///
/// Prefer forui form widget labels and `enabled` flags first; use these helpers
/// only where semantics are missing (custom click targets, scale pickers, map).
abstract final class SettingsSemantics {
  /// Marks [child] as a page/section heading.
  static Widget sectionHeader({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  /// Read-only name + value announcement with decorative children hidden.
  static Widget readOnlyValue({
    required String name,
    required String value,
    required Widget child,
  }) {
    return Semantics(
      label: name,
      value: value,
      readOnly: true,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Interactive control with an explicit name; optional [value] for state.
  ///
  /// Set [excludeChild] when the child already exposes duplicate text nodes
  /// (e.g. palette swatches with visible titles).
  static Widget labeledControl({
    required String name,
    required Widget child,
    String? value,
    bool enabled = true,
    bool button = false,
    bool selected = false,
    bool excludeChild = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: name,
      value: value,
      enabled: enabled,
      button: button,
      selected: selected,
      onTap: button && enabled ? onTap : null,
      child: excludeChild ? ExcludeSemantics(child: child) : child,
    );
  }

  /// Icon-only control: one merged node (no duplicate [FButton] labels).
  static Widget iconAction({
    required String label,
    required Widget child,
    String? hint,
    bool enabled = true,
    bool selected = false,
  }) {
    return MergedActionSemantics(
      label: label,
      hint: hint,
      enabled: enabled,
      selected: selected,
      child: child,
    );
  }

  /// Announced label for the map "use my location" control.
  static String useMyLocationAction(AppLocalizations l10n) =>
      l10n.useMyLocation;

  /// Announced label for applying the device/system timezone.
  static String useSystemTimezoneAction(AppLocalizations l10n) =>
      l10n.useSystemTimezone;

  /// Decrease iqamah minutes for [prayerName].
  static String decreaseIqamahAction(
    AppLocalizations l10n,
    String prayerName,
  ) =>
      l10n.a11ySettingsDecreaseIqamah(prayerName);

  /// Increase iqamah minutes for [prayerName].
  static String increaseIqamahAction(
    AppLocalizations l10n,
    String prayerName,
  ) =>
      l10n.a11ySettingsIncreaseIqamah(prayerName);

  /// Reset iqamah for [prayerName] to the default offset.
  static String resetIqamahAction(AppLocalizations l10n, String prayerName) =>
      l10n.a11ySettingsResetIqamah(prayerName);

  /// Hides [child] from the semantics tree (decorative only).
  static Widget decorative(Widget child) => ExcludeSemantics(child: child);
}
