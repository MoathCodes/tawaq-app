import 'package:flutter/material.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';

/// Shared accessibility semantics wrappers for feature screens.
///
/// Prefer forui form widget `label` and `enabled` first; use these helpers for
/// custom click targets, merged chips, and controls that need explicit names.
abstract final class SemanticsWrappers {
  /// Marks [child] as a page/section heading.
  static Widget sectionHeader({
    required Widget child,
    String? label,
  }) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  /// Interactive or read-only control with an explicit [label].
  ///
  /// Pass [iconAction] for icon-only controls (merged into one node).
  /// Pass [readOnlyValue] to announce a read-only name + value pair.
  static Widget labeledControl({
    required String label,
    required Widget child,
    String? hint,
    VoidCallback? onTap,
    String? readOnlyValue,
    Widget? iconAction,
    String? value,
    bool enabled = true,
    bool button = false,
    bool selected = false,
    bool excludeChild = false,
  }) {
    if (iconAction != null) {
      return MergedActionSemantics(
        label: label,
        hint: hint,
        enabled: enabled,
        selected: selected,
        child: iconAction,
      );
    }

    final isReadOnly = readOnlyValue != null;
    final announcedValue = readOnlyValue ?? value;

    return Semantics(
      label: label,
      hint: hint,
      value: announcedValue,
      readOnly: isReadOnly,
      enabled: enabled,
      button: button,
      selected: selected,
      onTap: button && enabled ? onTap : null,
      child: excludeChild || isReadOnly
          ? ExcludeSemantics(child: child)
          : child,
    );
  }

  /// Hides [child] from the semantics tree (decorative only).
  static Widget decorative({required Widget child}) =>
      ExcludeSemantics(child: child);
}
