import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/feature/settings/presentation/widgets/keyboard_shortcuts/keyboard_shortcuts_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/prayer_location_settings.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/tabs/settings_appearance_tab.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Stable application identity for a settings destination.
enum SettingsTabId {
  appearance('appearance'),
  prayerTimes('prayer-times'),
  location('location'),
  keyboardShortcuts('keyboard-shortcuts');

  new(this.wireValue);

  /// Stable query/persistence value.
  final String wireValue;
}

/// Persisted/query key for the default settings tab.
const kSettingsDefaultTabKey = 'appearance';

/// Persisted/query key for the location settings tab.
const kSettingsLocationTabKey = 'location';

/// Whether a Material tab controller has fully settled after a tap or swipe.
bool settingsTabIsSettled({
  required bool indexIsChanging,
  required double offset,
}) => !indexIsChanging && offset.abs() <= 0.000001;

/// Parses current wire values and legacy ARB-derived persistence keys.
SettingsTabId? settingsTabIdFromWire(String? value) => switch (value) {
  'appearance' => SettingsTabId.appearance,
  'prayer-times' || 'timeSectionTitle' => SettingsTabId.prayerTimes,
  'location' || 'locationSectionTitle' => SettingsTabId.location,
  'keyboard-shortcuts' ||
  'keyboardShortcutsTabTitle' => SettingsTabId.keyboardShortcuts,
  _ => null,
};

/// A single settings tab — key, chrome, visibility, and body builder.
class SettingsTab {
  /// Creates [SettingsTab].
  const new({
    required this.id,
    required this.icon,
    required this.label,
    required this.visible,
    required this.builder,
  });

  /// Stable destination identity.
  final SettingsTabId id;

  /// Stable query/persistence key.
  String get key => id.wireValue;

  /// Tab icon.
  final IconData icon;

  /// Localized tab title.
  final String Function(AppLocalizations l10n) label;

  /// Whether this tab should appear for the current platform.
  final bool Function({required bool showKeyboardShortcuts}) visible;

  /// Scrollable body for this tab.
  final Widget Function(AppLocalizations l10n) builder;
}

/// All settings tabs in display order.
const kSettingsTabs = <SettingsTab>[
  SettingsTab(
    id: SettingsTabId.appearance,
    icon: FLucideIcons.palette,
    label: _appearanceLabel,
    visible: _alwaysVisible,
    builder: _appearanceBody,
  ),
  SettingsTab(
    id: SettingsTabId.prayerTimes,
    icon: FLucideIcons.clock,
    label: _prayerTimesLabel,
    visible: _alwaysVisible,
    builder: _prayerTimesBody,
  ),
  SettingsTab(
    id: SettingsTabId.location,
    icon: FLucideIcons.mapPin,
    label: _locationLabel,
    visible: _alwaysVisible,
    builder: _locationBody,
  ),
  SettingsTab(
    id: SettingsTabId.keyboardShortcuts,
    icon: FLucideIcons.keyboard,
    label: _keyboardShortcutsLabel,
    visible: _keyboardShortcutsVisible,
    builder: _keyboardShortcutsBody,
  ),
];

bool _alwaysVisible({required bool showKeyboardShortcuts}) => true;

bool _keyboardShortcutsVisible({required bool showKeyboardShortcuts}) =>
    showKeyboardShortcuts;

String _appearanceLabel(AppLocalizations l10n) => l10n.appearance;

String _prayerTimesLabel(AppLocalizations l10n) => l10n.timeSectionTitle;

String _locationLabel(AppLocalizations l10n) => l10n.locationSectionTitle;

String _keyboardShortcutsLabel(AppLocalizations l10n) =>
    l10n.keyboardShortcutsTabTitle;

Widget _appearanceBody(AppLocalizations l10n) => const SettingsAppearanceTab();

Widget _prayerTimesBody(AppLocalizations l10n) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: AppSpacing.lg,
  children: [
    PrayerTimeSettings(),
    PrayerAdhanSettings(chrome: SettingsChrome.section),
  ],
);

Widget _locationBody(AppLocalizations l10n) => const PrayerLocationSettings(
  gateMapToSettingsTab: true,
);

Widget _keyboardShortcutsBody(AppLocalizations l10n) =>
    const KeyboardShortcutsSection();

/// Resolves a persisted tab key, defaulting to appearance.
SettingsTab tabForKey(String? key) {
  final id = settingsTabIdFromWire(key);
  if (id != null) {
    for (final tab in kSettingsTabs) {
      if (tab.id == id) {
        return tab;
      }
    }
  }
  return kSettingsTabs.first;
}

/// Returns tabs visible on the current platform.
List<SettingsTab> visibleTabs({bool? showKeyboardShortcuts}) {
  final showShortcuts = showKeyboardShortcuts ?? supportsKeyboardShortcuts;
  return [
    for (final tab in kSettingsTabs)
      if (tab.visible(showKeyboardShortcuts: showShortcuts)) tab,
  ];
}

/// Index of a tab key in the visible list, or `-1` if not visible.
int indexForTabKey(
  String tabKey, {
  bool? showKeyboardShortcuts,
}) {
  final id = settingsTabIdFromWire(tabKey);
  if (id == null) return -1;
  final tabs = visibleTabs(showKeyboardShortcuts: showKeyboardShortcuts);
  for (var i = 0; i < tabs.length; i++) {
    if (tabs[i].id == id) {
      return i;
    }
  }
  return -1;
}

/// Resolves [tabKey] to a visible tab key, falling back to appearance.
String resolveVisibleTabKey(
  String tabKey, {
  bool? showKeyboardShortcuts,
}) {
  if (indexForTabKey(
        tabKey,
        showKeyboardShortcuts: showKeyboardShortcuts,
      ) >=
      0) {
    return settingsTabIdFromWire(tabKey)!.wireValue;
  }
  return kSettingsDefaultTabKey;
}

/// Resolves URL input first, falling back to the persisted restore checkpoint
/// when the wire value is missing, invalid, or unavailable on this platform.
String resolveSettingsRouteTab({
  required String? routeKey,
  required String? persistedKey,
  required bool showKeyboardShortcuts,
}) {
  final routeId = settingsTabIdFromWire(routeKey);
  if (routeId != null &&
      (showKeyboardShortcuts || routeId != SettingsTabId.keyboardShortcuts)) {
    return routeId.wireValue;
  }
  return resolveVisibleTabKey(
    persistedKey ?? kSettingsDefaultTabKey,
    showKeyboardShortcuts: showKeyboardShortcuts,
  );
}
