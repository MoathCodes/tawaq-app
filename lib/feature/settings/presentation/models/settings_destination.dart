import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_select_tile_group.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_rerun_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/desktop_settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/keyboard_shortcuts/keyboard_shortcuts_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/typography_settings_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// A navigable settings tab — single source of truth for tab metadata and body.
sealed class SettingsDestination {
  /// Creates [SettingsDestination].
  const SettingsDestination();

  /// Stable persistence identifier — matches the ARB key for this tab's label.
  String get labelKey;

  /// Tab icon.
  IconData get icon;

  /// Localized tab title.
  String label(AppLocalizations l10n);

  /// Whether this tab should appear for the current platform.
  bool isVisible({required bool showKeyboardShortcuts});
}

/// Appearance and theme settings tab.
final class SettingsAppearanceDestination extends SettingsDestination {
  /// Creates [SettingsAppearanceDestination].
  const SettingsAppearanceDestination();

  @override
  String get labelKey => 'appearance';

  @override
  IconData get icon => FLucideIcons.palette;

  @override
  String label(AppLocalizations l10n) => l10n.appearance;

  @override
  bool isVisible({required bool showKeyboardShortcuts}) => true;
}

/// Prayer time and adhan settings tab.
final class SettingsPrayerTimesDestination extends SettingsDestination {
  /// Creates [SettingsPrayerTimesDestination].
  const SettingsPrayerTimesDestination();

  @override
  String get labelKey => 'timeSectionTitle';

  @override
  IconData get icon => FLucideIcons.clock;

  @override
  String label(AppLocalizations l10n) => l10n.timeSectionTitle;

  @override
  bool isVisible({required bool showKeyboardShortcuts}) => true;
}

/// Prayer location settings tab.
final class SettingsLocationDestination extends SettingsDestination {
  /// Creates [SettingsLocationDestination].
  const SettingsLocationDestination();

  @override
  String get labelKey => 'locationSectionTitle';

  @override
  IconData get icon => FLucideIcons.mapPin;

  @override
  String label(AppLocalizations l10n) => l10n.locationSectionTitle;

  @override
  bool isVisible({required bool showKeyboardShortcuts}) => true;
}

/// Keyboard shortcuts reference tab (desktop only).
final class SettingsKeyboardShortcutsDestination extends SettingsDestination {
  /// Creates [SettingsKeyboardShortcutsDestination].
  const SettingsKeyboardShortcutsDestination();

  @override
  String get labelKey => 'keyboardShortcutsTabTitle';

  @override
  IconData get icon => FLucideIcons.keyboard;

  @override
  String label(AppLocalizations l10n) => l10n.keyboardShortcutsTabTitle;

  @override
  bool isVisible({required bool showKeyboardShortcuts}) =>
      showKeyboardShortcuts;
}

/// Default settings tab when no match is found.
const kSettingsDefaultDestination = SettingsAppearanceDestination();

/// Typed navigation target for the location settings tab.
const kSettingsLocationDestination = SettingsLocationDestination();

/// All settings tabs in display order.
const kSettingsDestinations = <SettingsDestination>[
  SettingsAppearanceDestination(),
  SettingsPrayerTimesDestination(),
  SettingsLocationDestination(),
  SettingsKeyboardShortcutsDestination(),
];

/// Resolves a persisted label key to a destination, defaulting to appearance.
SettingsDestination destinationForKey(String? key) {
  if (key == null) {
    return kSettingsDefaultDestination;
  }
  for (final destination in kSettingsDestinations) {
    if (destination.labelKey == key) {
      return destination;
    }
  }
  return kSettingsDefaultDestination;
}

/// Returns destinations visible on the current platform.
List<SettingsDestination> visibleDestinations({
  required bool showKeyboardShortcuts,
}) {
  return [
    for (final destination in kSettingsDestinations)
      if (destination.isVisible(showKeyboardShortcuts: showKeyboardShortcuts))
        destination,
  ];
}

/// Index of [destination] in the visible list, or `-1` if not visible.
int indexForDestination(
  SettingsDestination destination, {
  required bool showKeyboardShortcuts,
}) {
  final destinations = visibleDestinations(
    showKeyboardShortcuts: showKeyboardShortcuts,
  );
  for (var i = 0; i < destinations.length; i++) {
    if (destinations[i].labelKey == destination.labelKey) {
      return i;
    }
  }
  return -1;
}

/// Resolves [destination] to a visible tab, falling back to appearance.
SettingsDestination resolveVisibleDestination(
  SettingsDestination destination, {
  required bool showKeyboardShortcuts,
}) {
  if (indexForDestination(
        destination,
        showKeyboardShortcuts: showKeyboardShortcuts,
      ) >=
      0) {
    return destination;
  }
  return kSettingsDefaultDestination;
}

/// Builds the scrollable body for a settings tab.
Widget settingsDestinationBody(
  SettingsDestination destination,
  AppLocalizations l10n,
) {
  return switch (destination) {
    SettingsAppearanceDestination() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const OnboardingRerunTile(),
        const DesktopSettingsSection(),
        SettingsSection(
          title: l10n.languageLabel,
          subtitle: l10n.onboardingLanguageStepHint,
          child: const LocaleSelectTileGroup(),
        ),
        const ColorThemeSelector(),
        SettingsSection(
          title: l10n.typographySectionTitle,
          subtitle: l10n.typographySectionSubtitle,
          child: const TypographySettingsSection(),
        ),
      ],
    ),
    SettingsPrayerTimesDestination() => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        PrayerSettingsTimeSection(),
        PrayerAdhanSettingsSection(),
      ],
    ),
    SettingsLocationDestination() => const PrayerSettingsLocationSection(),
    SettingsKeyboardShortcutsDestination() => const KeyboardShortcutsSection(),
  };
}
