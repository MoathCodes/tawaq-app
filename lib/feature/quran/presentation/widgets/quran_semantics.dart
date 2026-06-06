import 'package:flutter/material.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Accessibility helpers for the Quran feature.
///
/// Prefer forui form widget `label` and `enabled` first; use these helpers for
/// mushaf surfaces, merged chips, and controls that need explicit names.
abstract final class QuranSemantics {
  /// Strips the placeholder digit from localized field templates.
  static String fieldNameFromTemplate(
    String template, {
    String placeholder = '1',
  }) {
    if (template.endsWith(placeholder)) {
      return template.substring(0, template.length - placeholder.length).trim();
    }
    return template;
  }

  /// Localized "Surah" field name (without number).
  static String surahFieldName(AppLocalizations l10n) =>
      fieldNameFromTemplate(l10n.surahNameDefault(1));

  /// Localized "Juz" field name (without number).
  static String juzFieldName(AppLocalizations l10n) =>
      fieldNameFromTemplate(l10n.juzLabel(1));

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

  /// Mushaf / page canvas: one announced region, no per-glyph semantics.
  static Widget mushafReadingRegion({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      container: true,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Landmark region (e.g. study panel) without hiding descendant controls.
  static Widget landmark({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      container: true,
      child: child,
    );
  }

  /// Interactive control with an explicit name; optional [value] for state.
  static Widget labeledControl({
    required String name,
    required Widget child,
    String? value,
    bool enabled = true,
    bool button = false,
    bool selected = false,
    bool excludeChild = false,
  }) {
    return Semantics(
      label: name,
      value: value,
      enabled: enabled,
      button: button,
      selected: selected,
      child: excludeChild ? ExcludeSemantics(child: child) : child,
    );
  }

  /// Merges descendants into one node (e.g. icon + label chip).
  static Widget mergedChip({required Widget child}) =>
      MergeSemantics(child: child);

  /// Hides [child] from the semantics tree (decorative only).
  static Widget decorative(Widget child) => ExcludeSemantics(child: child);
}
